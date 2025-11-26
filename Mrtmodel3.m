clc; clear; clear all;

% Ask the user which country to process (e.g., BRAZIL, ARGENTINA)
selectedCountry = input('Insert country name (e.g., BRAZIL): ', 's');
selectedCountry = upper(strtrim(string(selectedCountry)));
if selectedCountry == ""
    error('A country name is required to run the estimation.');
end

% Load GDP and reshape to long format
Tg = readtable('GDP_SouthAmerica_1990_2019.csv');
varCountries = Tg.Properties.VariableNames(2:end);
Tg = stack(Tg, varCountries, ...
           'NewDataVariableName', 'GDP', ...
           'IndexVariableName', 'Country');
Tg.Country = upper(strtrim(string(Tg.Country)));

% Load years of schooling and map geoUnit to country names
Ts = readtable('Years_of_schooling.csv');
Map = readtable('CODEtoNAMECountry.csv');
Map.Properties.VariableNames = {'geoUnit','Country'};
Ts = innerjoin(Ts, Map, 'Keys','geoUnit');
Ts.Properties.VariableNames{'year'} = 'Year';
Ts.Properties.VariableNames{'value'} = 'SchoolYears';
Ts.Country = upper(strtrim(string(Ts.Country)));
Ts.geoUnit = [];
Ts.indicatorId = [];
Ts.qualifier = [];
Ts.magnitude = [];

% Load net migration and reshape to long format
Tn = readtable('NetMigration_SouthAmerica_1990_2019.csv');
varCountriesN = Tn.Properties.VariableNames(2:end);
Tn = stack(Tn, varCountriesN, ...
           'NewDataVariableName', 'NetMigration', ...
           'IndexVariableName', 'Country');
Tn.Country = upper(strtrim(string(Tn.Country)));

% Merge datasets
T = innerjoin(innerjoin(Tg, Ts, 'Keys', {'Country','Year'}), ...
              Tn, 'Keys', {'Country','Year'});

% Filter to the selected country
T = T(strcmpi(T.Country, selectedCountry), :);
if isempty(T)
    error('No data found for country %s.', selectedCountry);
end

% Compute GDP growth by country (year-over-year percent change)
T = sortrows(T, {'Country','Year'});
T.GDPgrowth = NaN(height(T),1);
[uniqueCountries, ~, idxCountry] = unique(T.Country);
for i = 1:numel(uniqueCountries)
    mask = idxCountry == i;
    gdpSeries = T.GDP(mask);
    years = T.Year(mask);
    [yearsSorted, order] = sort(years); %#ok<ASGLU>
    gdpSorted = gdpSeries(order);
    growthSeries = [NaN; diff(gdpSorted) ./ gdpSorted(1:end-1)];
    orderedGrowth = NaN(sum(mask),1);
    orderedGrowth(order) = growthSeries;
    T.GDPgrowth(mask) = orderedGrowth;
end

% Replace initial NaN growth values with 0 (no prior year)
T.GDPgrowth = fillmissing(T.GDPgrowth, 'constant', 0);

% Remove rows that lack any predictor data (GDP, SchoolYears, GDPgrowth)
missingPredictors = ismissing(T(:, {'GDP','SchoolYears','GDPgrowth'}));
rowsToKeep = ~any(missingPredictors, 2);
T = T(rowsToKeep, :);
if isempty(T)
    error('All rows for %s are missing required predictors.', selectedCountry);
end

% Train/pred split
Ttrain = T(T.Year <= 2005, :);
Tpred  = T(T.Year > 2005, :);

% Drop training rows without a migration target
Ttrain = Ttrain(~ismissing(Ttrain.NetMigration), :);

% Ensure there is training data
if isempty(Ttrain)
    error('No training data available for %s in 1990-2005.', selectedCountry);
end

% Normalize predictors based on training statistics to avoid leakage
trainPredictorsRaw = [Ttrain.GDP, Ttrain.SchoolYears, Ttrain.GDPgrowth, Ttrain.Year];
predPredictorsRaw  = [Tpred.GDP,  Tpred.SchoolYears,  Tpred.GDPgrowth,  Tpred.Year];

[trainPredictorsZ, mu, sigma] = zscore(trainPredictorsRaw);
sigma(sigma == 0) = 1; % guard against zero variance
predPredictorsZ = (predPredictorsRaw - mu) ./ sigma;

if isempty(Tpred)
    error('No prediction rows available for %s after 2005.', selectedCountry);
end

% Detect degenerate predictor grids that would cause flat predictions
if size(unique(predPredictorsZ, 'rows'), 1) == 1
    warning('Predictor values after 2005 have zero variation; predictions will be flat. Check GDP/schooling inputs for %s.', selectedCountry);
end

trainResponse = Ttrain.NetMigration;

% Fit a Gaussian process regressor with ARD to capture smooth but
% non-linear changes over time and predictors without collapsing to a
% constant surface
mdl = fitrgp(trainPredictorsZ, trainResponse, ...
    'KernelFunction', 'ardsquaredexponential', ...
    'Standardize', false);

% Predict on hold-out set using only predictor inputs
Tpred.PredictedNetMigration = predict(mdl, predPredictorsZ);

% Sort predictions chronologically before exporting
Tpred = sortrows(Tpred, 'Year');

% Export only the predictions for the selected country and years > 2005
OUT = Tpred(:, {'Country','Year','PredictedNetMigration'});
safeCountry = regexprep(lower(selectedCountry), '[^a-z0-9]+', '_');
outfile = sprintf('predicted_netmigration_%s.csv', safeCountry);
writetable(OUT, outfile);