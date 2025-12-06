#include <stdio.h>
<<<<<<< Updated upstream
=======
#include <stdlib.h>
#include <string.h>
#include <math.h>

// FIX: Use #define for array sizes to avoid VLA warnings
#define MAX_ROWS 5000
#define MAX_COLS 50     // Max number of countries (columns) in truth file
#define MAX_LINE 2048   // Increased buffer size for wide rows

// Structure for raw data rows
typedef struct {
    char country[64];
    int year;
    double value;
} Row;

// Structure to aggregate statistics per country
typedef struct {
    char name[64];
    double sum_abs_error;
    int count;
} CountryStat;

// Helper: Find or create a country index in the stats array
int get_country_index(CountryStat stats[], int *count, const char *name) {
    for (int i = 0; i < *count; i++) {
        if (strcmp(stats[i].name, name) == 0) {
            return i;
        }
    }
    // If not found, add new country
    strcpy(stats[*count].name, name);
    stats[*count].sum_abs_error = 0;
    stats[*count].count = 0;
    (*count)++;
    return (*count) - 1;
}

// Helper to clean strings (remove newlines/quotes)
void clean_token(char *str) {
    str[strcspn(str, "\r\n")] = 0; // Remove newlines
}

// 1. NEW: Function to load "Wide" Truth CSV (Year, Country1, Country2, ...)
int load_truth_wide(const char *filename, Row rows[], int max_rows) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        printf("Error: Could not open truth file %s\n", filename);
        return -1;
    }

    char line[MAX_LINE];
    char country_headers[MAX_COLS][64];
    int num_countries = 0;
    int row_count = 0;

    // A. Parse Header (Row 1)
    if (fgets(line, sizeof(line), fp)) {
        clean_token(line);
        
        // First token is "Year" (skip it)
        char *token = strtok(line, ","); 
        if (!token) { fclose(fp); return 0; }

        // Subsequent tokens are Country Names
        while ((token = strtok(NULL, ",")) != NULL) {
            if (num_countries < MAX_COLS) {
                // Copy header name to storage
                strncpy(country_headers[num_countries], token, 63);
                country_headers[num_countries][63] = '\0';
                num_countries++;
            }
        }
    }

    // B. Parse Data Rows
    while (fgets(line, sizeof(line), fp)) {
        clean_token(line);
        
        // 1. Get Year (First column)
        char *token = strtok(line, ",");
        if (!token) continue;
        int year = atoi(token);

        // 2. Loop through Country Columns
        for (int i = 0; i < num_countries; i++) {
            token = strtok(NULL, ",");
            if (token && row_count < max_rows) {
                // Create a row entry for this country/year cell
                strcpy(rows[row_count].country, country_headers[i]);
                rows[row_count].year = year;
                rows[row_count].value = atof(token);
                row_count++;
            }
        }
        
        if (row_count >= max_rows) {
            printf("Warning: Max rows reached while loading truth file.\n");
            break;
        }
    }

    fclose(fp);
    return row_count;
}

// 2. Function to load "Long" Prediction CSV (Country, Year, Value)
// (Renamed from load_csv to be specific)
int load_predictions(const char *filename, Row rows[], int max_rows) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        printf("Error: Could not open prediction file %s\n", filename);
        return -1;
    }

    char line[256];
    int count = 0;

    // Skip header
    fgets(line, sizeof(line), fp);

    while (count < max_rows && fgets(line, sizeof(line), fp)) {
        char country[64];
        int year;
        double val;

        // Parse: Country,Year,Value
        if (sscanf(line, "%63[^,],%d,%lf", country, &year, &val) == 3) {
            strcpy(rows[count].country, country);
            rows[count].year = year;
            rows[count].value = val;
            count++;
        }
    }

    fclose(fp);
    return count;
}

