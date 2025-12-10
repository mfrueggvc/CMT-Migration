clc; clear; close all; 
fprintf('=== Migration Prediction Model for South America ===\n'); 
fprintf('Training period: 1990-2014\n'); 
fprintf('Prediction period: 2015-2019\n\n'); 

%% DATA LOADING 
% Load GDP 
Tg = readtable('GDP_SouthAmerica_1990_2019.csv'); 
varCountries = Tg.Properties.VariableNames(2:end); 
Tg = stack(Tg, varCountries, 'NewDataVariableName', 'GDP', 'IndexVariableName', 'Country'); 
Tg.Country = upper(strtrim(string(Tg.Country))); 

% Load Schooling 
Ts = readtable("Schooling_SouthAmerica_1990_2019 (1).csv"); 
varCountries = Ts.Properties.VariableNames(2:end); 
Ts = stack(Ts, varCountries, 'NewDataVariableName', 'SchoolYears', 'IndexVariableName', 'Country'); 
Ts.Country = upper(strtrim(string(Ts.Country))); 
Ts = Ts(:, {'Country','Year','SchoolYears'}); 

% Load Unemployment 
Tu = readtable('Unemployment_SouthAmerica_1990_2019.csv'); 
varCountries = Tu.Properties.VariableNames(2:end); 
Tu = stack(Tu, varCountries, 'NewDataVariableName', 'Unemployment', 'IndexVariableName', 'Country'); 
Tu.Country = upper(strtrim(string(Tu.Country))); 
Tu = Tu(:, {'Country','Year','Unemployment'}); 

% Load Net Migration (only used for training up to 2014) 
Tn = readtable('NetMigration_SouthAmerica_1990_2019.csv'); 
varCountriesN = Tn.Properties.VariableNames(2:end); 
Tn = stack(Tn, varCountriesN, 'NewDataVariableName', 'NetMigration', 'IndexVariableName', 'Country'); 
Tn.Country = upper(strtrim(string(Tn.Country))); 

