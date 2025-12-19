# South America Migration Prediction Model (1990-2019)

## Project Overview

This project implements a stepwise regression model with autoregressive components to predict net migration flows in South American countries from 2015 to 2019, using socioeconomic data from 1990 to 2014 as training period.
##  Project Structure

```
CMT-Migration/
│
├── REPORT
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
│   │   └── preprocess_Homicide.m
│   │   
│   ├── model/                  # Prediction model
│   │   └── run_model.m 
│   │
│   │
│   └── plots/                  # Visualization
│       └──  run_plot_migration_results.m
├── c/
│   └── run_comparison.c        # Evaluation module (C)           
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
run_preprocessing.m

### Expected Output
- `data/processed/Unemployment_SouthAmerica_1990_2019.csv`
- `data/processed/GDOP_SouthAmerica_1990_2019.csv`
- `data/processed/Homicide_SouthAmerica_1990_2019.csv`
- `data/processed/Schooling_SouthAmerica_1990_2019.csv`
- `data/processed/NetMigration_SouthAmerica_1990_2019.csv`

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
- `results/evaluation/summary_out.csv` #(MAE, MBE, MedianAE, MAPE per country)
  

---

## Step 4: Generate Visualizations
matlab
run_plot_migration_results


## Expected Output:
- PNG graphs in `results/evaluation/TimeSeriesCountryName.png`  #time series for each country (12 Countries)
-  `results/evaluation/Summary_Accuracy.png` # evaluating the accuracy of the model compared to real data 

---

---

##  Model Architecture

### **Training Period:** 1990-2014
### **Prediction Period:** 2015-2019
### Model Version (Prediction model): 8.0


### **Model Type:**
Stepwise regression with interaction terms, fitted using ordinary least squares (OLS).

## **Iterative Prediction:**
Since the model uses lagged migration values, predictions are generated year-by-year (2015, then 2016, etc.), feeding each year's prediction back into the model as a lag variable.

---
## Raw and Engineered Predictors entering the filter : 
-GDPgrowth
-GDPaccel
-LogGDP
-LogSchool
-Unemployment
-UnempChange
-Homicide
-HomicideChange
-LogHomicide
-OpportunityIndex
-EconomicStress
-SafetyIndex
-MigrationLag1
-MigrationLag2
-TimeTrend

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
- ### If you downloads the zip folder : 
- use the bash or terminal to access the project folder:
 cd /home/username/Downloads/CMT-Migration-main. #use your username
- ### If you clone the repository :
- use the bash or terminal to access a folder where you want the project,  
- (example) cd /home/username/Downloads
- then clone the repository : 
- git clone (/URL)  # paste the URL of the repository instead of (/URL)
- enter the folder : 
- cd CMT-Migration      # notice that the name is different if you clone or donwloads the zip 
- ### then execute :                        
- bash run_project.sh ; 

# FINAL OUTPUTS
- All final Outputs are generated into the folder /results. 
- What you want to look at is all the graphs, in /results/evaluation/Graphs you will find the plots showing : 
- 1. The graphs showing the metrics (the accuracy) of the model and the predictions, in Linear and Log scales.(Summary_Accuracy.png)
- 2. The graphs showing for each Country:  the plot of real NetMigration vs predicted NetMigration and an evaluation of the prediction for that specific Country. (files named :TimeSeries_Country.png )
- In /results/predictions you will find the numerical predictions of the model and the metrics self-evaluation from the model. 
- In /results/evaluation you will find the two .csv tables definning the real metrics of the prediction (computed confronting real data).

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

- **Preprocessing:** < 2 minutes
- **Model Predictions:** ~ 2-5minutes (depends on # countries)
- **Evaluation:** < 30 second
- **Visualization:** < 2 minutes

**Total:** ~5-10 minutes maximum on a standard laptop

---




**Last Updated:** December 2025  
**Project Version:** 1.0
