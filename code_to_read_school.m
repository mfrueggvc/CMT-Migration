%% ================================================
% PROCESS MEAN YEARS OF SCHOOLING (1990–2019)
% Builds a clean table: Year x Country
% ================================================

%% 1. Load the CSV (separator = semicolon)
raw = readtable('Years_Of_Schooling_1.csv', ...
    'Delimiter', ';', ...
    'ReadVariableNames', true);

%% 2. South American countries (ISO codes + names)
iso_codes = ["ARG","BOL","BRA","CHL","COL","ECU","GUY","PRY","PER","SUR","URY","VEN"];
country_names = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

%% 3. Create year range
years = (1990:2019)';
clean = table(years, 'VariableNames', {'Year'});

%% 4. Loop through countries
for i = 1:length(iso_codes)
    iso = iso_codes(i);
    cname = country_names(i);

    % Extract rows for that country
    subset = raw(strcmp(raw.countryIsoCode, iso), :);

    % Create column of NaN for the 30 years
    col = NaN(length(years),1);

    % Fill available values
    for j = 1:height(subset)
        yr = subset.year(j);

        if yr >= 1990 && yr <= 2019
            idx = yr - 1990 + 1;  % Convert year → row index
            col(idx) = subset.value(j);
        end
    end

    % Add column to table
    clean.(cname) = col;
end

%% 5. Display first rows
disp(clean(1:10, :));

%% 6. Save
writetable(clean, 'Schooling_SouthAmerica_1990_2019.csv');
save('Schooling_SouthAmerica_1990_2019.mat', 'clean');

disp("Schooling dataset processed and saved successfully!");
