# South America Migration Prediction Model (1990-2019)

## Project Overview

This project implements a multi-linear regression model with autoregressive components to predict net migration flows in South American countries from 2015 to 2019, using socioeconomic data from 1990 to 2014 as training period.

# Key Features:
- Feature engineering with economic indicators (GDP growth, unemployment, education, homicide rates)
- Autoregressive approach with lagged migration variables
- Interactive term modeling (e.g., crime × unemployment)
- Comprehensive evaluation with MAE, MBE, and Median Absolute Error
- Automated visualization pipeline

------  REMOVE BEFORE SUBMISSION--------------------------------------------------------------------------
### **Recommended Structure:**
```
CMT_Migration_Project.zip
├── code/               (all .m, .c, .sh files)
├── data/raw/           (original datasets)
├── data/ground_truth/  (validation data)
├── results_example/    (sample outputs - optional)
└── README.md           (this file)
```

### **Exclude:**
- Temporary files (`.asv`, `*~`, `.DS_Store`)
- Compiled binaries (`run_comparison`, `*.exe`)
- Generated outputs (`data/processed/`, `results/`)
- Version control (`.git/`)

---

## Pre-Submission Checklist

- [ ] All raw data files present in `data/raw/`
- [ ] Ground truth file specified in script
- [ ] Script tested at least once successfully
- [ ] README updated with any special instructions
- [ ] File names corrected (no duplicates like "(1)")
- [ ] Sample outputs included (optional but recommended)
-------------------------------------------------------------------------------------------------------------------------------------


##  System Requirements

### **Software Dependencies:**
- **MATLAB** (R2020a or later recommended)
- **GCC Compiler** (for C evaluation module)
- **Bash Shell** (Linux/Mac) or **Command Prompt** (Windows)

--- 

---



### **All Platforms (Recommended):**
```bash
chmod +x run_project.sh
./run_project.sh
```



> **Windows Note:** The script creates log files (`matlab_preprocessing.log`, `matlab_model.log`, `matlab_plots.log`) to capture all MATLAB output. Check these files if errors occur.

---

##  Project Structure

```
CMT-Migration/
│
├── run_project.sh              # Main automation script (Unix)
├── README.md                   # This file
├── .git/
├── data/
│   ├── raw/                    # Original datasets (user-provided)
│   │   ├── GDP_Worldbank_Unchanged.csv
│   │   ├── Years_Of_Schooling_UNDP_Unchanged.csv
│   │   ├── Unemployment_Worldbank_Unchanged.csv
│   │   ├── Net_Migration_Worldbank_Unchanged.csv
│   │   ├── Homicide_Worldbank_Unchanged.csv
│   │   └── Population.csv
│   │
│   ├── processed/              # Cleaned datasets (auto-generated)
│   │
│   └── ground_truth/          
│       └── Net_Migration_South_America_1990_2019.csv
│
├── matlab/
│   ├── preprocessing/          # Data cleaning scripts
│   │   ├── run_preprocessing.m
│   │   ├── preprocess_GDP.m
│   │   ├── preprocess_Schooling.m
│   │   ├── preprocess_Unemployment.m
│   │   ├── preprocess_NetMigration.m
│   │   ├── preprocess_Homicide.m
│   │   ├── code_to_read_GDP.m
│   │   ├── code_to_read_Schooling.m
│   │   ├── code_to_read_Unemployment.m
│   │   ├── code_to_read_NetMigration.m
│   │   └── code_to_read_Homicide.m
│   ├── model/                  # Prediction model
│   │   ├── model5.m
│   │   └── run_model.m
│   │
│   │
│   └── plots/                  # Visualization
│       ├── run_plot_migration_results.m
│       └── plot_migration_results.m
├── c/
│   ├── run_comparison.c        # Evaluation module (C)
│   └── migration_compare.c          # Compiled binary (auto-generated)
│
└── results/
    ├── predictions/            # Model outputs (CSV)
    │   ├── predicted_migration_all_countries.csv
    │   ├── predicted_migration_south_america.csv
    │   └── model_quality_metrics.csv
    │
    └── evaluation/             # Performance metrics + plots
        ├── out.csv             # Year-by-year comparison
        ├── summary_out.csv     # Aggregated metrics (MAE, MBE, MedianAE)
        └── Graphs/             # PNG visualizations
```



### Step 1 : Preprocess raw data
matlab
addpath(fullfile(pwd,'matlab','preprocessing'))
run_preprocessing.m

