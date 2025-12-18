# South America Migration Prediction Model (1990-2019)

## Project Overview

This project implements a multi-linear regression model with autoregressive components to predict net migration flows in South American countries from 2015 to 2019, using socioeconomic data from 1990 to 2014 as training period.
##  Project Structure

```
CMT-Migration/
│
├── run_project.sh              # Main automation script 
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
│   └── migration_compare.c          
│
└── results/
    ├── predictions/            # Model outputs (CSV)
    │   ├── predicted_migration_all_countries.csv
    │   └── model_quality_metrics.csv                
    │
    └── evaluation/             # Performance metrics + plots
        ├── out.csv             # Year-by-year comparison
        ├── summary_out.csv     # Aggregated metrics (MAE, MBE, MedianAE)
        └── Graphs/             # PNG visualizations 
```



## Step 1 : Preprocess raw data
matlab
addpath(fullfile(pwd,'matlab','preprocessing'))
run_preprocessing.m

### Expected Output
- `data/processed/ 


## Step 2: Run Prediction Model
matlab
addpath(fullfile(pwd,'matlab','model'))
run_model.m


### Expected Output:
- `results/predictions/predicted_migration_all_countries.csv` #predictions for each country
- `results/predictions/model_quality_metrics.csv` # self evaluation of the model

---

## Step 3: Evaluate Predictions


### Expected Output: 
- `results/evaluation/out.csv` #(detailed residuals)
- `results/evaluation/summary_out.csv` #(MAE, MBE, MedianAE per country)
  

---

## Step 4: Generate Visualizations
matlab
run_plot_migration_results


## Expected Output:
- PNG graphs in `results/evaluation/TimeSeriesCountry.png`  #time series for each country
- `results/evaluation/Summary_Metrics_Linear.png`, `results/evaluation/Summary_Metrics_LogScale.png` # two graph evaluating the accuracy of the model compared to real data


# Required Format (Wide):
csv
Year,Argentina,Bolivia,Brazil,Chile,Colombia,...
2015,12000,5000,30000,8000,15000,...
2016,11500,4800,28000,7500,14000,...
...


---

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

## Evaluation Metrics

| Metric | Description | Interpretation |
|--------|-------------|----------------|
| **MAE** | Mean Absolute Error | Average magnitude of errors |
| **MBE** | Mean Bias Error | Direction of errors (+ = underprediction, - = overprediction) |
| **MedianAE** | Median Absolute Error | Robustness to outliers |
| **R²** | Coefficient of Determination | Training fit quality (0-1) |
| **RMSE** | Root Mean Square Error | Penalizes large errors |


# RUNNING THE PROGRAMM : 

## Software Dependencies:
- **MATLAB** - MATLAB R2021b (command available as `matlab-2021b` on Linux systems)
- **GCC Compiler** (for C evaluation module)
- **Bash Shell** (Linux/Mac) or **Command Prompt** (Windows)

## BUILD: 
No need to build anything

## Execute

- Download the zip folder of the project
on the bash access the project folder : (example): cd /home/username/Downloads/CMT-Migration-main. 
- then execute : 
- chmod +x run_project.sh ; 
- ./run_project.sh ; 
### FINAL OUTPUTS
- All final Outputs are generated into the folder /results. 
- what you want to look at is all the graphs, in /results/evaluation/Graphs you will find the plots showing : 
-1. The graphs showing the metrics (the accuracy) of the model and the predictions, in Linear and Log scales.(Summary_Metrics_Linear.png and Summary_Metrics_LogScale.png)
-2. The graphs showing for each Country:  the plot of real NetMigration vs predicted NetMigration and an evaluation of the prediction for that specific Country. (files named :TimeSeries_Country.png )
- In /results/predictions you will find the numerical predictions of the model and the metrics self-evaluation from the model. 
- In /results/evaluation you will find the two .csv tables definning the real metrics of the model (computed confronting real data).

``` 
```
## Note: 
The script creates log files (`matlab_preprocessing.log`, `matlab_model.log`, `matlab_plots.log`) to capture all MATLAB output. Check these files if errors occur.
```
```
### Contributors 
Students : Mirto Regazzoni, Mark Ruegg, Aimé Couty
with the help of generative AI



# Data Sources:
- GDP, Unemployment, Homicide: World Bank Open Data
- Education: UNDP Human Development Reports
- Migration: UN DESA Population Division

# Methodology:
- Feature engineering inspired by econometric migration models
- Autoregressive approach follows Box-Jenkins methodology
- Evaluation metrics standard in time series forecasting

---
--- 

--- 
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


### ** IMPORTANT ** : 
   On Windows systems using individual MATLAB licenses, headless execution via shell scripts may fail due to licensing restrictions. In this case, the project can be executed by launching MATLAB manually and running the provided master script.

**Last Updated:** December 2025  
**Version:** 1.0