% Load Homicide Rate (per 100k population)
Th = readtable('homicide_per_100k (3).csv'); 
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
    
    % Migration Momentum (IMPORTANT: uses lagged values)
    % Note: These will be dynamically updated during prediction
    Tcountry.MigrationLag1 = [NaN; Tcountry.NetMigration(1:end-1)]; 
    Tcountry.MigrationLag2 = [NaN; NaN; Tcountry.NetMigration(1:end-2)]; 
    Tcountry.MigrationVelocity = [0; diff(Tcountry.NetMigration)]; 
    % Logarithmic transformations compress large values and model diminishing
    % returns: a change from 1 to 2 is treated as more important than a change
    % from 100 to 101. This also reduces the influence of extreme outliers.
    Tcountry.LogGDP = log(Tcountry.GDP + 1); 
    Tcountry.LogSchool = log(Tcountry.SchoolYears + 1); 
    Tcountry.LogHomicide = log(Tcountry.Homicide + 1); % Log of violence level
    
    % Economic Opportunity Index (GDP per education year)
    Tcountry.OpportunityIndex = Tcountry.GDP ./ (Tcountry.SchoolYears + 1); 
    
    % Economic Stress (unemployment × GDP volatility)
    Tcountry.EconomicStress = Tcountry.Unemployment .* abs(Tcountry.GDPgrowth); 
    
    % Safety Index (interaction: high crime + unemployment = emigration). SafetyIndex is an engineered feature that multiplies homicide rate by
    % unemployment. It approximates situations where insecurity and lack of
    % jobs reinforce each other as a push factor for migration
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
    
    %% MODEL SPECIFICATION
    
    % Predictor variables (features used in the model)
    predVars = {'GDPgrowth', 'GDPaccel', 'LogGDP', 'LogSchool', ...
                'Unemployment', 'UnempChange', 'Homicide', 'HomicideChange', ...
                'LogHomicide', 'OpportunityIndex', 'EconomicStress', ...
                'SafetyIndex', 'MigrationLag1', 'MigrationLag2', ...
                'MigrationVelocity', 'TimeTrend'}; 
    
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
    % These will be replaced iteratively with actual predictions
    X_pred_raw(:, strcmp(predVars, 'MigrationLag1')) = 0; 
    X_pred_raw(:, strcmp(predVars, 'MigrationLag2')) = 0; 
    X_pred_raw(:, strcmp(predVars, 'MigrationVelocity')) = 0; 
    
    %% NORMALIZATION (Z-score standardization)
    % Mean and standard deviation are computed only on the TRAINING set.
    % This prevents data leakage: information from future years (2015–2019)
    % is not used when scaling the inputs that are used to fit the model.
    [X_train_norm, mu, sigma] = zscore(X_train_raw); 
    
    % Handle edge cases in normalization parameters
    sigma(~isfinite(sigma)) = 0; 
    mu(~isfinite(mu)) = 0; 
    zeroVarCols = sigma == 0;  % Columns with no variation
    sigma(zeroVarCols) = 1;    % Prevent division by zero
    X_train_norm(:, zeroVarCols) = 0; 
    % If a predictor has no variation in the training set, its standard deviation
    % becomes zero. We set sigma=1 for those columns so that (x - mu)./sigma
    % does not divide by zero, and we set the normalized values to zero because
    % a constant feature carries no additional information after centering.
    % Same normalization to prediction data
    X_pred_norm = (X_pred_raw - mu) ./ sigma; 
    X_pred_norm(~isfinite(X_pred_norm)) = 0; 
    
    if isempty(Tpred) 
        fprintf('  Warning: No prediction rows available for %s after 2014.\n\n', currentCountry); 
        continue; 
    end 
    
    % Check if prediction features have variation (avoids flat predictions)
    if size(unique(X_pred_norm, 'rows'), 1) == 1 
        warning('Predictor values after 2014 have zero variation; predictions may be flat for %s.', currentCountry); 
    end 
    
    % Create tables for model fitting
    TrainTable = array2table(X_train_norm, 'VariableNames', predVars); 
    TrainTable.NetMigration = y_train; 
    
    PredTable = array2table(X_pred_norm, 'VariableNames', predVars); 
    
    %% FIT LINEAR MODEL WITH INTERACTIONS
    
    % Model formula includes:
    % - Main effects: all predictors
    % - Interactions: capture combined effects
    %     GDPgrowth:Unemployment (economic downturn)
    %     MigrationLag1:GDPgrowth (momentum influenced by economy)
    %     LogGDP:LogSchool (development level)
    %     Homicide:Unemployment (safety + joblessness = strong push factor)
    % The formula includes both main effects and interaction terms.
    % An interaction A:B means that the effect of A depends on the level of B.
    % For example, Homicide:Unemployment captures that high violence combined
    % with high unemployment can produce a stronger migration push than either
    % factor alone. Similar logic holds for GDPgrowth:Unemployment, 
    % MigrationLag1:GDPgrowth, and LogGDP:LogSchool.
    mdl = fitlm(TrainTable, ['NetMigration ~ GDPgrowth + GDPaccel + LogGDP + LogSchool + ' ...
                             'Unemployment + UnempChange + Homicide + HomicideChange + ' ...
                             'LogHomicide + OpportunityIndex + EconomicStress + SafetyIndex + ' ...
                             'MigrationLag1 + MigrationLag2 + MigrationVelocity + TimeTrend + ' ...
                             'GDPgrowth:Unemployment + MigrationLag1:GDPgrowth + ' ...
                             'LogGDP:LogSchool + Homicide:Unemployment']); 
    
    %%  ITERATIVE PREDICTION (Auto-Regressive Approach) 
    
    % Key concept: Each year's prediction depends on the previous year
    % We cannot predict all future years in one shot because the model uses
    % lagged migration variables (MigrationLag1, MigrationLag2, MigrationVelocity).
    % Each year's prediction depends on previous migration values, so we generate
    % forecasts year by year and feed each new prediction back into the lags.
    % This captures migration momentum: if people are leaving, trend continues
    
    predicted_migration = zeros(height(Tpred), 1); 
    
    for pred_idx = 1:height(Tpred) 
        
        if pred_idx == 1 
            % First prediction (2015): use actual 2014 data
            current_lag1 = Ttrain.NetMigration(end); 
            current_lag2 = Ttrain.NetMigration(end-1); 
            current_vel = Ttrain.NetMigration(end) - Ttrain.NetMigration(end-1); 
        elseif pred_idx == 2 
            % Second prediction (2016): use 2015 prediction + 2014 actual
            current_lag1 = predicted_migration(1); 
            current_lag2 = Ttrain.NetMigration(end); 
            current_vel = predicted_migration(1) - Ttrain.NetMigration(end); 
        else 
            % Following years: use previous predictions
            current_lag1 = predicted_migration(pred_idx - 1); 
            current_lag2 = predicted_migration(pred_idx - 2); 
            current_vel = predicted_migration(pred_idx - 1) - predicted_migration(pred_idx - 2); 
        end 
        
      
        PredRow = PredTable(pred_idx, :); 
        
        % Normalize lag values using training statistics
        % Note: strcmp finds the column index matching the variable name, it is used to find the correct column of each lag variable by name,
        % so the code does not depend on fixed column positions.
        PredRow.MigrationLag1 = (current_lag1 - mu(strcmp(predVars, 'MigrationLag1'))) / sigma(strcmp(predVars, 'MigrationLag1')); 
        PredRow.MigrationLag2 = (current_lag2 - mu(strcmp(predVars, 'MigrationLag2'))) / sigma(strcmp(predVars, 'MigrationLag2')); 
        PredRow.MigrationVelocity = (current_vel - mu(strcmp(predVars, 'MigrationVelocity'))) / sigma(strcmp(predVars, 'MigrationVelocity')); 
        
        % Generate prediction for this year
        predicted_migration(pred_idx) = predict(mdl, PredRow); 
    end 
    
    %% STORE RESULTS 
    
    predResults = table(); 
    predResults.Country = repmat({char(currentCountry)}, height(Tpred), 1); 
    predResults.Year = Tpred.Year; 
    predResults.PredictedNetMigration = predicted_migration; 
    %predResults.GDP = Tpred.GDP; 
    %predResults.SchoolYears = Tpred.SchoolYears; 
    %predResults.Unemployment = Tpred.Unemployment; 
    %predResults.Homicide = Tpred.Homicide;
    %predResults.GDPgrowth = Tpred.GDPgrowth; 
    
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

