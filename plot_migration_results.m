% Clear workspace
clear; clc; close all;

% --- CONFIGURATION ---
% Change these if you named your output files differently in the C step
detailedFile = 'output_results.csv';
summaryFile = 'summary_output_results.csv';

% Check files exist
if ~isfile(detailedFile) || ~isfile(summaryFile)
    error('Files not found. Make sure you ran the C program first and named the outputs correctly.');
end

% --- LOAD DATA ---
opts = detectImportOptions(detailedFile);
opts.VariableTypes{'Country'} = 'categorical';
T_detail = readtable(detailedFile, opts);

optsSum = detectImportOptions(summaryFile);
optsSum.VariableTypes{'Country'} = 'categorical';
T_summary = readtable(summaryFile, optsSum);

% --- FIGURE 1: Error Metrics Comparison ---
figure('Name', 'Migration Prediction Errors', 'Color', 'w', 'Position', [100, 100, 1000, 600]);
countries = string(T_summary.Country);
n_countries = length(countries);

% Create grouped bar chart data
metrics = [T_summary.MAE, T_summary.MedianAE];

b = bar(categorical(countries), metrics);
b(1).FaceColor = [0.2, 0.6, 0.8]; % Blue for MAE
b(2).FaceColor = [0.8, 0.4, 0.2]; % Orange for Median

title('Impact of Outliers: MAE vs Median Absolute Error', 'FontSize', 14);
ylabel('Net Migration Error', 'FontSize', 12);
legend({'MAE (Sensitive to Outliers)', 'Median AE (Robust)'}, 'Location', 'best');
grid on;
box on;

% Add count labels on top
xtips = b(1).XEndPoints;
ytips = max(metrics, [], 2)' + (max(metrics(:)) * 0.05);
for i = 1:length(countries)
    text(xtips(i), ytips(i), sprintf('n=%d', T_summary.Count(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
end

% --- FIGURE 2: Time Series Per Country ---
% Determine grid size for subplots
num_plots = n_countries;
cols = ceil(sqrt(num_plots));
rows = ceil(num_plots / cols);

figure('Name', 'Actual vs Predicted Time Series', 'Color', 'w', 'Position', [150, 150, 1200, 800]);

for i = 1:n_countries
    country_name = countries(i);
    
    % Extract data for specific country
    data_idx = T_detail.Country == country_name;
    sub_data = T_detail(data_idx, :);
    
    % Sort by year to ensure lines connect correctly
    sub_data = sortrows(sub_data, 'Year');
    
    subplot(rows, cols, i);
    hold on;
    
    % Plot Actual
    plot(sub_data.Year, sub_data.Actual, '-o', 'LineWidth', 2, 'Color', 'b', 'MarkerSize', 4, 'MarkerFaceColor', 'b');
    
    % Plot Predicted
    plot(sub_data.Year, sub_data.Predicted, '--s', 'LineWidth', 2, 'Color', 'r', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
    
    title(char(country_name), 'Interpreter', 'none', 'FontWeight', 'bold');
    if i == 1
        legend('Actual', 'Predicted', 'Location', 'best');
    end
    
    grid on;
    xlim([min(sub_data.Year)-1, max(sub_data.Year)+1]);
    
    % Format Y-axis to be readable
    ax = gca;
    ax.YAxis.Exponent = 0;
    
    hold off;
end

sgtitle('Migration Trends: Historical vs Predicted (Validation)', 'FontSize', 16);