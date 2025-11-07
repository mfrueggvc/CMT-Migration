%% UN Population Data Extraction and Organization
% File: SYB67_1_202411_Population, Surface Area and Density.txt
% Author: <your name>
% Description: Reads the UN population dataset in text format, extracts
% main columns (Country, Year, Total Population), and organizes the data.

clc; clear;

% 1️⃣ Read the entire content of the text file
% Make sure this file is in the same folder as your MATLAB script
filename = 'SYB67_1_202411_Population, Surface Area and Density.txt';
rawText = fileread(filename);

% 2️⃣ Use a regular expression (regex) to capture key fields
% It looks for: Country name, Year, and Total Population value
expr = '(?<Country>[A-Z][A-Za-z\s\.\-\(\)éèëêïîàç''']+)\s+(?<Year>\d{4})\s+(?<Total>\d+\.\d+)';

tokens = regexp(rawText, expr, 'names');

% 3️⃣ Convert the structure array into a MATLAB table
T = struct2table(tokens);

% 4️⃣ Convert text columns to numeric types
T.Year = str2double(T.Year);
T.Total = str2double(T.Total);

% 5️⃣ Remove duplicates and sort by country and year
T = unique(T, 'rows');
T = sortrows(T, {'Country','Year'});

% 6️⃣ Display the first few rows
disp('Preview of the extracted table:');
disp(T(1:15,:));

% 7️⃣ (Optional) Save results to Excel for easier inspection
writetable(T, 'UN_Population_Simplified.xlsx');
disp('✅ Data saved as UN_Population_Simplified.xlsx');