% CONTINENTAL AGGREGATION

fprintf('=== Aggregating South America Results ===\n'); 

years = unique(allPredictions.Year); 
continentalPred = table(); 

for y = 1:length(years) 
    yearData = allPredictions(allPredictions.Year == years(y), :); 
    
    row = table(); 
    row.Year = years(y); 
    row.TotalPredictedMigration = sum(yearData.PredictedNetMigration); 
    %row.TotalGDP = sum(yearData.GDP); 
    %row.AvgUnemployment = mean(yearData.Unemployment); 
    %row.AvgHomicide = mean(yearData.Homicide);
    %row.AvgSchoolYears = mean(yearData.SchoolYears); 
    %row.NumCountries = height(yearData); 
    
    continentalPred = [continentalPred; row]; 
end 

%% SAVE RESULTS TO CSV
allPredictions.PredictedNetMigration = round(allPredictions.PredictedNetMigration);
continentalPred.TotalPredictedMigration = round(continentalPred.TotalPredictedMigration);
currentDir = pwd; 
writetable(allPredictions, 'predicted_migration_all_countries.csv'); 
writetable(continentalPred, 'predicted_migration_south_america.csv'); 
writetable(allMetrics, 'model_quality_metrics.csv'); 

fprintf('\n=== Results Saved Successfully ===\n'); 
fprintf('Output directory: %s\n\n', currentDir); 
fprintf('Generated files:\n'); 
fprintf('  1. predicted_migration_all_countries.csv  (Country-level predictions)\n'); 
fprintf('  2. predicted_migration_south_america.csv  (Continental aggregation)\n'); 
fprintf('  3. model_quality_metrics.csv              (Model R² and fit statistics)\n\n'); 

%% ========== SUMMARY STATISTICS ==========

fprintf('=== Model Summary ===\n'); 
fprintf('Total countries processed: %d\n', height(allMetrics)); 
fprintf('Average R²: %.4f\n', mean([allMetrics.RSquared])); 
fprintf('Average Adjusted R²: %.4f\n', mean([allMetrics.AdjRSquared])); 
fprintf('Average Training RMSE: %.0f\n\n', mean([allMetrics.RMSE_Train])); 