# Expected Output
- `data/processed/ ------------------------------------------------------------------------------------------------------------------------------


### Step 2: Run Prediction Model
matlab
addpath(fullfile(pwd,'matlab','model'))
run_model.m


# Expected Output:
- `results/predictions/predicted_migration_all_countries.csv`
- `results/predictions/model_quality_metrics.csv`

---

### **Step 3: Evaluate Predictions (Terminal/CMD)**

# Linux/Mac:
bash
gcc -O2 -Wall -Wextra -o c/run_comparison c/run_comparison.c -lm

./c/run_comparison \
  "data/ground_truth/migration_truth.csv" \
  "results/predictions/predicted_migration_all_countries.csv" \
  "results/evaluation/out.csv"


 # Windows (CMD):
cmd
gcc -O2 -Wall -Wextra -o c\run_comparison.exe c\run_comparison.c -lm

c\run_comparison.exe ^
  "data\ground_truth\migration_truth.csv" ^
  "results\predictions\predicted_migration_all_countries.csv" ^
  "results\evaluation\out.csv"


 # Expected Output: -------------------------------------------------------------------------------------------------------------------------------------
- `results/evaluation/out.csv` (detailed residuals)
- `results/evaluation/summary_out.csv` (MAE, MBE, MedianAE per country)
  ARE THIS THE FILES OUTPUT OF MARFK ??? 

---

### Step 4: Generate Visualizations
matlab
addpath(fullfile(pwd,'matlab','plots'))
run_plot_migration_results


# Expected Output:
- PNG graphs in `results/evaluation/Graphs/` ----------------------------------------------------------------------------------------------------



# Required Format (Wide):
csv
Year,Argentina,Bolivia,Brazil,Chile,Colombia,...
2015,12000,5000,30000,8000,15000,...
2016,11500,4800,28000,7500,14000,...
...


---

## Raw Data Files
If your files in `data/raw/` have different names, update the `readtable()` calls in:
- `matlab/preprocessing/preprocess_GDP.m`
- `matlab/preprocessing/preprocess_Schooling.m`
- `matlab/preprocessing/preprocess_Unemployment.m`
- `matlab/preprocessing/preprocess_NetMigration.m`
- `matlab/preprocessing/preprocess_Homicide.m`

---

##  Model Architecture

### **Training Period:** 1990-2014
### **Prediction Period:** 2015-2019

### **Features Used:**
1. **Economic Indicators:**
   - GDP Growth (year-over-year %)
   - GDP Acceleration (2nd derivative)
   - Log(GDP) - reduces outlier impact

2. **Education:**
   - Mean Years of Schooling
   - Log(SchoolYears)

3. **Labor Market:**
   - Unemployment Rate (%)
   - Unemployment Change

4. **Safety:**
   - Homicide Rate (per 100k)
   - Homicide Change
   - Log(Homicide)

5. **Derived Features:**
   - Opportunity Index = GDP / SchoolYears
   - Economic Stress = Unemployment × |GDP Growth|
   - Safety Index = Homicide × Unemployment

6. **Autoregressive Terms:**
   - Migration Lag 1 (previous year)
   - Migration Lag 2 (2 years prior)
   - Migration Velocity (trend)

7. **Interaction Terms:**
   - GDP Growth × Unemployment
   - Migration Lag 1 × GDP Growth
   - Log(GDP) × Log(SchoolYears)
   - Homicide × Unemployment

### **Model Type:**
Multi-linear regression with interaction terms, fitted using ordinary least squares (OLS).

## **Iterative Prediction:**
Since the model uses lagged migration values, predictions are generated year-by-year (2015, then 2016, etc.), feeding each year's prediction back into the model as a lag variable.

---

#  Evaluation Metrics

| Metric | Description | Interpretation |
|--------|-------------|----------------|
| **MAE** | Mean Absolute Error | Average magnitude of errors |
| **MBE** | Mean Bias Error | Direction of errors (+ = underprediction, - = overprediction) |
| **MedianAE** | Median Absolute Error | Robustness to outliers |
| **R²** | Coefficient of Determination | Training fit quality (0-1) |
| **RMSE** | Root Mean Square Error | Penalizes large errors |

---

# Troubleshooting

### **Error: "Missing predictions file"**
**Cause:** MATLAB model did not complete.  
**Solution:**
1. Check file names in `data/processed/`
2. Verify no missing data in raw CSV files
3. Run `run_model.m` manually in MATLAB to see errors



---

### **MATLAB Hangs or Shows No Output (Windows)**
**Cause:** Git Bash + MATLAB communication issue.  
**Solution:**
1. run manually from MATLAB Desktop
2. OR use CMD/PowerShell instead of Git Bash

---

### **MATLAB Freezes When Opening Folder**
**Cause:** OneDrive sync conflict or too many files.  
**Solution:**
1. Don't use "Open Folder" - use only `cd` command
2. Move project outside OneDrive:
```bash
cp -r CMT-Migration ~/Desktop/CMT-Migration
```
3. Exclude folder from OneDrive sync

---

### **GCC Not Found**
**Solution:**
- **Windows:** Install MinGW or use WSL
- **macOS:** `xcode-select --install`
- **Linux:** `sudo apt install build-essential`



____


### References

# Data Sources:
- GDP, Unemployment, Homicide: World Bank Open Data
- Education: UNDP Human Development Reports
- Migration: UN DESA Population Division

# Methodology:
- Feature engineering inspired by econometric migration models
- Autoregressive approach follows Box-Jenkins methodology
- Evaluation metrics standard in time series forecasting

---

##  Author

**Project:** Computational Methods and Tools - Migration Analysis  
**Institution:** EPFL  
**Year:** 2025  
**Students :** Mirto Regazzoni, Mark Ruegg, Aimé Couty

---

## License

This project is submitted as coursework. All data used is publicly available from official sources (World Bank, UN, UNDP).

---

##  Expected Runtime

- **Preprocessing:** ~30 seconds
- **Model Training:** ~2-5 minutes (depends on # countries)
- **Evaluation:** <1 second
- **Visualization:** ~10 seconds

**Total:** ~5-10 minutes on a standard laptop

---

##  Notes for Reviewers
 **Missing dependencies:** All required software is listed in "System Requirements"


### ** IMPORTANT ** : 
   On Windows systems using individual MATLAB licenses, headless execution via shell scripts may fail due to licensing restrictions. In this case, the project can be executed by launching MATLAB manually and running the provided master script.

**Last Updated:** December 2025  
**Version:** 1.0
