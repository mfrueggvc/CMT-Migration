clc; clear; close all;

fprintf('=== Migration Prediction Model for South America ===\n');
fprintf('Training period: 1990-2014\n');
fprintf('Prediction period: 2015-2019\n');


thisFile    = mfilename('fullpath');
modelDir    = fileparts(thisFile);
matlabDir   = fileparts(modelDir);
projectRoot = fileparts(matlabDir);

dataDir    = fullfile(projectRoot, 'data', 'processed');
resultsDir = fullfile(projectRoot, 'results', 'predictions');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end



%% DATA LOADING 
% Load GDP 
Tg = readtable(fullfile(dataDir, 'GDP_SouthAmerica_1990_2019.csv')); 
varCountries = Tg.Properties.VariableNames(2:end); 
Tg = stack(Tg, varCountries, 'NewDataVariableName', 'GDP', 'IndexVariableName', 'Country'); 
Tg.Country = upper(strtrim(string(Tg.Country))); 

% Load Schooling 
Ts = readtable(fullfile(dataDir,"Schooling_SouthAmerica_1990_2019.csv")); 
varCountries = Ts.Properties.VariableNames(2:end); 
Ts = stack(Ts, varCountries, 'NewDataVariableName', 'SchoolYears', 'IndexVariableName', 'Country'); 
Ts.Country = upper(strtrim(string(Ts.Country))); 
Ts = Ts(:, {'Country','Year','SchoolYears'}); 

% Load Unemployment 
Tu = readtable(fullfile(dataDir,'Unemployment_SouthAmerica_1990_2019.csv')); 
varCountries = Tu.Properties.VariableNames(2:end); 
Tu = stack(Tu, varCountries, 'NewDataVariableName', 'Unemployment', 'IndexVariableName', 'Country'); 
Tu.Country = upper(strtrim(string(Tu.Country))); 
Tu = Tu(:, {'Country','Year','Unemployment'}); 

% Load Net Migration (only used for training up to 2014) 
Tn = readtable(fullfile(dataDir,'NetMigration_SouthAmerica_1990_2019.csv')); 
varCountriesN = Tn.Properties.VariableNames(2:end); 
Tn = stack(Tn, varCountriesN, 'NewDataVariableName', 'NetMigration', 'IndexVariableName', 'Country'); 
Tn.Country = upper(strtrim(string(Tn.Country))); 

% Load Homicide Rate (per 100k population)
Th = readtable(fullfile(dataDir,'Homicide_SouthAmerica_1990_2019.csv')); 
varCountries = Th.Properties.VariableNames(2:end); 
Th = stack(Th, varCountries, 'NewDataVariableName', 'Homicide', 'IndexVariableName', 'Country'); 
Th.Country = upper(strtrim(string(Th.Country))); 
Th = Th(:, {'Country','Year','Homicide'});


%% MERGE ALL DATASETS
T = innerjoin(Tg, Ts, 'Keys', {'Country','Year'}); 
T = innerjoin(T, Tu, 'Keys', {'Country','Year'}); 
T = innerjoin(T, Tn, 'Keys', {'Country','Year'}); 
T = innerjoin(T, Th, 'Keys', {'Country', 'Year'}); 

countries = unique(T.Country); 
fprintf('Countries found: %d\n', length(countries)); 
for i = 1:length(countries) 
    fprintf('  - %s\n', countries{i}); 
end 
fprintf('\n'); 

%% PROCESS EACH COUNRTY
allPredictions = table(); 
allMetrics = table(); 

