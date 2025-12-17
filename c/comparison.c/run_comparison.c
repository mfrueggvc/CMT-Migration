#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h> 

static void build_summary_path(const char *out_path, char *summary_path, size_t n) {
    const char *last_slash  = strrchr(out_path, '/');
    const char *last_bslash = strrchr(out_path, '\\');
    const char *sep = last_slash > last_bslash ? last_slash : last_bslash;

    if (sep) {
        size_t dir_len = (size_t)(sep - out_path + 1);
        if (dir_len >= n) dir_len = n - 1;
        memcpy(summary_path, out_path, dir_len);
        summary_path[dir_len] = '\0';
        strncat(summary_path, "summary_out.csv", n - strlen(summary_path) - 1);
    } else {
        strncpy(summary_path, "summary_out.csv", n - 1);
        summary_path[n - 1] = '\0';
    }
}

// CONFIGURATION
 #define MAX_ROWS 1000   
 #define MAX_COLS 200    
 #define MAX_LINE 4096   
 #define MAX_YEARS_PER_COUNTRY 200 
 
 typedef struct {
     char country[64];
     int year;
     double value;
 } Row;
 
 typedef struct {
     char name[64];
     double sum_abs_error;  
     double sum_bias;       
     double sum_sq_error;   // Using this slot for Sum of MAPE (per country)
     double errors[MAX_YEARS_PER_COUNTRY]; 
     int count;
 } CountryStat;
 
 // Comparison for Median calculation
 int compare_doubles(const void *a, const void *b) {
     double arg1 = *(const double *)a;
     double arg2 = *(const double *)b;
     if (arg1 < arg2) return -1;
     if (arg1 > arg2) return 1;
     return 0;
 }
 
 // Remove quotes/whitespace without allocation
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
 
 // Uppercase + Trim without allocation
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
     stats[*count].sum_bias = 0; 
     stats[*count].sum_sq_error = 0;
     stats[*count].count = 0;
     (*count)++;
     return (*count) - 1;
 }
 
 // 1. LOAD TRUTH (Wide Format)
 int load_truth_wide(const char *filename, Row rows[], int max_rows) {
     FILE *fp = fopen(filename, "r");
     if (!fp) { printf("Error: Could not open truth file %s\n", filename); return -1; }
 
     char line[MAX_LINE];
     char country_headers[MAX_COLS][64];
     int num_countries = 0;
     int row_count = 0;
 
     if (fgets(line, sizeof(line), fp)) {
         char *start = line;
         if ((unsigned char)line[0] == 0xEF && (unsigned char)line[1] == 0xBB) start += 3;
         
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
 
     while (fgets(line, sizeof(line), fp) && row_count < max_rows) {
         char line_copy[MAX_LINE];
         strcpy(line_copy, line);
         
         char *token = strtok(line_copy, ",;");
         if (!token) continue;
         
         strip_clean(token);
         if (strlen(token) == 0) continue; 
 
         int year = atoi(token);
 
         for (int i = 0; i < num_countries; i++) {
             token = strtok(NULL, ",;");
             if (token) {
                 strip_clean(token);
                 strcpy(rows[row_count].country, country_headers[i]);
                 rows[row_count].year = year;
                 rows[row_count].value = atof(token);
                 row_count++;
                 if (row_count >= max_rows) break;
             }
         }
     }
     fclose(fp);
     return row_count;
 }
 
 // 2. LOAD PREDICTIONS
 int load_predictions(const char *filename, Row rows[], int max_rows) {
     FILE *fp = fopen(filename, "r");
     if (!fp) { printf("Error: Could not open prediction file %s\n", filename); return -1; }
 
     char line[MAX_LINE];
     int count = 0;
     
     fgets(line, sizeof(line), fp); // Skip header
 
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
 
     static Row truth_rows[MAX_ROWS];
     static Row pred_rows[MAX_ROWS];
     static CountryStat country_stats[MAX_COLS]; 
     int num_countries = 0;
 
     printf("Loading data...\n");
     int n_truth = load_truth_wide(argv[1], truth_rows, MAX_ROWS);
     int n_pred = load_predictions(argv[2], pred_rows, MAX_ROWS);
 
     if (n_truth < 0 || n_pred < 0) return 1;
 
     FILE *fout = fopen(argv[3], "w");
     if (!fout) { printf("Error creating output file.\n"); return 1; }
     
     fprintf(fout, "Country,Year,Actual,Predicted,Residual,PctError\n");
 
     int matches = 0;

     double global_sum_ape = 0.0; 
     
 
     for (int i = 0; i < n_pred; i++) {
         double actual = find_value(truth_rows, n_truth, pred_rows[i].country, pred_rows[i].year);
         
         if (actual < 1e17) {
             double residual = actual - pred_rows[i].value; 
             double abs_err = fabs(residual);
             
             double pct_err = 0.0;
             if (fabs(actual) > 1e-9) { 
                 pct_err = (pred_rows[i].value - actual) / actual * 100.0;
             }
             double abs_pct_err = fabs(pct_err);
 
             global_sum_ape += abs_pct_err;

 
             fprintf(fout, "%s,%d,%.2f,%.2f,%.2f,%.2f\n", 
                     pred_rows[i].country, pred_rows[i].year, actual, pred_rows[i].value, residual, pct_err);
             
             matches++;
 
             int idx = get_country_index(country_stats, &num_countries, pred_rows[i].country);
             country_stats[idx].sum_abs_error += abs_err;
             country_stats[idx].sum_bias += residual; 
             country_stats[idx].sum_sq_error += abs_pct_err; 
             
             if (country_stats[idx].count < MAX_YEARS_PER_COUNTRY) {
                 country_stats[idx].errors[country_stats[idx].count] = abs_err;
             }
             country_stats[idx].count++;
         }
     }
     fclose(fout);
 
     // --- SUMMARY GENERATION ---
     char summary_file[256];
     sprintf(summary_file, "summary_%s", argv[3]);
     FILE *fsum = fopen(summary_file, "w");
     
     fprintf(fsum, "Country,Count,MAE,MBE,MedianAE,MAPE\n"); 
 
     printf("Comparison complete. Found %d matching records.\n", matches);
 
     if (matches > 0) {
         double overall_mape = global_sum_ape / matches;
         printf("\n------------------------------------------------\n");
         printf(" RESULTS CONTROL SUMMARY\n");
         printf("------------------------------------------------\n");
         printf(" Total Matches Processed: %d\n", matches);
         printf(" Overall MAPE (All Data): %.2f%%\n", overall_mape);
         printf("------------------------------------------------\n\n");
     }
     
     for(int i=0; i<num_countries; i++) {
         CountryStat *s = &country_stats[i];
         if(s->count > 0) {
             double mae = s->sum_abs_error / s->count;
             double mbe = s->sum_bias / s->count;
             double mape = s->sum_sq_error / s->count;
             
             double median_ae = 0;
             qsort(s->errors, s->count, sizeof(double), compare_doubles);
             if (s->count % 2 == 0) {
                 median_ae = (s->errors[s->count/2 - 1] + s->errors[s->count/2]) / 2.0;
             } else {
                 median_ae = s->errors[s->count/2];
             }
 
             fprintf(fsum, "%s,%d,%.4f,%.4f,%.4f,%.2f\n", s->name, s->count, mae, mbe, median_ae, mape);
         }
     }
     fclose(fsum);
     
     return 0;
 }