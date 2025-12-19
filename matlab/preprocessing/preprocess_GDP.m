function preprocess_GDP(rawDir, processedDir)
% PREPROCESS_GDP



inputFile = fullfile(rawDir, 'GDP_Worldbank_Unchanged.csv');
fid = fopen(inputFile,'r','n','UTF-8');
if fid == -1
    error('Impossibile aprire il file: %s', inputFile);
end

raw_lines = {};
tline = fgetl(fid);
while ischar(tline)
    raw_lines{end+1} = tline; %#ok<AGROW>
    tline = fgetl(fid);
end
fclose(fid);

raw_lines = raw_lines(~cellfun(@isempty, raw_lines));


if ~isempty(raw_lines)
    raw_lines{1} = regexprep(raw_lines{1}, '^\xEF\xBB\xBF', '');
end


header_line = raw_lines{3};
header_line = strrep(header_line,'"',''); % remove quotes
column_names = strsplit(header_line, ',');

data_lines = raw_lines(4:end);

split_lines = cellfun(@(x) strsplit(strrep(x,'"',''), ','), ...
                      data_lines, 'UniformOutput', false);


ncol = length(column_names);

% AI-generated block (robust CSV normalization)
for i = 1:length(split_lines)
    row = split_lines{i};
    if length(row) < ncol
        row(end+1:ncol) = {''};
    elseif length(row) > ncol
        row = row(1:ncol);
    end
    split_lines{i} = row;
end
% End AI-generated block


T = cell2table(vertcat(split_lines{:}), ...
    'VariableNames', matlab.lang.makeValidName(column_names));


for j = 5:width(T)
    T.(j) = str2double(T.(j));
end


south_america = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

T = T(ismember(T.CountryName, south_america), :);


all_year_cols = T.Properties.VariableNames(5:end);
year_nums = str2double(extractAfter(all_year_cols,1));

valid = (year_nums >= 1990 & year_nums <= 2019);

valid_cols = all_year_cols(valid);
valid_years = year_nums(valid);

clean = array2table(valid_years','VariableNames',{'Year'});

for i = 1:length(south_america)
    country = south_america(i);
    row = T(strcmp(T.CountryName,country), valid_cols);
    clean.(country) = table2array(row)';
end

%% 13. Save outputs (solo CSV in processedDir)
outCsv = fullfile(processedDir, 'GDP_SouthAmerica_1990_2019.csv');
writetable(clean, outCsv);

disp(">>> GDP CLEANED AND PROCESSED SUCCESSFULLY <<<");
disp(['File scritto: ', outCsv]);

end
