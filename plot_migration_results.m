%% 1. Setup and Data Loading
clear; clc; close all;

% Define file names
file1_name = 'file1.csv'; % Format: Country,Count,MAE,RMSE,MedianAE
file2_name = 'file2.csv'; % Format: Country,Year,Actual,Predicted,AbsError

% Check if input files exist
if ~isfile(file1_name) || ~isfile(file2_name)
    error('Files not found. Please ensure file1.csv and file2.csv are in the current folder.');
end

% Create a folder to save the PNGs
outputFolder = 'Generated_Graphs';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Load tables
T1 = readtable(file1_name);
T2 = readtable(file2_name);

% Convert Country columns to string/categorical for easier handling
if ~isstring(T1.Country) && ~iscell(T1.Country)
    T1.Country = string(T1.Country);
end
T1.CountryCat = categorical(T1.Country);

%% 2. Graphs for File 1 (Summary Metrics by Country)
% X-axis = Country, Y-axis = Value

f1 = figure('Name', 'Summary Metrics by Country', 'Color', 'w', 'Position', [100, 100, 1000, 800]);
sgtitle('Model Performance Metrics by Country (File 1)');

% -- MAE Subplot --
subplot(3, 1, 1);
bar(T1.CountryCat, T1.MAE, 'FaceColor', [0.2 0.6 0.8]);
ylabel('MAE');
title('Mean Absolute Error');
grid on;

% -- RMSE Subplot --
subplot(3, 1, 2);
bar(T1.CountryCat, T1.RMSE, 'FaceColor', [0.8 0.4 0.2]);
ylabel('RMSE');
title('Root Mean Squared Error');
grid on;

% -- MedianAE Subplot --
subplot(3, 1, 3);
bar(T1.CountryCat, T1.MedianAE, 'FaceColor', [0.4 0.7 0.4]);
ylabel('Median AE');
title('Median Absolute Error');
grid on;

% SAVE FIGURE 1
saveFileName = fullfile(outputFolder, 'Summary_Metrics_Comparison.png');
saveas(f1, saveFileName);
fprintf('Saved: %s\n', saveFileName);


%% 3. Graphs for File 2 (Time Series by Year)
% X-axis = Year, Y-axis = Value (Real vs Predicted, AbsError)

uniqueCountries = unique(T2.Country);

for i = 1:length(uniqueCountries)
    currentCountry = uniqueCountries{i};
    if iscell(currentCountry)
        currentCountry = currentCountry{1};
    end
    
    % Filter data for this specific country
    idx = strcmp(T2.Country, currentCountry);
    countryData = T2(idx, :);
    
    % Sort by Year
    [~, sortIdx] = sort(countryData.Year);
    countryData = countryData(sortIdx, :);
    
    % Create figure
    f2 = figure('Name', ['Time Series: ' currentCountry], 'Color', 'w', 'Visible', 'off'); % Visible off speeds up loop
    sgtitle(['Time Series Analysis: ' currentCountry]);
    
    % -- Subplot 1: Real vs Predicted --
    subplot(2, 1, 1);
    plot(countryData.Year, countryData.Actual, '-o', 'LineWidth', 1.5, 'DisplayName', 'Actual');
    hold on;
    plot(countryData.Year, countryData.Predicted, '--x', 'LineWidth', 1.5, 'DisplayName', 'Predicted');
    xlabel('Year');
    ylabel('Value');
    title('Real vs Predicted Value');
    legend('Location', 'best');
    grid on;
    
    % -- Subplot 2: Absolute Error --
    subplot(2, 1, 2);
    bar(countryData.Year, countryData.AbsError, 'FaceColor', [0.6 0.6 0.6]); 
    xlabel('Year');
    ylabel('Absolute Error');
    title('Absolute Error per Year');
    grid on;
    
    % SAVE FIGURE 2 (Clean filename to avoid errors with spaces)
    cleanCountryName = strrep(currentCountry, ' ', '_'); 
    saveFileName = fullfile(outputFolder, ['TimeSeries_' cleanCountryName '.png']);
    saveas(f2, saveFileName);
    fprintf('Saved: %s\n', saveFileName);
    
    % Close figure to free memory
    close(f2);
end

disp('------------------------------------------------');
disp(['Processing complete. All graphs saved in: ' outputFolder]);