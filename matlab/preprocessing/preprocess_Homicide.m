function preprocess_Homicide(rawDir, processedDir)
% Build homicide rate table for South America (1990–2019) and save CSV.

countries = { ...
    'Argentina'
    'Bolivia'
    'Brazil'
    'Chile'
    'Colombia'
    'Ecuador'
    'Guyana'
    'Paraguay'
    'Peru'
    'Suriname'
    'Uruguay'
    'Venezuela'};

years    = 1990:2019;
yearVars = "x" + string(years);

%% Read homicide CSV (raw World Bank export)
Hraw = readtable(fullfile(rawDir, 'Homicide_Worldbank_Unchanged (1).csv'), ...
                 'PreserveVariableNames', true);

headerH = string(table2cell(Hraw(1, :)));
Hraw.Properties.VariableNames = matlab.lang.makeValidName(headerH);
H = Hraw(2:end, :);

%% Read population CSV (only used for ordering, but kept for consistency)
Praw = readtable(fullfile(rawDir, 'Population.csv'), ...
                 'PreserveVariableNames', true);
headerP = string(table2cell(Praw(1, :)));
Praw.Properties.VariableNames = matlab.lang.makeValidName(headerP);
POP = Praw(2:end, :);

%% Filter the 12 countries
wb_list = {'Argentina','Bolivia','Brazil','Chile','Colombia','Ecuador', ...
           'Guyana','Paraguay','Peru','Suriname','Uruguay','Venezuela, RB'};

H_sa = H(ismember(H.CountryName, wb_list), :);
POP_sa = POP(ismember(POP.CountryName, wb_list), :);

%% Reorder to match target order
[~, idxH] = ismember(wb_list, H_sa.CountryName);
H_sa = H_sa(idxH, :);

[~, idxP] = ismember(wb_list, POP_sa.CountryName);
POP_sa = POP_sa(idxP, :); %#ok<NASGU>  % kept only to preserve logic

%% Extract homicide matrix 1990–2019
Homicide_matrix = H_sa{:, yearVars};  % 12 x N

%% Replace NaN with 0
Homicide_matrix(isnan(Homicide_matrix)) = 0;

%% Build final table (years in rows, one column per country)
HomicideTable = array2table(years', 'VariableNames', {'Year'});

for i = 1:length(countries)
    country = countries{i};
    if strcmp(country, 'Venezuela')
        true_name = 'Venezuela__RB'; % makeValidName version
    else
        true_name = matlab.lang.makeValidName(country);
    end
    HomicideTable.(true_name) = Homicide_matrix(i, :)';
end

HomicideTable.Properties.VariableNames = strrep( ...
    HomicideTable.Properties.VariableNames, 'Venezuela__RB', 'Venezuela');

outCsv = fullfile(processedDir, 'homicide_per_100k (3).csv');
writetable(HomicideTable, outCsv);

disp('>>> homicide_per_100k (3).csv created successfully <<<');
disp(size(HomicideTable));

end