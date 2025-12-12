function preprocess_Schooling(rawDir, processedDir)
% Build mean years of schooling dataset for South America (1990–2019) and save CSV.

%% 1. Load the CSV (semicolon separator)
inputFile = fullfile(rawDir, 'Years_Of_Schooling_UNDP_Unchanged.csv');
raw = readtable(inputFile, ...
    'Delimiter', ';', ...
    'ReadVariableNames', true);

%% 2. South American countries (ISO codes + names)
iso_codes = ["ARG","BOL","BRA","CHL","COL","ECU","GUY","PRY","PER","SUR","URY","VEN"];
country_names = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

%% 3. Year range
years = (1990:2019)';
clean = table(years, 'VariableNames', {'Year'});

%% 4. Build country columns
for i = 1:length(iso_codes)
    iso   = iso_codes(i);
    cname = country_names(i);

    subset = raw(strcmp(raw.countryIsoCode, iso), :);

    col = NaN(length(years),1);

    for j = 1:height(subset)
        yr = subset.year(j);
        if yr >= 1990 && yr <= 2019
            idx = yr - 1990 + 1;
            col(idx) = subset.value(j);
        end
    end

    clean.(cname) = col;
end

%% 5. Save CSV only
outCsv = fullfile(processedDir, 'Schooling_SouthAmerica_1990_2019.csv');
writetable(clean, outCsv);

disp('>>> Schooling_SouthAmerica_1990_2019.csv created successfully <<<');
disp(size(clean));

end
