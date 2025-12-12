#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h> 

// CONFIGURATION
#define MAX_ROWS 50000  
#define MAX_COLS 200    
#define MAX_LINE 8192
#define MAX_YEARS_PER_COUNTRY 200 // Buffer for storing errors for Median calc

typedef struct {
    char country[64];
    int year;
    double value;
} Row;

typedef struct {
    char name[64];
    double sum_abs_error;
    double sum_sq_error;     // For RMSE
    double errors[MAX_YEARS_PER_COUNTRY]; // Store individual errors for Median
    int count;
} CountryStat;

// Comparison function for qsort (needed for Median)
int compare_doubles(const void *a, const void *b) {
    double arg1 = *(const double *)a;
    double arg2 = *(const double *)b;
    if (arg1 < arg2) return -1;
    if (arg1 > arg2) return 1;
    return 0;
}

// Helper: Remove quotes and whitespace
void strip_clean(char *str) {
    char *src = str, *dst = str;
    while (*src) {
        if (*src != '"' && *src != '\'' && *src != '\r' && *src != '\n') {
            *dst = *src;
            dst++;
        }
        src++;
    }
    *dst = '\0';
}

// Helper: Normalize string for COMPARISON
void normalize_string(char *str) {
    char *src = str, *dst = str;
    while (*src) {
        if (*src != '"' && *src != '\'' && *src != '\r' && *src != '\n') {
            *dst = toupper((unsigned char)*src);
            dst++;
        }
        src++;
    }
    *dst = '\0';
    
    int len = strlen(str);
    while (len > 0 && isspace((unsigned char)str[len - 1])) str[--len] = '\0';
    char *start = str;
    while (isspace((unsigned char)*start)) start++;
    if (start != str) memmove(str, start, strlen(start) + 1);
}

int get_country_index(CountryStat stats[], int *count, const char *name) {
    for (int i = 0; i < *count; i++) {
        if (strcmp(stats[i].name, name) == 0) return i;
    }
    strcpy(stats[*count].name, name);
    stats[*count].sum_abs_error = 0;
    stats[*count].sum_sq_error = 0;
    stats[*count].count = 0;
    (*count)++;
    return (*count) - 1;
}

// 1. LOAD TRUTH FILE
int load_truth_wide(const char *filename, Row rows[], int max_rows) {
    FILE *fp = fopen(filename, "r");
    if (!fp) { printf("Error: Could not open truth file %s\n", filename); return -1; }

    char line[MAX_LINE];
    char country_headers[MAX_COLS][64];
    int num_countries = 0;
    int row_count = 0;

    if (fgets(line, sizeof(line), fp)) {
        char *start = line;
        if ((unsigned char)line[0] == 0xEF && (unsigned char)line[1] == 0xBB && (unsigned char)line[2] == 0xBF) start += 3;
        char *token = strtok(start, ",;"); 
        
        while ((token = strtok(NULL, ",;")) != NULL) {
            if (num_countries < MAX_COLS) {
                normalize_string(token); 
                strncpy(country_headers[num_countries], token, 63);
                country_headers[num_countries][63] = '\0';
                num_countries++;
            }
        }
    }

    while (fgets(line, sizeof(line), fp)) {
        char *temp_line = strdup(line);
        char *token = strtok(line, ",;");
        if (!token) { free(temp_line); continue; }
        strip_clean(token); 
        if (strlen(token) == 0) { free(temp_line); continue; }

        int year = atoi(token);

        for (int i = 0; i < num_countries; i++) {
            token = strtok(NULL, ",;");
            if (token && row_count < max_rows) {
                strip_clean(token);
                strcpy(rows[row_count].country, country_headers[i]);
                rows[row_count].year = year;
                rows[row_count].value = atof(token);
                row_count++;
            }
        }
        free(temp_line);
        if (row_count >= max_rows) break;
    }
    fclose(fp);
    return row_count;
}