// 3. Function to find a value in the array
double find_value(Row rows[], int n, const char *country, int year) {
    for (int i = 0; i < n; i++) {
        // Case-insensitive comparison might be safer, but using strict strcmp for now
        if (rows[i].year == year && strcmp(rows[i].country, country) == 0) {
            return rows[i].value;
        }
    }
    return 1e18; // Sentinel for "not found"
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        // Updated usage message with your specific filenames
        printf("Usage: %s <NetMigration_SouthAmerica_1990_2019.csv> <predicted_migration_all_countries.csv> <output_results.csv>\n", argv[0]);
        return 1;
    }

    const char *file_truth = argv[1];
    const char *file_pred = argv[2];
    const char *file_out_detailed = argv[3];

    // Setup Memory
    Row truth_rows[MAX_ROWS];
    Row pred_rows[MAX_ROWS];

    // Stats for countries (Max 50 countries)
    CountryStat country_stats[50];
    int num_countries = 0;

    // Load Files
    printf("Loading Truth file (Wide Format)...\n");
    int n_truth = load_truth_wide(file_truth, truth_rows, MAX_ROWS);
    
    printf("Loading Prediction file (Long Format)...\n");
    int n_pred = load_predictions(file_pred, pred_rows, MAX_ROWS);

    if (n_truth <= 0) { printf("Error: No truth data loaded.\n"); return 1; }
    if (n_pred <= 0) { printf("Error: No prediction data loaded.\n"); return 1; }

    printf("Loaded %d ground truth records (expanded).\n", n_truth);
    printf("Loaded %d prediction records.\n", n_pred);

    // Prepare Detailed Output File
    FILE *fout_detail = fopen(file_out_detailed, "w");
    if (!fout_detail) {
        printf("Error: Could not create output file %s\n", file_out_detailed);
        return 1;
    }
    fprintf(fout_detail, "Country,Year,Actual,Predicted,AbsError\n");

    // Global Accumulators
    double global_sum_abs = 0;
    double global_sum_sq = 0;
    int matched_count = 0;

    // Processing Loop
    for (int i = 0; i < n_pred; i++) {
        double actual_val = find_value(truth_rows, n_truth, pred_rows[i].country, pred_rows[i].year);

        if (actual_val < 1e17) {
            double diff = pred_rows[i].value - actual_val;
            double abs_err = fabs(diff);
            
            // 1. Write Detailed Data
            fprintf(fout_detail, "%s,%d,%.2f,%.2f,%.2f\n", 
                    pred_rows[i].country, pred_rows[i].year, 
                    actual_val, pred_rows[i].value, abs_err);

            // 2. Update Global Stats
            global_sum_abs += abs_err;
            global_sum_sq += (diff * diff);
            matched_count++;

            // 3. Update Per-Country Stats
            int idx = get_country_index(country_stats, &num_countries, pred_rows[i].country);
            country_stats[idx].sum_abs_error += abs_err;
            country_stats[idx].count++;
        }
    }
    fclose(fout_detail);

    // Create Summary Filename (e.g., "summary_results.csv")
    char file_out_summary[256];
    sprintf(file_out_summary, "summary_%s", file_out_detailed);
    
    FILE *fout_summary = fopen(file_out_summary, "w");
    if (!fout_summary) return 1;
    fprintf(fout_summary, "Country,MAE\n");

    // Write Summary File
    printf("\n--- Per Country Accuracy ---\n");
    for (int i = 0; i < num_countries; i++) {
        if (country_stats[i].count > 0) {
            double mae = country_stats[i].sum_abs_error / country_stats[i].count;
            fprintf(fout_summary, "%s,%.4f\n", country_stats[i].name, mae);
            printf("%-15s MAE: %.2f\n", country_stats[i].name, mae);
        }
    }
    fclose(fout_summary);

    printf("\n--- Global Summary ---\n");
    printf("Detailed data saved to: %s\n", file_out_detailed);
    printf("Aggregated data saved to: %s\n", file_out_summary);
>>>>>>> Stashed changes

int main() {
    printf("Hello, world!\n");
    return 0;
}


