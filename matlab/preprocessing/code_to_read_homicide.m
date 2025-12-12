%% ===============================================
%  1. PARAMÈTRES DE BASE
% ===============================================
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
    'Venezuela'};   % <<< changé ici : plus "Venezuela, RB"

years = 1990:2019;
yearVars = "x" + string(years);   % e.g. "x1990", "x1991", ...


%% ===============================================
%  2. LECTURE BRUTE DU CSV HOMICIDES
% ===============================================
Hraw = readtable('homicide.csv', 'PreserveVariableNames', true);

headerH = string(table2cell(Hraw(1, :)));
Hraw.Properties.VariableNames = matlab.lang.makeValidName(headerH);

H = Hraw(2:end, :);


%% ===============================================
%  3. LECTURE BRUTE DU CSV POPULATION (pour ordre)
% ===============================================
Praw = readtable('Population.csv', 'PreserveVariableNames', true);
headerP = string(table2cell(Praw(1, :)));
Praw.Properties.VariableNames = matlab.lang.makeValidName(headerP);
POP = Praw(2:end, :);


%% ===============================================
%  4. FILTRER LES 12 PAYS
% ===============================================
% Ici on garde "Venezuela, RB" dans les fichiers World Bank
H_sa = H(ismember(H.CountryName, {'Argentina','Bolivia','Brazil','Chile','Colombia','Ecuador',...
                                  'Guyana','Paraguay','Peru','Suriname','Uruguay','Venezuela, RB'}), :);

POP_sa = POP(ismember(POP.CountryName, {'Argentina','Bolivia','Brazil','Chile','Colombia','Ecuador',...
                                        'Guyana','Paraguay','Peru','Suriname','Uruguay','Venezuela, RB'}), :);


%% ===============================================
%  5. RÉORDONNER SELON LA LISTE OFFICIELLE
% ===============================================
% Adapter l'ordre WorldBank → ton ordre (Venezuela, RB → Venezuela)
worldbank_names = {'Argentina','Bolivia','Brazil','Chile','Colombia','Ecuador',...
                   'Guyana','Paraguay','Peru','Suriname','Uruguay','Venezuela, RB'};

[~, idxH] = ismember(worldbank_names, H_sa.CountryName);
H_sa = H_sa(idxH, :);

[~, idxP] = ismember(worldbank_names, POP_sa.CountryName);
POP_sa = POP_sa(idxP, :);


%% ===============================================
%  6. EXTRAIRE LA MATRICE 1990–2019
% ===============================================
Homicide_matrix = H_sa{:, yearVars};   % taille = 12 × 30


%% ===============================================
%  7. REMPLACER NaN PAR 0
% ===============================================
Homicide_matrix(isnan(Homicide_matrix)) = 0;


%% ===============================================
%  8. CONSTRUIRE LE TABLEAU FINAL (ANNÉES EN LIGNES)
% ===============================================
HomicideTable = array2table(years', 'VariableNames', {'Year'});

for i = 1:length(countries)
    country = countries{i};

    % Correction spéciale : correspondance Venezuela <-> Venezuela, RB
    if strcmp(country, 'Venezuela')
        true_name = 'Venezuela__RB';  % compatible avec makeValidName
    else
        true_name = matlab.lang.makeValidName(country);
    end

    HomicideTable.(true_name) = Homicide_matrix(i, :)';
end

% Final renaming for clarity
HomicideTable.Properties.VariableNames = strrep(...
    HomicideTable.Properties.VariableNames, 'Venezuela__RB', 'Venezuela');

% Sauvegarde CSV
writetable(HomicideTable, 'homicide_per_100k.csv');

disp('✔ Fichier homicide_per_100k.csv créé avec succès !');
disp(size(HomicideTable));