// 2. LOAD PREDICTION FILE
int load_predictions(const char *filename, Row rows[], int max_rows) {
    FILE *fp = fopen(filename, "r");
    if (!fp) { printf("Error: Could not open prediction file %s\n", filename); return -1; }

    char line[MAX_LINE];
    int count = 0;
    fgets(line, sizeof(line), fp); 

    while (count < max_rows && fgets(line, sizeof(line), fp)) {
        char *country_token = strtok(line, ",;");
        char *year_token = strtok(NULL, ",;");
        char *val_token = strtok(NULL, ",;");

        if (country_token && year_token && val_token) {
            normalize_string(country_token);
            strip_clean(year_token);
            strip_clean(val_token);

            strcpy(rows[count].country, country_token);
            rows[count].year = atoi(year_token);
            rows[count].value = atof(val_token);
            count++;
        }
    }
    fclose(fp);
    return count;
}

double find_value(Row rows[], int n, const char *country, int year) {
    for (int i = 0; i < n; i++) {
        if (rows[i].year == year && strcmp(rows[i].country, country) == 0) {
            return rows[i].value;
        }
    }
    return 1e18; 
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        printf("Usage: %s <truth.csv> <pred.csv> <out.csv>\n", argv[0]);
        return 1;
    }

    Row *truth_rows = malloc(MAX_ROWS * sizeof(Row));
    Row *pred_rows = malloc(MAX_ROWS * sizeof(Row));
    CountryStat country_stats[MAX_COLS];
    int num_countries = 0;

    printf("Loading data...\n");
    int n_truth = load_truth_wide(argv[1], truth_rows, MAX_ROWS);
    int n_pred = load_predictions(argv[2], pred_rows, MAX_ROWS);

    // COMPARE
    FILE *fout = fopen(argv[3], "w");
    if (!fout) { printf("Error creating output file.\n"); return 1; }
    fprintf(fout, "Country,Year,Actual,Predicted,AbsError\n");

    int matches = 0;

    for (int i = 0; i < n_pred; i++) {
        double actual = find_value(truth_rows, n_truth, pred_rows[i].country, pred_rows[i].year);
        
        if (actual < 1e17) {
            double err = fabs(pred_rows[i].value - actual);
            
            fprintf(fout, "%s,%d,%.2f,%.2f,%.2f\n", 
                    pred_rows[i].country, pred_rows[i].year, actual, pred_rows[i].value, err);
            
            matches++;

            int idx = get_country_index(country_stats, &num_countries, pred_rows[i].country);
            country_stats[idx].sum_abs_error += err;
            country_stats[idx].sum_sq_error += (err * err);
            
            if (country_stats[idx].count < MAX_YEARS_PER_COUNTRY) {
                country_stats[idx].errors[country_stats[idx].count] = err;
            }
            country_stats[idx].count++;
        }
    }
    fclose(fout);

    // SUMMARY
    char summary_file[256];
    sprintf(summary_file, "summary_%s", argv[3]);
    FILE *fsum = fopen(summary_file, "w");
    fprintf(fsum, "Country,Count,MAE,RMSE,MedianAE\n"); // Added Headers

    printf("Comparison complete. Found %d matching records.\n", matches);
    
    for(int i=0; i<num_countries; i++) {
        CountryStat *s = &country_stats[i];
        if(s->count > 0) {
            double mae = s->sum_abs_error / s->count;
            double rmse = sqrt(s->sum_sq_error / s->count);
            
            // Calculate Median
            double median_ae = 0;
            qsort(s->errors, s->count, sizeof(double), compare_doubles);
            if (s->count % 2 == 0) {
                median_ae = (s->errors[s->count/2 - 1] + s->errors[s->count/2]) / 2.0;
            } else {
                median_ae = s->errors[s->count/2];
            }

            fprintf(fsum, "%s,%d,%.4f,%.4f,%.4f\n", s->name, s->count, mae, rmse, median_ae);
        }
    }
    fclose(fsum);
    
    printf("Results written to:\n  - %s (Detailed)\n  - %s (MAE, RMSE, Median)\n", argv[3], summary_file);

    free(truth_rows);
    free(pred_rows);
    return 0;
}