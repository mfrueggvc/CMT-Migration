%% 1. Setup and Data Loading
clear; clc; close all;

% Define file names (Change to match your output from C code)
file1_name = 'summary_out.csv'; % Format: Country,Count,MAE,MBE,MedianAE
file2_name = 'out.csv';         % Format: Country,Year,Actual,Predicted,Residual

% Check if input files exist
if ~isfile(file1_name) || ~isfile(file2_name)
    error('Files not found. Please ensure the CSV files are in the current folder.');
end

% Create a folder to save the PNGs
outputFolder = 'Generated_Graphs';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Load tables
T1 = readtable(file1_name);
T2 = readtable(file2_name);

% Convert Country columns to string/categorical
if ~isstring(T1.Country) && ~iscell(T1.Country)
    T1.Country = string(T1.Country);
end
T1.CountryCat = categorical(T1.Country);

%% 2. Graphs for File 1: LINEAR Scale (MAE, MBE, MedianAE)
f_lin = figure('Name', 'Summary Metrics (Linear)', 'Color', 'w', 'Position', [100, 100, 1000, 800]);
sgtitle('Model Performance Metrics by Country (Linear Scale)');

% MAE
subplot(3, 1, 1);
bar(T1.CountryCat, T1.MAE, 'FaceColor', [0.2 0.6 0.8]);
ylabel('MAE'); title('Mean Absolute Error (Magnitude)'); grid on;

% MBE (New! Can be negative)
subplot(3, 1, 2);
bar(T1.CountryCat, T1.MBE, 'FaceColor', [0.8 0.4 0.2]);
ylabel('MBE'); title('Mean Bias Error (Direction: +Under / -Over)'); 
yline(0, 'k', 'LineWidth', 1.5); % Add a strong zero line
grid on;

% MedianAE
subplot(3, 1, 3);
bar(T1.CountryCat, T1.MedianAE, 'FaceColor', [0.4 0.7 0.4]);
ylabel('Median AE'); title('Median Absolute Error (Robustness)'); grid on;

% Save Linear Figure
saveFileName = fullfile(outputFolder, 'Summary_Metrics_Linear.png');
saveas(f_lin, saveFileName);
fprintf('Saved: %s\n', saveFileName);


%% 3. Graphs for File 1: LOG Scale (MAE & MedianAE only)
% Note: We cannot plot MBE on log scale easily because it has negative values.
f_log = figure('Name', 'Summary Metrics (Log Scale)', 'Color', 'w', 'Position', [150, 150, 1000, 800]);
sgtitle('Magnitude Metrics by Country (Log Scale)');

% MAE (Log)
subplot(2, 1, 1);
b1 = bar(T1.CountryCat, T1.MAE, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'YScale', 'log'); 
ylabel('MAE (Log)'); title('Mean Absolute Error (Log Scale)'); grid on;
b1.BaseValue = min(T1.MAE(T1.MAE>0)) / 10; % Fix visual baseline

% MedianAE (Log)
subplot(2, 1, 2);
b3 = bar(T1.CountryCat, T1.MedianAE, 'FaceColor', [0.4 0.7 0.4]);
set(gca, 'YScale', 'log');
ylabel('Median AE (Log)'); title('Median Absolute Error (Log Scale)'); grid on;
b3.BaseValue = min(T1.MedianAE(T1.MedianAE>0)) / 10;

% Save Log Figure
saveFileName = fullfile(outputFolder, 'Summary_Metrics_LogScale.png');
saveas(f_log, saveFileName);
fprintf('Saved: %s\n', saveFileName);


%% 4. Graphs for File 2 (Time Series: Residuals)
uniqueCountries = unique(T2.Country);

for i = 1:length(uniqueCountries)
    currentCountry = uniqueCountries{i};
    if iscell(currentCountry)
        currentCountry = currentCountry{1};
    end
    
    % Filter and Sort Data
    idx = strcmp(T2.Country, currentCountry);
    countryData = T2(idx, :);
    [~, sortIdx] = sort(countryData.Year);
    countryData = countryData(sortIdx, :);
    
    % Create figure (Invisible to save speed)
    f_ts = figure('Name', ['Time Series: ' currentCountry], 'Color', 'w', 'Visible', 'off');
    sgtitle(['Time Series Analysis: ' currentCountry]);
    
    % Real vs Predicted
    subplot(2, 1, 1);
    plot(countryData.Year, countryData.Actual, '-o', 'LineWidth', 1.5, 'DisplayName', 'Actual');
    hold on;
    plot(countryData.Year, countryData.Predicted, '--x', 'LineWidth', 1.5, 'DisplayName', 'Predicted');
    xlabel('Year'); ylabel('Value');
    title('Real vs Predicted Value');
    legend('Location', 'best'); grid on;
    
    % Residuals (New! Can be negative)
    subplot(2, 1, 2);
    bar(countryData.Year, countryData.Residual, 'FaceColor', [0.6 0.6 0.6]); 
    yline(0, 'k', 'LineWidth', 1.5); % Zero line
    xlabel('Year'); ylabel('Residual (Act - Pred)');
    title('Residuals (Positive = Underpredicted, Negative = Overpredicted)'); grid on;
    
    % Save
    cleanCountryName = strrep(currentCountry, ' ', '_'); 
    saveFileName = fullfile(outputFolder, ['TimeSeries_' cleanCountryName '.png']);
    saveas(f_ts, saveFileName);
    fprintf('Saved: %s\n', saveFileName);
    
    close(f_ts); 
end

disp('------------------------------------------------');
disp(['Processing complete. Check the folder: ' outputFolder]);