for c = 1:length(countries) 
    currentCountry = countries{c}; 
    fprintf('Processing %s...\n', currentCountry); 
    
    Tcountry = T(strcmpi(T.Country, currentCountry), :); 
    if isempty(Tcountry) 
        fprintf('  Warning: No data for %s. Skipping.\n\n', currentCountry); 
        continue; 
    end 
    
    Tcountry = sortrows(Tcountry, 'Year'); 
    
    %% filling missing value
    
    % GDP: Linear interpolation
    if any(isnan(Tcountry.GDP)) 
        validIdx = ~isnan(Tcountry.GDP); 
        if sum(validIdx) >= 2 
            Tcountry.GDP = interp1(Tcountry.Year(validIdx), Tcountry.GDP(validIdx), ... 
                                   Tcountry.Year, 'linear', 'extrap'); 
        else 
            Tcountry.GDP = fillmissing(Tcountry.GDP, 'constant', nanmean(Tcountry.GDP)); 
        end 
    end 
    
    % SchoolYears: Smooth monotonic growth
    if any(isnan(Tcountry.SchoolYears)) 
        validIdx = ~isnan(Tcountry.SchoolYears); 
        if sum(validIdx) >= 2 
            Tcountry.SchoolYears = interp1(Tcountry.Year(validIdx), ... 
                                           Tcountry.SchoolYears(validIdx), ... 
                                           Tcountry.Year, 'pchip', 'extrap'); 
        else 
            Tcountry.SchoolYears = fillmissing(Tcountry.SchoolYears, 'constant', nanmean(Tcountry.SchoolYears)); 
        end 
    end 
    
    % Unemployment: Can fluctuate, use spline
    if any(isnan(Tcountry.Unemployment)) 
        validIdx = ~isnan(Tcountry.Unemployment); 
        if sum(validIdx) >= 3 
            Tcountry.Unemployment = interp1(Tcountry.Year(validIdx), ... 
                                            Tcountry.Unemployment(validIdx), ... 
                                            Tcountry.Year, 'spline', 'extrap'); 
        elseif sum(validIdx) >= 2 
            Tcountry.Unemployment = interp1(Tcountry.Year(validIdx), ... 
                                            Tcountry.Unemployment(validIdx), ... 
                                            Tcountry.Year, 'linear', 'extrap'); 
        else 
            Tcountry.Unemployment = fillmissing(Tcountry.Unemployment, 'constant', nanmean(Tcountry.Unemployment)); 
        end 
    end 
    
    % Homicide Rate: Use spline for smooth trends
    if any(isnan(Tcountry.Homicide)) 
        validIdx = ~isnan(Tcountry.Homicide); 
        if sum(validIdx) >= 3 
            Tcountry.Homicide = interp1(Tcountry.Year(validIdx), ... 
                                        Tcountry.Homicide(validIdx), ... 
                                        Tcountry.Year, 'spline', 'extrap'); 
        elseif sum(validIdx) >= 2 
            Tcountry.Homicide = interp1(Tcountry.Year(validIdx), ... 
                                        Tcountry.Homicide(validIdx), ... 
                                        Tcountry.Year, 'linear', 'extrap'); 
        else 
            Tcountry.Homicide = fillmissing(Tcountry.Homicide, 'constant', nanmean(Tcountry.Homicide)); 
        end 
    end 
    
    % NetMigration: Only fill for training period (<=2014)
    trainMaskAll = Tcountry.Year <= 2014; 
    if any(isnan(Tcountry.NetMigration(trainMaskAll))) 
        validIdx = ~isnan(Tcountry.NetMigration) & trainMaskAll; 
        if sum(validIdx) >= 3 
            trainYears = Tcountry.Year(trainMaskAll); 
            Tcountry.NetMigration(trainMaskAll) = interp1(Tcountry.Year(validIdx), ... 
                                                          Tcountry.NetMigration(validIdx), ... 
                                                          trainYears, 'spline', 'extrap'); 
        else 
            Tcountry.NetMigration(trainMaskAll) = fillmissing(Tcountry.NetMigration(trainMaskAll), 'linear', 'EndValues', 'nearest'); 
        end 
    end 
    
    %% FEATURE ENGINEERING
    
    % GDP Growth (year-over-year percentage change)
    gdpVals = Tcountry.GDP; 
    prevGDP = gdpVals(1:end-1); 
    growthSeries = [0; diff(gdpVals) ./ prevGDP]; 
    growthSeries(~isfinite(growthSeries)) = 0;  % Replace Inf/NaN with 0
    Tcountry.GDPgrowth = growthSeries; 
    
    % GDP Acceleration (second derivative - detects economic shocks)
    accelSeries = [0; 0; diff(Tcountry.GDPgrowth(2:end))]; 
    accelSeries(~isfinite(accelSeries)) = 0; 
    Tcountry.GDPaccel = accelSeries; 
    
    % Unemployment Change (rising unemployment drives emigration)
    unempChange = [0; diff(Tcountry.Unemployment)]; 
    unempChange(~isfinite(unempChange)) = 0; 
    Tcountry.UnempChange = unempChange; 
    
    % Homicide Rate Change (safety deterioration triggers migration)
    homicideChange = [0; diff(Tcountry.Homicide)];
    homicideChange(~isfinite(homicideChange)) = 0;
    Tcountry.HomicideChange = homicideChange;
    
    % Migration Momentum (IMPORTANT: LEAKAGE FIXED)
    % Lag 1: Migration the previous year
    Tcountry.MigrationLag1 = [NaN; Tcountry.NetMigration(1:end-1)]; 
    % Lag 2: Migration 2 years ago
    Tcountry.MigrationLag2 = [NaN; NaN; Tcountry.NetMigration(1:end-2)]; 
    
    % MigrationVelocity (Rate of Change)
    % OLD (Leaky): [0; diff(NetMigration)] -> Uses current year
    % NEW (Safe): Lag1 - Lag2 -> Uses only past years
    Tcountry.MigrationVelocity = Tcountry.MigrationLag1 - Tcountry.MigrationLag2;
    Tcountry.MigrationVelocity(isnan(Tcountry.MigrationVelocity)) = 0;

    % Logarithmic transformations compress large values and model diminishing returns
    Tcountry.LogGDP = log(Tcountry.GDP + 1); 
    Tcountry.LogSchool = log(Tcountry.SchoolYears + 1); 
    Tcountry.LogHomicide = log(Tcountry.Homicide + 1); 
    
    % Economic Opportunity Index (GDP per education year)
    Tcountry.OpportunityIndex = Tcountry.GDP ./ (Tcountry.SchoolYears + 1); 
    
    % Economic Stress (unemployment × GDP volatility)
    Tcountry.EconomicStress = Tcountry.Unemployment .* abs(Tcountry.GDPgrowth); 
    
    % Safety Index 
    Tcountry.SafetyIndex = Tcountry.Homicide .* Tcountry.Unemployment;
    
    % Time trend (normalized 0 to 1)
    Tcountry.TimeTrend = (Tcountry.Year - min(Tcountry.Year)) / (max(Tcountry.Year) - min(Tcountry.Year)); 
    
    % Clean up any remaining non-finite values in engineered features
    engineeredVars = {'GDPgrowth','GDPaccel','UnempChange','HomicideChange',...
                      'MigrationVelocity','OpportunityIndex','EconomicStress',...
                      'SafetyIndex','TimeTrend','LogGDP','LogSchool','LogHomicide'}; 
    for v = 1:numel(engineeredVars) 
        colName = engineeredVars{v}; 
        colData = Tcountry.(colName); 
        colData(~isfinite(colData)) = 0; 
        Tcountry.(colName) = colData; 
    end 
    
    %% SPLIT INTO TRAINING AND PREDICTION SETS
    
    % Training: 1990-2014 with valid NetMigration
    Ttrain = Tcountry(Tcountry.Year <= 2014 & ~isnan(Tcountry.NetMigration), :); 
    
    % Prediction: 2015-2019 (NetMigration unknown, to be predicted)
    Tpred = Tcountry(Tcountry.Year > 2014, :); 
    
    if isempty(Ttrain) || height(Ttrain) < 5 
        fprintf('  Warning: Insufficient training data for %s. Skipping.\n\n', currentCountry); 
        continue; 
    end 
    
    if isempty(Tpred) 
        fprintf('  Warning: No prediction period data for %s. Skipping.\n\n', currentCountry); 
        continue; 
    end 
    
  
    
    % Full list of potential predictors
    predVars = {'GDPgrowth', 'GDPaccel', 'LogGDP', 'LogSchool', ...
                'Unemployment', 'UnempChange', 'Homicide', 'HomicideChange', ...
                'LogHomicide', 'OpportunityIndex', 'EconomicStress', ...
                'SafetyIndex', 'MigrationLag1', 'MigrationLag2', ...
                'TimeTrend'}; 
    
    % Remove training rows with missing predictor values
    validTrainMask = all(isfinite(Ttrain{:, predVars}), 2); 
    Ttrain = Ttrain(validTrainMask, :); 
    
    if height(Ttrain) < 5 
        fprintf('  Warning: Training predictors for %s contain too many gaps. Skipping.\n\n', currentCountry); 
        continue; 
    end 
    
    % Extract training features and target
    X_train_raw = Ttrain{:, predVars}; 
    y_train = Ttrain.NetMigration; 
    
    % Extract prediction features
    X_pred_raw = Tpred{:, predVars}; 
    
    % IMPORTANT: Initialize lag variables to zero for prediction period
    X_pred_raw(:, strcmp(predVars, 'MigrationLag1')) = 0; 
    X_pred_raw(:, strcmp(predVars, 'MigrationLag2')) = 0; 
    
    %% NORMALIZATION & RANK FIX (CORRELATION FILTER)
    
    [X_train_norm, mu, sigma] = zscore(X_train_raw); 
    
    % --- STEP 1: DROP CONSTANT FEATURES ---
    keepMask = sigma > 1e-12;
    if sum(keepMask) < length(predVars)
        droppedVars = predVars(~keepMask);
        fprintf('  Note: Dropping constant features for %s: %s\n', ...
                currentCountry, strjoin(droppedVars, ', '));
    end
    
    % Apply Mask 1
    localPredVars = predVars(keepMask);
    X_train_norm  = X_train_norm(:, keepMask);
    mu            = mu(keepMask);
    sigma         = sigma(keepMask);
    
    % --- STEP 2: DROP HIGHLY CORRELATED FEATURES --- 
    % Calculate correlation matrix of remaining variables # this filter has been written by an LLM
    if size(X_train_norm, 2) > 1
        R = corr(X_train_norm);
        % Find indices where correlation is near 1 or -1 (excluding diagonal)
        % We use 0.99 as threshold. If >0.99, variables are virtually identical.
        [row, col] = find(triu(abs(R), 1) > 0.99);
        
        if ~isempty(row)
            varsToRemove = {};
            % Identify which ones to drop (dropping the one with higher index)
            dropIndices = unique(col);
            
            % Create a mask for features to KEEP
            keepMask2 = true(1, length(localPredVars));
            keepMask2(dropIndices) = false;
            
            droppedCorrelated = localPredVars(dropIndices);
            fprintf('  Note: Dropping highly correlated features for %s: %s\n', ...
                    currentCountry, strjoin(droppedCorrelated, ', '));
            
            % Apply Mask 2
            localPredVars = localPredVars(keepMask2);
            X_train_norm  = X_train_norm(:, keepMask2);
            mu            = mu(keepMask2);
            sigma         = sigma(keepMask2);
        end
    end
    
    % Apply final filters to prediction data
    [~, keptIndicesInOriginal] = ismember(localPredVars, predVars);
    X_pred_raw_subset = X_pred_raw(:, keptIndicesInOriginal);
    X_pred_norm = (X_pred_raw_subset - mu) ./ sigma;
    X_pred_norm(~isfinite(X_pred_norm)) = 0; 
    
    if isempty(Tpred) 
        fprintf('  Warning: No prediction rows available for %s after 2014.\n\n', currentCountry); 
        continue; 
    end 
    
    
    TrainTable = array2table(X_train_norm, 'VariableNames', localPredVars); 
    TrainTable.NetMigration = y_train; 
    
    PredTable = array2table(X_pred_norm, 'VariableNames', localPredVars); 
    
    %% DYNAMIC FORMULA GENERATION (INTERACTIONS)
    % We must construct the formula string based ONLY on the surviving variables.
    
    formulaTerms = localPredVars;
    
    % Potential interactions
    interactionsToCheck = {
        {'GDPgrowth', 'Unemployment'}, ...
        {'MigrationLag1', 'GDPgrowth'}, ...
        {'LogGDP', 'LogSchool'}, ...
        {'Homicide', 'Unemployment'}
    };
    
    for k = 1:length(interactionsToCheck)
        var1 = interactionsToCheck{k}{1};
        var2 = interactionsToCheck{k}{2};
        
        % Check 1: Do both variables exist in our filtered set?
        if ismember(var1, localPredVars) && ismember(var2, localPredVars)
            % For stepwise, we add interactions to the "Upper" model bound
            formulaTerms{end+1} = sprintf('%s:%s', var1, var2);
        end
    end
    
   
    formulaStr = ['NetMigration ~ ' strjoin(formulaTerms, ' + ')];

    %% FIT LINEAR MODEL (STEPWISE)
   
    warning('off', 'stats:LinearModel:RankDefDesignMat');
    
    
 
    % (linear + selected interactions)
    
    mdl = stepwiselm(TrainTable, 'constant', ...
                     'Upper', formulaStr, ...
                     'Criterion', 'BIC', ...
                     'Verbose', 0);
                     
    warning('on', 'stats:LinearModel:RankDefDesignMat');
    
    %%  ITERATIVE PREDICTION (Auto-Regressive Approach) 
    
    predicted_migration = zeros(height(Tpred), 1); 
    
    for pred_idx = 1:height(Tpred) 
        
        if pred_idx == 1 
            % First prediction (2015): use actual 2014 data
            current_lag1 = Ttrain.NetMigration(end); 
            current_lag2 = Ttrain.NetMigration(end-1); 
        elseif pred_idx == 2 
            % Second prediction (2016): use 2015 prediction + 2014 actual
            current_lag1 = predicted_migration(1); 
            current_lag2 = Ttrain.NetMigration(end); 
        else 
            % Following years: use previous predictions
            current_lag1 = predicted_migration(pred_idx - 1); 
            current_lag2 = predicted_migration(pred_idx - 2); 
        end 
        
        PredRow = PredTable(pred_idx, :); 
        
        % Normalize lag values using training statistics
        % Check if Lag vars were kept before trying to update them
        if ismember('MigrationLag1', localPredVars)
            idx = strcmp(localPredVars, 'MigrationLag1');
            PredRow.MigrationLag1 = (current_lag1 - mu(idx)) / sigma(idx);
        end
        
        if ismember('MigrationLag2', localPredVars)
            idx = strcmp(localPredVars, 'MigrationLag2');
            PredRow.MigrationLag2 = (current_lag2 - mu(idx)) / sigma(idx);
        end
        
      
        predicted_migration(pred_idx) = predict(mdl, PredRow); 
    end 
    
    %% STORE RESULTS 
    
    predResults = table(); 
    predResults.Country = repmat({char(currentCountry)}, height(Tpred), 1); 
    predResults.Year = Tpred.Year; 
    predResults.PredictedNetMigration = predicted_migration; 
    
    allPredictions = [allPredictions; predResults]; 
    
    % Store model quality metrics
    metricRow = table(); 
    metricRow.Country = {char(currentCountry)}; 
    metricRow.RSquared = mdl.Rsquared.Ordinary; 
    metricRow.AdjRSquared = mdl.Rsquared.Adjusted; 
    metricRow.RMSE_Train = mdl.RMSE; 
    metricRow.NumObservations = height(Ttrain); 
    
    allMetrics = [allMetrics; metricRow]; 
    
    fprintf('  R² = %.4f | Adj R² = %.4f | RMSE = %.0f | N = %d\n\n', ...
            metricRow.RSquared, metricRow.AdjRSquared, metricRow.RMSE_Train, metricRow.NumObservations); 
end 


%% SAVE RESULTS TO CSV

allPredictions.PredictedNetMigration = round(allPredictions.PredictedNetMigration);

writetable(allPredictions,  fullfile(resultsDir, 'predicted_migration_all_countries.csv'));
writetable(allMetrics,      fullfile(resultsDir, 'model_quality_metrics.csv'));

fprintf('\n=== Results Saved Successfully ===\n');
fprintf('Output directory: %s\n\n', resultsDir);
fprintf('Generated files:\n');
fprintf('  1. predicted_migration_all_countries.csv (Country-level predictions)\n');
fprintf('  2. model_quality_metrics.csv (Model R² and fit statistics)\n\n');

%%  SUMMARY STATISTICS 

fprintf('=== Model Summary ===\n'); 
fprintf('Total countries processed: %d\n', height(allMetrics)); 
fprintf('Average R²: %.4f\n', mean([allMetrics.RSquared])); 
fprintf('Average Adjusted R²: %.4f\n', mean([allMetrics.AdjRSquared])); 
fprintf('Average Training RMSE: %.0f\n\n', mean([allMetrics.RMSE_Train])); 


fprintf('All predictions generated successfully!\n');