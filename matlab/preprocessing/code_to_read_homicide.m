%% ===============================================
%  PROCESS WORLD BANK HOMICIDE RATE (1990–2019)
%  Output format: Year × Country
%  Indicator already per 100,000 inhabitants
% ===============================================

clear; clc;

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
    'Venezuela'};

worldbank_names = { ...
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
    'Venezuela, RB'};

years = 1990:2019;
yearVars = "x" + string(years);   % "x1990" ... "x2019"


%% ===============================================
%  2. LECTURE BRUTE DU CSV WORLD BANK
% ===============================================
Hraw = readtable('Homicide_Worldbank_Unchanged.csv', ...
                 'PreserveVariableNames', true);

% La première ligne contient les vrais noms de colonnes
headerH = string(table2cell(Hraw(1, :)));
Hraw.Properties.VariableNames = matlab.lang.makeValidName(headerH);

% Supprimer la ligne d'en-tête
H = Hraw(2:end, :);


%% ===============================================
%  3. FILTRER LES 12 PAYS
% ===============================================
H_sa = H(ismember(H.CountryName, worldbank_names), :);


%% ===============================================
%  4. RÉORDONNER SELON L'ORDRE OFFICIEL
% ===============================================
[~, idxH] = ismember(worldbank_names, H_sa.CountryName);
H_sa = H_sa(idxH, :);


%% ===============================================
%  5. EXTRAIRE LES ANNÉES 1990–2019
% ===============================================
Homicide_matrix = H_sa{:, yearVars};   % taille = 12 × 30


%% ===============================================
%  6. GESTION DES VALEURS MANQUANTES
% ===============================================
% Hypothèse choisie : absence de donnée → 0 homicide reporté
Homicide_matrix(isnan(Homicide_matrix)) = 0;


%% ===============================================
%  7. CONSTRUIRE LE TABLEAU FINAL (ANNÉES EN LIGNES)
% ===============================================
HomicideTable = array2table(years', 'VariableNames', {'Year'});

for i = 1:length(countries)
    country = countries{i};
    HomicideTable.(country) = Homicide_matrix(i, :)';
end


%% ===============================================
%  8. SAUVEGARDE
% ===============================================
writetable(HomicideTable, 'Homicide_SouthAmerica_1990_2019.csv');

disp('✔ Homicide dataset créé avec succès !');
disp(HomicideTable(1:10, :));
