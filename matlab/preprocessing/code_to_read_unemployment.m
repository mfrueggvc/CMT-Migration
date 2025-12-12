%% ============================================================
% PROCESS UNEMPLOYMENT FOR SOUTH AMERICA (1990–2019)
% Version finale – robuste même si certains pays ont des données manquantes
% ============================================================

clear; clc;

filename = 'unemployment.csv';

%% 1) Lire toutes les lignes du fichier brut
fid = fopen(filename, 'r', 'n', 'UTF-8');
raw_lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fid);
raw_lines = raw_lines{1};

%% 2) En-tête = 5e ligne
header_line = raw_lines{5};
header_cells = strsplit(header_line, ',');
header_cells = strrep(header_cells, '"', '');

% Enlever colonnes vides terminales
while ~isempty(header_cells) && all(header_cells{end}=="")
    header_cells(end) = [];
end

nCols = numel(header_cells);
fprintf("Colonnes dans l'en-tête : %d\n", nCols);

%% 3) Lignes de données
data_lines = raw_lines(6:end);
data_lines = data_lines(~cellfun(@(s) isempty(strtrim(s)), data_lines));
nRows = numel(data_lines);
fprintf("Lignes de données : %d\n", nRows);

%% 4) Construire matrice brute
rows = cell(nRows, nCols);

for i = 1:nRows
    parts = strsplit(data_lines{i}, ',');
    parts = strrep(parts, '"', '');
    
    % Ajuster au nombre de colonnes officiel
    if numel(parts) < nCols
        parts(end+1:nCols) = {''};
    elseif numel(parts) > nCols
        parts = parts(1:nCols);
    end
    
    rows(i,:) = parts;
end

%% 5) Construire la table MATLAB
varNames = matlab.lang.makeValidName(header_cells);
T = cell2table(rows, 'VariableNames', varNames);

fprintf("Table brute : %d lignes, %d colonnes\n", height(T), width(T));

disp("Colonnes:");
disp(T.Properties.VariableNames');

%% 6) Détection colonnes années
allVars = T.Properties.VariableNames;

isYear = ~cellfun(@isempty, regexp(allVars, '^x?(199\d|20[0-1]\d)$', 'once'));
yearCols = allVars(isYear);

% Extraire les années en supprimant 'x' au début
years = str2double(erase(yearCols, "x"));

mask = years>=1990 & years<=2019;
years = years(mask);
yearCols = yearCols(mask);

% Trier
[years, idx] = sort(years);
yearCols = yearCols(idx);

fprintf("Années retenues (%d valeurs) :\n", numel(years));
disp(yearCols');

%% 7) Colonne pays
if ismember('CountryName', T.Properties.VariableNames)
    country_col = 'CountryName';
else
    error("Impossible de trouver la colonne CountryName.");
end

%% 8) Pays d'Amérique du Sud
south_america = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

%% 9) Construire la table finale avec padding automatique
clean = table(years', 'VariableNames', {'Year'});
Ny = length(years);

for i = 1:length(south_america)
    cname = south_america(i);

    idx = strcmp(string(T.(country_col)), cname);

    if ~any(idx)
        fprintf("⚠ Pas de données pour %s → colonne remplie de NaN\n", cname);
        vals = NaN(Ny,1);
    else
        row = T(idx, yearCols);
        raw_vals = table2array(row(1,:));
        vals = str2double(raw_vals(:));  % vecteur colonne
        
        % 🔥 CORRECTION FINALE : padding/ajustement
        if length(vals) < Ny
            vals = [vals; NaN(Ny-length(vals),1)];
        elseif length(vals) > Ny
            vals = vals(1:Ny);
        end
    end

    clean.(cname) = vals;
end

%% 10) Sauvegarde
writetable(clean, 'Unemployment_SouthAmerica_1990_2019.csv');
save('Unemployment_SouthAmerica_1990_2019.mat', 'clean');

disp("✔ Dataset unemployment créé :");
disp('Unemployment_SouthAmerica_1990_2019.csv');
