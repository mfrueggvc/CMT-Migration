% run_plot_migration_results.m
% Generates plots from C comparison output
% Input: summary_out.csv, out.csv (from results/evaluation/)
% Output: PNG graphs in results/evaluation/Graphs/

clear; clc; close all;

%% 1. Setup and Path Resolution
thisFile    = mfilename('fullpath');
plotsDir    = fileparts(thisFile);      % .../matlab/plots
matlabDir   = fileparts(plotsDir);      % .../matlab
projectRoot = fileparts(matlabDir);     % .../CMT-Migration

comparisonDir = fullfile(projectRoot, 'results', 'evaluation');
outputFolder = fullfile(comparisonDir, 'Graphs');

summaryFileName = 'summary_out.csv';
detailFileName  = 'out.csv';

file1_name = fullfile(comparisonDir, summaryFileName);
file2_name = fullfile(comparisonDir, detailFileName);

fprintf('=== PLOT GENERATION START ===\n');
fprintf('Project root:    %s\n', projectRoot);
fprintf('Input files:     %s\n', comparisonDir);
fprintf('Output folder:   %s\n\n', outputFolder);

%% 2. Validate Input Files
if ~isfile(file1_name)
    error('File not found: %s\nRun comparison step first!', file1_name);
end

if ~isfile(file2_name)
    error('File not found: %s\nRun comparison step first!', file2_name);
end

%% 3. Create Output Folder
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
    fprintf('Created output folder: %s\n', outputFolder);
end

%% 4. Load Data
fprintf('Loading data...\n');
T1 = readtable(file1_name);
T2 = readtable(file2_name);

% Convert Country columns to string
T1.Country = string(T1.Country);
T2.Country = string(T2.Country);
T1.CountryCat = categorical(T1.Country);

fprintf('  Summary data: %d countries\n', height(T1));
fprintf('  Detail data:  %d records\n\n', height(T2));

%% 5. Helper Functions
common_style = @(ax) set(ax, 'LineWidth', 1.2, 'FontSize', 10, 'Box', 'on', 'TickDir', 'in');

lifted_title_sum = @(text) title(text, 'Units', 'normalized', 'Position', [0.5, 1.02, 0], ...
    'FontSize', 12, 'FontWeight', 'bold');

lifted_title_ind = @(text) title(text, 'Units', 'normalized', 'Position', [0.5, 1.02, 0], ...
    'FontSize', 11, 'FontWeight', 'bold');

%% 6. Summary Figure (Linear Scale)
fprintf('Generating summary figure (linear scale)...\n');

f_lin = figure('Name', 'Summary Metrics (Linear)', 'Color', 'w', 'Position', [100, 100, 1000, 800], 'Visible', 'off');
sgtitle('Model Performance Metrics by Country (Linear Scale)');

% MAE
subplot(3, 1, 1);
bar(T1.CountryCat, T1.MAE, 'FaceColor', [0.2 0.6 0.8]);
ylabel('MAE'); title('Mean Absolute Error (Magnitude)'); grid on;
common_style(gca);

% MBE (can be negative)
subplot(3, 1, 2);
bar(T1.CountryCat, T1.MBE, 'FaceColor', [0.8 0.4 0.2]);
ylabel('MBE'); title('Mean Bias Error (Direction: +Under / -Over)');
yline(0, 'k', 'LineWidth', 1.5);
grid on;
common_style(gca);

% MedianAE
subplot(3, 1, 3);
bar(T1.CountryCat, T1.MedianAE, 'FaceColor', [0.4 0.7 0.4]);
ylabel('Median AE'); title('Median Absolute Error (Robustness)'); grid on;
common_style(gca);

saveFileName = fullfile(outputFolder, 'Summary_Metrics_Linear.png');
saveas(f_lin, saveFileName);
close(f_lin);
fprintf('  Saved: Summary_Metrics_Linear.png\n');

%% 7. Summary Figure (Log Scale)
fprintf('Generating summary figure (log scale)...\n');

% Calculate safe log limits
all_log_data = [T1.MAE; abs(T1.MBE); T1.MedianAE];
valid_data = all_log_data(all_log_data > 0 & ~isnan(all_log_data));

if isempty(valid_data)
    y_min_log = 0.1;
    y_max_log = 100;
else
    y_min_log = 10^floor(log10(min(valid_data)));
    y_max_log = 10^ceil(log10(max(valid_data)));
end

f_log = figure('Name', 'Summary Metrics (Log Scale)', 'Color', 'w', 'Position', [150, 150, 1000, 800], 'Visible', 'off');
t = tiledlayout(3, 1, 'TileSpacing', 'loose', 'Padding', 'loose');
title(t, 'Model Performance Metrics by Country (Log Scale)', 'FontSize', 14, 'FontWeight', 'bold');

% MAE (Log)
nexttile;
b1 = bar(T1.CountryCat, T1.MAE, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'YScale', 'log');
ylim([y_min_log, y_max_log]);
ylabel('MAE (Log)'); lifted_title_sum('Mean Absolute Error'); grid on;
b1.BaseValue = y_min_log;
common_style(gca);

% MBE (Log - absolute value)
nexttile;
hold on;
pos = T1.MBE >= 0;
neg = T1.MBE < 0;

