function preprocess_Unemployment(rawDir, processedDir)
% Build unemployment dataset for South America (1990–2019) and save CSV.

filename = fullfile(rawDir, 'Unemployment_Worldbank_Unchanged.csv');

%% 1) Read all raw lines
fid = fopen(filename, 'r', 'n', 'UTF-8');
if fid == -1
    error('Cannot open file: %s', filename);
end
raw_lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fid);
raw_lines = raw_lines{1};

%% 2) Header = 5th line
header_line  = raw_lines{5};
header_cells = strsplit(header_line, ',');
header_cells = strrep(header_cells, '"', '');

while ~isempty(header_cells) && all(header_cells{end}=="")
    header_cells(end) = [];
end

nCols = numel(header_cells);

%% 3) Data lines
data_lines = raw_lines(6:end);
data_lines = data_lines(~cellfun(@(s) isempty(strtrim(s)), data_lines));
nRows = numel(data_lines);

%% 4) Build raw matrix
rows = cell(nRows, nCols);

for i = 1:nRows
    parts = strsplit(data_lines{i}, ',');
    parts = strrep(parts, '"', '');
    
    if numel(parts) < nCols
        parts(end+1:nCols) = {''};
    elseif numel(parts) > nCols
        parts = parts(1:nCols);
    end
    
    rows(i,:) = parts;
end

%% 5) Build MATLAB table
varNames = matlab.lang.makeValidName(header_cells);
T = cell2table(rows, 'VariableNames', varNames);

%% 6) Detect year columns
allVars = T.Properties.VariableNames;

% AI-generated block (regex-based year detection and sorting), ChatGPT
isYear  = ~cellfun(@isempty, regexp(allVars, '^x?(199\d|20[0-1]\d)$', 'once'));
yearCols = allVars(isYear);

years = str2double(erase(yearCols, "x"));
mask  = years >= 1990 & years <= 2019;
years    = years(mask);
yearCols = yearCols(mask);

[years, idx] = sort(years);
yearCols = yearCols(idx);
% End AI-generated block

%% 7) Country column
if ismember('CountryName', T.Properties.VariableNames)
    country_col = 'CountryName';
else
    error("Column 'CountryName' not found.");
end

%% 8) South America countries
south_america = ["Argentina","Bolivia","Brazil","Chile","Colombia","Ecuador", ...
                 "Guyana","Paraguay","Peru","Suriname","Uruguay","Venezuela"];

%% 9) Build final table with padding
clean = table(years', 'VariableNames', {'Year'});
Ny = length(years);

for i = 1:length(south_america)
    cname = south_america(i);

    idxCountry = strcmp(string(T.(country_col)), cname);

    if ~any(idxCountry)
        vals = NaN(Ny,1);
    else
        row      = T(idxCountry, yearCols);
        raw_vals = table2array(row(1,:));
        vals     = str2double(raw_vals(:));
        
        if length(vals) < Ny
            vals = [vals; NaN(Ny-length(vals),1)];
        elseif length(vals) > Ny
            vals = vals(1:Ny);
        end
    end

    clean.(cname) = vals;
end

%% 10) Save CSV (no .mat)
outCsv = fullfile(processedDir, 'Unemployment_SouthAmerica_1990_2019.csv');
writetable(clean, outCsv);

disp('>>> Unemployment_SouthAmerica_1990_2019.csv created successfully <<<');
disp(size(clean));

end