fprintf('=== Continental Predictions (2015-2019) ===\n'); 
disp(continentalPred); 
fprintf('\n'); 

% %% VISUALIZATION
% 
% % Figure 1: Model Quality by Country 
% figure('Position', [100, 100, 1200, 500]); 
% 
% subplot(1,2,1); 
% bar(categorical(allMetrics.Country), [allMetrics.RSquared]); 
% ylabel('R² (Model Fit)', 'FontSize', 12); 
% xlabel('Country', 'FontSize', 12); 
% title('Training Model Quality by Country', 'FontSize', 14, 'FontWeight', 'bold'); 
% ylim([0, 1]); 
% grid on; 
% xtickangle(45); 
% 
% subplot(1,2,2); 
% bar(categorical(allMetrics.Country), [allMetrics.RMSE_Train]); 
% ylabel('RMSE (Training)', 'FontSize', 12); 
% xlabel('Country', 'FontSize', 12); 
% title('Prediction Error by Country', 'FontSize', 14, 'FontWeight', 'bold'); 
% grid on; 
% xtickangle(45); 
% 
% % Figure 2: Continental Trends
% figure('Position', [100, 100, 1000, 800]); 
% 
% subplot(3,1,1); 
% plot(continentalPred.Year, continentalPred.TotalPredictedMigration, '-ro', ...
%      'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r'); 
% xlabel('Year', 'FontSize', 12); 
% ylabel('Total Net Migration', 'FontSize', 12); 
% title('South America - Predicted Total Net Migration (2015-2019)', 'FontSize', 14, 'FontWeight', 'bold'); 
% grid on; 
% 
% subplot(3,1,2); 
% yyaxis left; 
% plot(continentalPred.Year, continentalPred.TotalGDP, '-bs', 'LineWidth', 2, 'MarkerSize', 8); 
% ylabel('Total GDP', 'FontSize', 12); 
% yyaxis right; 
% plot(continentalPred.Year, continentalPred.AvgUnemployment, '-rd', 'LineWidth', 2, 'MarkerSize', 8); 
% ylabel('Avg Unemployment Rate (%)', 'FontSize', 12); 
% xlabel('Year', 'FontSize', 12); 
% title('Economic Indicators - South America', 'FontSize', 14, 'FontWeight', 'bold'); 
% legend('Total GDP', 'Avg Unemployment', 'Location', 'best'); 
% grid on; 
% 
% subplot(3,1,3);
% plot(continentalPred.Year, continentalPred.AvgHomicide, '-md', ...
%      'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'm');
% xlabel('Year', 'FontSize', 12);
% ylabel('Avg Homicide Rate (per 100k)', 'FontSize', 12);
% title('Safety Indicator - South America', 'FontSize', 14, 'FontWeight', 'bold');
% grid on;
% 
% % Figure 3: Individual Country Predictions 
% figure('Position', [100, 100, 1400, 800]); 
% [~, sortIdx] = sort([allMetrics.RSquared], 'descend'); 
% displayCountries = min(9, height(allMetrics)); 
% 
% for i = 1:displayCountries 
%     subplot(3, 3, i); 
%     countryData = allPredictions(strcmpi(allPredictions.Country, allMetrics.Country{sortIdx(i)}), :); 
% 
%     plot(countryData.Year, countryData.PredictedNetMigration, '-ro', ...
%          'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r'); 
% 
%     title(sprintf('%s (R²=%.3f)', char(allMetrics.Country{sortIdx(i)}), ...
%           allMetrics.RSquared(sortIdx(i))), 'FontSize', 11, 'FontWeight', 'bold'); 
%     xlabel('Year', 'FontSize', 10); 
%     ylabel('Predicted Migration', 'FontSize', 10); 
%     grid on; 
% 
%     hold on; 
%     yline(0, '--k', 'LineWidth', 0.5);  % Reference line at zero
% end 

sgtitle('Country-Level Migration Predictions (2015-2019)', 'FontSize', 14, 'FontWeight', 'bold'); 

fprintf('=== Visualization Complete ===\n'); 
fprintf('All predictions generated successfully!\n');
