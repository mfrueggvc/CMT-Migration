clc; clear; close all;


% Ask the user for the country
selectedCountry = input('Insert South America : ', 's');
selectedCountry = upper(strtrim(string(selectedCountry)));

if selectedCountry == ""
    error('Error: A country name is required.');
end

fprintf('Processing data for: %s...\n', selectedCountry);



%   GDP
Tg = readtable('GDP_SouthAmerica_1990_2019.csv');
% Stack columns (years) into rows
varCountries = Tg.Properties.VariableNames(2:end); 
Tg = stack(Tg, varCountries, 'NewDataVariableName', 'GDP', 'IndexVariableName', 'Country');
Tg.Country = upper(strtrim(string(Tg.Country)));

%  Schooling old deata extraction system
%Ts = readtable('Years_of_schooling.csv');
%Map = readtable('CODEtoNAMECountry.csv');
%Map.Properties.VariableNames = {'geoUnit','Country'};
%Ts = innerjoin(Ts, Map, 'Keys','geoUnit'); % Join to get country names
%Ts.Properties.VariableNames{'year'} = 'Year';
%Ts.Properties.VariableNames{'value'} = 'SchoolYears';
%Ts.Country = upper(strtrim(string(Ts.Country)));
Ts=readtable("Schooling_SouthAmerica_1990_2019 (1).csv")
% Cleanup unnecessary columns
% Stack columns (years) into rows
varCountries = Ts.Properties.VariableNames(2:end); 
Ts = stack(Ts, varCountries, 'NewDataVariableName', 'SchoolYears', 'IndexVariableName', 'Country');
Ts.Country = upper(strtrim(string(Ts.Country)));
Ts = Ts(:, {'Country','Year','SchoolYears'}); 

% -- Load Net Migration
Tn = readtable('NetMigration_SouthAmerica_1990_2019.csv');
varCountriesN = Tn.Properties.VariableNames(2:end);
Tn = stack(Tn, varCountriesN, 'NewDataVariableName', 'NetMigration', 'IndexVariableName', 'Country');
Tn.Country = upper(strtrim(string(Tn.Country)));
%%%%%%% insert new parameter
% --- MERGE DATASETS
% Join all tables by Country and Year
T = innerjoin(Tg, Ts, 'Keys', {'Country','Year'});
T = innerjoin(T, Tn, 'Keys', {'Country','Year'});

% Filter for the selected country immediately to simplify processing
T = T(strcmpi(T.Country, selectedCountry), :);

if isempty(T)
    error('No data found for country %s. Check spelling.', selectedCountry);
end

% Ensure chronological order
T = sortrows(T, 'Year');

% Calculate GDP Growth (Year-over-Year %)
% Formula: (GDP_current - GDP_prev) / GDP_prev
gdpVals = T.GDP;
T.GDPgrowth = [0; diff(gdpVals) ./ gdpVals(1:end-1)];


T.GDP = fillmissing(T.GDP, 'linear');
T.SchoolYears = fillmissing(T.SchoolYears, 'linear');
T.NetMigration = fillmissing(T.NetMigration, 'linear');

%%%--TRAIN vs PREDICT

% SPLIT CRITERIA: Train <= 2014, Predict > 2014
Ttrain = T(T.Year <= 2014, :);
Tpred  = T(T.Year > 2014, :);

if isempty(Ttrain)
    error('No training data available before 2005.');
end
if isempty(Tpred)
    error('No data available after 2005 for prediction inputs.');
end


% We use Year, GDP, Schooling, and Growth as inputs
predVars = {'Year', 'GDP', 'SchoolYears', 'GDPgrowth'};
X_train_raw = Ttrain(:, predVars).Variables;
y_train     = Ttrain.NetMigration;

X_pred_raw  = Tpred(:, predVars).Variables;


% Crucial: We calculate Mean and Sigma ONLY on training data (<=2005)
% and apply those same values to the future data. This prevents "data leakage".

[X_train_norm, mu, sigma] = zscore(X_train_raw);

% Apply the training scaling to the prediction set
X_pred_norm = (X_pred_raw - mu) ./ sigma;


% We use Linear Regression instead of Gaussian Process.

% Linear Regression captures the TREND (slope) and projects it forward.

fprintf('Training model on data from 1990 to 2014...\n');


TrainTable = array2table(X_train_norm, 'VariableNames', predVars);
TrainTable.NetMigration = y_train;

% Fit Linear Model

mdl = fitlm(TrainTable, 'NetMigration ~ Year + GDP + SchoolYears + GDPgrowth');

% Display Model Accuracy (R-Squared) in Command Window
disp(mdl);
fprintf('R-Squared (Model Fit): %.4f\n', mdl.Rsquared.Ordinary);


% Create table for prediction inputs
PredTable = array2table(X_pred_norm, 'VariableNames', predVars);

% Predict future migration
predicted_migration = predict(mdl, PredTable);

% Store results
Tpred.PredictedNetMigration = predicted_migration;




OUT = Tpred(:, {'Country', 'Year', 'PredictedNetMigration'});

% Create a safe filename
safeCountry = regexprep(lower(selectedCountry), '[^a-z0-9]+', '_');
outfile = sprintf('predicted_netmigration_%s.csv', safeCountry);

% Save to CSV
writetable(OUT, outfile);
fprintf('Success! Predictions saved to: %s\n', outfile);

%  SIMPLE PLOt
figure;
hold on;
plot(Ttrain.Year, Ttrain.NetMigration, '-bo', 'LineWidth', 1.5, 'DisplayName', 'Actual (Train <= 2014)');
plot(Tpred.Year, Tpred.PredictedNetMigration, '-r*', 'LineWidth', 1.5, 'DisplayName', 'Predicted (> 2014)');
xlabel('Year');
ylabel('Net Migration');
title(['Migration Prediction for ' char(selectedCountry)]);
legend('Location', 'best');
grid on;



pppp