if any(pos)
    bp = bar(T1.CountryCat(pos), abs(T1.MBE(pos)), 'FaceColor', [0.2 0.4 0.8]);
    bp.BaseValue = y_min_log;
end

if any(neg)
    bn = bar(T1.CountryCat(neg), abs(T1.MBE(neg)), 'FaceColor', [0.8 0.4 0.2]);
    bn.BaseValue = y_min_log;
end

set(gca, 'YScale', 'log');
ylim([y_min_log, y_max_log]);
ylabel('|MBE| (Log)'); lifted_title_sum('Mean Bias (Blue=Under, Orange=Over)'); grid on;
common_style(gca);
hold off;

% MedianAE (Log)
nexttile;
b3 = bar(T1.CountryCat, T1.MedianAE, 'FaceColor', [0.4 0.7 0.4]);
set(gca, 'YScale', 'log');
ylim([y_min_log, y_max_log]);
ylabel('Median AE (Log)'); lifted_title_sum('Median Absolute Error'); grid on;
b3.BaseValue = y_min_log;
common_style(gca);

saveFileName = fullfile(outputFolder, 'Summary_Metrics_LogScale.png');
saveas(f_log, saveFileName);
close(f_log);
fprintf('  Saved: Summary_Metrics_LogScale.png\n');

%% 8. Individual Country Time Series
uniqueCountries = unique(T2.Country);
fprintf('\nGenerating time series for %d countries...\n', length(uniqueCountries));

f_ts = figure('Color', 'w', 'Visible', 'off', 'Position', [100, 100, 800, 900]);

for i = 1:length(uniqueCountries)
    clf(f_ts);
    
    currentCountry = uniqueCountries{i};
    if iscell(currentCountry)
        currentCountry = currentCountry{1};
    end
    
    set(f_ts, 'Name', currentCountry);
    
    % Filter and sort data
    idx = strcmp(T2.Country, currentCountry);
    countryData = T2(idx, :);
    
    if height(countryData) == 0
        warning('No data for country: %s', currentCountry);
        continue;
    end
    
    [~, sortIdx] = sort(countryData.Year);
    countryData = countryData(sortIdx, :);
    
    % Layout
    t_sub = tiledlayout(f_ts, 2, 1, 'TileSpacing', 'loose', 'Padding', 'loose');
    t_sub.Units = 'normalized';
    t_sub.OuterPosition = [0 0 1 0.92];
    
    title(t_sub, {['Time Series Analysis: ' currentCountry], ''}, ...
        'FontSize', 15, 'FontWeight', 'bold');
    
    % Plot 1: Real vs Predicted
    nexttile;
    plot(countryData.Year, countryData.Actual, '-o', 'LineWidth', 1.5, 'MarkerSize', 5); hold on;
    plot(countryData.Year, countryData.Predicted, '--x', 'LineWidth', 1.5, 'MarkerSize', 5);
    ylabel('Net Migration'); lifted_title_ind('Real vs Predicted');
    legend('Actual', 'Predicted', 'Location', 'best'); grid on;
    xticks(countryData.Year); xtickformat('%.0f');
    common_style(gca);
    hold off;
    
    % Plot 2: Residuals
    nexttile;
    plotData = countryData.Residual;
    bar(countryData.Year, plotData, 'FaceColor', [0.6 0.6 0.6]);
    ylabel('Residual'); lifted_title_ind('Residuals (Positive = Underpredicted, Negative = Overpredicted)');
    yline(0, 'k', 'LineWidth', 1.5); grid on;
    
    % Dynamic Y-axis scaling
    min_val = min(plotData, [], 'omitnan');
    max_val = max(plotData, [], 'omitnan');
    
    if isempty(min_val) || isnan(min_val)
        min_val = 0;
        max_val = 0;
    end
    
    range_val = max_val - min_val;
    
    if range_val == 0
        step = 10;
    else
        raw_step = range_val / 8;
        magnitude = 10^floor(log10(raw_step));
        normalized = raw_step / magnitude;
        
        if normalized < 1.5
            step = 1 * magnitude;
        elseif normalized < 3.5
            step = 2 * magnitude;
        else
            step = 5 * magnitude;
        end
        
        if step < 10
            step = 10;
        end
        
        step = ceil(step / 10) * 10;
    end
    
    lower_lim = floor(min_val / step) * step;
    upper_lim = ceil(max_val / step) * step;
    
    if lower_lim == upper_lim
        lower_lim = lower_lim - step;
        upper_lim = upper_lim + step;
    end
    
    ylim([lower_lim, upper_lim]);
    yticks(lower_lim:step:upper_lim);
    xticks(countryData.Year); xtickformat('%.0f');
    common_style(gca);
    
    % Save
    cleanName = strrep(currentCountry, ' ', '_');
    saveFileName = fullfile(outputFolder, ['TimeSeries_' cleanName '.png']);
    saveas(f_ts, saveFileName);
    
    fprintf('  Saved: TimeSeries_%s.png\n', cleanName);
end

close(f_ts);

%% 9. Summary
fprintf('\n=== PLOT GENERATION COMPLETE ===\n');
fprintf('All graphs saved to: %s\n', outputFolder);
fprintf('Generated files:\n');
fprintf('  - Summary_Metrics_Linear.png\n');
fprintf('  - Summary_Metrics_LogScale.png\n');
fprintf('  - TimeSeries_*.png (one per country)\n');