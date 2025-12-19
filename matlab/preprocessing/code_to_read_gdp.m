%% ============================================================
% FINAL ROBUST IMPORT FOR WORLD BANK GDP CSV (MALFORMED FORMAT)
% Handles: BOM, blank lines, quotes, misaligned columns
% Extracts South America GDP per capita (1990–2019)
% ============================================================

%% 1. Read file line-by-line (robust)
fid = fopen('GDP_Worldbank_Unchanged (1).csv','r','n','UTF-8');
raw_lines = {};
tline = fgetl(fid);
while ischar(tline)
    raw_lines{end+1} = tline;
    tline = fgetl(fid);
end
fclose(fid);

%% 2. Remove completely empty lines
raw_lines = raw_lines(~cellfun(@isempty, raw_lines));

%% 3. Remove BOM if present
raw_lines{1} = regexprep(raw_lines{1}, '^\xEF\xBB\xBF', '');

%% 4. Extract header (line 3 after removing empties)
header_line = raw_lines{3};
header_line = strrep(header_line,'"',''); % remove quotes
column_names = strsplit(header_line, ',');

%% 5. Extract data lines (starting from line 4)
data_lines = raw_lines(4:end);

%% 6. Convert each data line into a list of columns
split_lines = cellfun(@(x) strsplit(strrep(x,'"',''), ','), ...
                      data_lines, 'UniformOutput', false);

%% 7. Normalize number of columns (fill missing with empty)
ncol = length(column_names);

%%% AI-generated block (robust CSV normalization)
for i = 1:length(split_lines)
    row = split_lines{i};
    if length(row) < ncol
        row(end+1:ncol) = {''};
    elseif length(row) > ncol
        row = row(1:ncol);
    end
    split_lines{i} = row;
end
%%% End AI-generated block

%% 8. Convert to table
T = cell2table(vertcat(split_lines{:}), ...
    'VariableNames', matlab.lang.makeValidName(column_names));

%% 9. Convert numeric year columns
for j = 5:width(T)
    T.(j) = str2double(T.(j));
end

%% 10. Filter to South America
south_america = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

T = T(ismember(T.CountryName, south_america), :);

%% 11. Keep years 1990–2019
all_year_cols = T.Properties.VariableNames(5:end);
year_nums = str2double(extractAfter(all_year_cols,1));

valid = (year_nums >= 1990 & year_nums <= 2019);

valid_cols = all_year_cols(valid);
valid_years = year_nums(valid);

%% 12. Build final clean matrix: Year × Country
clean = array2table(valid_years','VariableNames',{'Year'});

for i = 1:length(south_america)
    country = south_america(i);
    row = T(strcmp(T.CountryName,country), valid_cols);
    clean.(country) = table2array(row)';
end

%% 13. Save outputs
disp(clean(1:10,:))
writetable(clean,'GDP_SouthAmerica_1990_2019.csv');
save('GDP_SouthAmerica_1990_2019.mat','clean');

disp(">>> GDP CLEANED AND PROCESSED SUCCESSFULLY <<<");
