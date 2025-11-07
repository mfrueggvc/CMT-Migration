% CMT Project – Modelling Emigration using Socio-Economic Indicators
% Goal: Build a simple, interpretable model to estimate emigration rates 
% from a small set of macro indicators (GDP, unemployment, conflict...).

%% 1. Import Data
% Import the datasets (World Bank, ILO, UCDP...) and combine them into a single table.
% Each file should include columns for Country, Year, and Value.


%% 2. Clean and Merge Data
% Align countries and years across datasets.
% Handle missing or inconsistent entries.
% Remove outliers if necessary.

%% 3. Prepare Variables
% Compute emigration per 1000 inhabitants.
% Apply log-transformations if needed.
% Create the final analysis table with all predictors.

%% 4. Build the Model
% Start with a simple linear regression:
% Later, test variations (lagged variables, Poisson regression...).

%% 5. Evaluate Model
% Compare predicted vs observed values.

%% 6. Visualize Results
% Plot correlations and prediction results.
% Example: scatter GDP vs Emigration, or line plots over time.

%% 7. Discussion
% Comment on model performance, main findings, and limitations.