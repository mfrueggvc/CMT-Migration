#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// Define the structure
typedef struct {
    char country[64];
    int year;
    double value; // Renamed from net_migration
} Row;

// 1. Function to load CSV (Moved outside main)
int load_csv(const char *filename, Row rows[], int max_rows) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        printf("Error: Could not open file %s\n", filename);
        return -1;
    }

    char line[256];
    int count = 0;

    // Skip header
    fgets(line, sizeof(line), fp);

    while (fgets(line, sizeof(line), fp)) {
        char country[64];
        int year;
        double val;

        // Parse line: Country,Year,Value
        if (sscanf(line, "%63[^,],%d,%lf", country, &year, &val) == 3) {
            strcpy(rows[count].country, country);
            rows[count].year = year;
            rows[count].value = val;
            count++;
        
        }
    }

    // Close the file before returning the count of rows loaded
    fclose(fp);
    return count;
}

// 2. Function to find a value in the array (Moved outside main)
double find_value(Row rows[], int n, const char *country, int year) {
    for (int i = 0; i < n; i++) {
        // Compare year and country string
        if (rows[i].year == year && strcmp(rows[i].country, country) == 0) {
            return rows[i].value;
        }
    }
    return 1e18; // Sentinel for "not found"
    // Ensure all control paths return a value
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <truth.csv> <predictions.csv>\n", argv[0]);
        return 1;
    }

    // Define max rows (adjust if your files are larger)
    const int MAX_ROWS = 5000;
    
    // Allocate memory for the "Ground Truth" data
    // Using static arrays for simplicity based on your snippet
    Row truth_rows[MAX_ROWS];
    Row pred_rows[MAX_ROWS];

    // Load the files
    printf("Loading files...\n");
    int n_truth = load_csv(argv[1], truth_rows, MAX_ROWS);
    int n_pred = load_csv(argv[2], pred_rows, MAX_ROWS);

    if (n_truth < 0 || n_pred < 0) return 1;

    printf("Loaded %d ground truth records.\n", n_truth);
    printf("Loaded %d prediction records.\n", n_pred);

    // Variables for statistics
    double sum_abs_diff = 0;
    double sum_sq_diff = 0;
    int matched_count = 0;
    int unmatched_count = 0;

    // Loop through every prediction and try to find it in the truth data
    for (int i = 0; i < n_pred; i++) {
        double actual_val = find_value(truth_rows, n_truth, pred_rows[i].country, pred_rows[i].year);

        if (actual_val > 1e17) { // Check against sentinel
            unmatched_count++;
        } else {
            double diff = pred_rows[i].value - actual_val;
            sum_abs_diff += fabs(diff);
            sum_sq_diff += (diff * diff);
            matched_count++;
        }
    }

    // Calculate final stats
    printf("\n--- Results ---\n");
    if (matched_count > 0) {
        double mae = sum_abs_diff / matched_count;
        double mse = sum_sq_diff / matched_count;
        double rmse = sqrt(mse);

        printf("Matched: %d | Unmatched: %d\n", matched_count, unmatched_count);
        printf("MAE:  %.4f\n", mae);
        printf("RMSE: %.4f\n", rmse);
    } else {
        printf("No matches found between files.\n");
    }

    return 0;
}