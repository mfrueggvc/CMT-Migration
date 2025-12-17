function preprocess_NetMigration(rawDir, processedDir)
% Build net migration dataset for South America (1990–2019) and save CSV.

filename = fullfile(rawDir, 'Net_Migration_Worldbank_Unchanged.csv');

%% 1. Read file line-by-line (robust)
fid = fopen(filename,'r','n','UTF-8');
if fid == -1
    error('Cannot open file: %s', filename);
end
raw_lines = {};
tline = fgetl(fid);
while ischar(tline)
    raw_lines{end+1} = tline; %#ok<AGROW>
    tline = fgetl(fid);
end
fclose(fid);

%% 2. Remove empty lines
raw_lines = raw_lines(~cellfun(@isempty, raw_lines));

%% 3. Remove BOM if present
if ~isempty(raw_lines)
    raw_lines{1} = regexprep(raw_lines{1}, '^\xEF\xBB\xBF', '');
end

%% 4. Extract header (line 3)
header_line = raw_lines{3};
header_line = strrep(header_line,'"','');
column_names = strsplit(header_line, ',');

%% 5. Extract data lines
data_lines = raw_lines(4:end);

%% 6. Split each data line by commas
split_lines = cellfun(@(x) strsplit(strrep(x,'"',''), ','), ...
                      data_lines, 'UniformOutput', false);

%% 7. Normalize all rows to same number of columns
ncol = length(column_names);
for i = 1:length(split_lines)
    row = split_lines{i};
    if length(row) < ncol
        row(end+1:ncol) = {''};
    elseif length(row) > ncol
        row = row(1:ncol);
    end
    split_lines{i} = row;
end

%% 8. Convert to table
T = cell2table(vertcat(split_lines{:}), ...
    'VariableNames', matlab.lang.makeValidName(column_names));

%% 9. Convert year columns to numeric
for j = 5:width(T)
    T.(j) = str2double(T.(j));
end

%% 10. Filter to South America
south_america = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

T = T(ismember(T.CountryName, south_america), :);

%% 11. Keep only years 1990–2019
all_year_cols = T.Properties.VariableNames(5:end);
year_nums = str2double(extractAfter(all_year_cols,1));

valid       = (year_nums >= 1990 & year_nums <= 2019);
valid_cols  = all_year_cols(valid);
valid_years = year_nums(valid);

%% 12. Build final clean table
clean = array2table(valid_years','VariableNames',{'Year'});

for i = 1:length(south_america)
    country = south_america(i);
    row = T(strcmp(T.CountryName,country), valid_cols);
    clean.(country) = table2array(row)';
end

%% 13. Save CSV only
outCsv = fullfile(processedDir, 'NetMigration_SouthAmerica_1990_2019.csv');
writetable(clean, outCsv);

disp('>>> NetMigration_SouthAmerica_1990_2019.csv created successfully <<<');
disp(size(clean));

end
