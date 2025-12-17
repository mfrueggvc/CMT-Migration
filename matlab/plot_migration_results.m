% Project: Migration Model
% Author: Mark Rüegg
% Date: 17-12-2025
% Description: 
%   Reads statistical output from the C engine and generates:
%   1. A global summary dashboard.
%   2. Individual time-series plots for every country.
%   
% Input: 'summary_out.csv', 'out.csv'
% Output: Saves PNG images to 'Generated_Graphs' folder.

% --- AUTOMATIC FOLDER ALIGNMENT ---
scriptPath = mfilename('fullpath');
[scriptFolder, ~, ~] = fileparts(scriptPath);
if ~isempty(scriptFolder), cd(scriptFolder); end

%% 1. Setup
clear; clc; close all;

file1_name = 'summary_out.csv'; 
file2_name = 'out.csv';         

if ~isfile(file1_name)
    error('File "%s" not found in %s', file1_name, pwd);
end

opts = detectImportOptions(file1_name); opts.VariableNamingRule = 'preserve';
T1 = readtable(file1_name, opts);

opts2 = detectImportOptions(file2_name); opts2.VariableNamingRule = 'preserve';
T2 = readtable(file2_name, opts2);

% Ensure String/Categorical Types
if ~isstring(T1.Country) && ~iscell(T1.Country), T1.Country = string(T1.Country); end
if ~isstring(T2.Country) && ~iscell(T2.Country), T2.Country = string(T2.Country); end
T1.CountryCat = categorical(T1.Country);

outputFolder = 'Generated_Graphs';
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end

%% 2. Global Helper Functions (Defined ONCE)

common_style = @(ax) set(ax, 'LineWidth', 1.2, 'FontSize', 10, 'Box', 'on', 'TickDir', 'in');

% Title Helpers
lifted_title_sum = @(text) title(text, 'Units', 'normalized', 'Position', [0.5, 1.02, 0], ...
                             'FontSize', 12, 'FontWeight', 'bold');
                         
lifted_title_ind = @(text) title(text, 'Units', 'normalized', 'Position', [0.5, 1.02, 0], ...
                             'FontSize', 11, 'FontWeight', 'bold');

%% 3. Summary Figure
% Calculate Limits
all_log_data = [T1.MAE; abs(T1.MBE); T1.MedianAE];
valid_data = all_log_data(all_log_data > 0 & ~isnan(all_log_data)); % Handle NaNs
if isempty(valid_data)
    y_min_log = 0.1; y_max_log = 100;
else
    y_min_log = 10^floor(log10(min(valid_data)));
    y_max_log = 10^ceil(log10(max(valid_data)));
end

f_sum = figure('Color', 'w', 'Position', [50, 50, 1000, 1600], 'Visible', 'off');
t = tiledlayout(4, 1, 'TileSpacing', 'loose', 'Padding', 'loose');

% Main Title with Spacer
title(t, {'Migration Model Comparison', ''}, 'FontSize', 18, 'FontWeight', 'bold');

% --- 1. MAE ---
nexttile;
b1 = bar(T1.CountryCat, T1.MAE, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'YScale', 'log'); ylim([y_min_log, y_max_log]); 
ylabel('MAE'); lifted_title_sum('Mean Absolute Error (Magnitude)'); grid on;
b1.BaseValue = y_min_log; common_style(gca);

% --- 2. MBE ---
nexttile; hold on;
pos = T1.MBE >= 0; neg = T1.MBE < 0;
bp = bar(T1.CountryCat(pos), abs(T1.MBE(pos)), 'FaceColor', [0.2 0.4 0.8]);
bn = bar(T1.CountryCat(neg), abs(T1.MBE(neg)), 'FaceColor', [0.8 0.4 0.2]);
set(gca, 'YScale', 'log'); ylim([y_min_log, y_max_log]); 
ylabel('MBE'); lifted_title_sum('Mean Bias (Blue=Under, Orange=Over)'); grid on;
if ~isempty(bp), bp.BaseValue = y_min_log; end
if ~isempty(bn), bn.BaseValue = y_min_log; end
common_style(gca); hold off;

% --- 3. Median AE ---
nexttile;
b3 = bar(T1.CountryCat, T1.MedianAE, 'FaceColor', [0.4 0.7 0.4]);
set(gca, 'YScale', 'log'); ylim([y_min_log, y_max_log]); 
ylabel('MedAE'); lifted_title_sum('Median Absolute Error'); grid on;
b3.BaseValue = y_min_log; common_style(gca);

% --- 4. MAPE (Linear) ---
nexttile;
bar(T1.CountryCat, T1.MAPE, 'FaceColor', [0.6 0.2 0.6]);
ylabel('MAPE (%)'); lifted_title_sum('Mean Absolute Percentage Error (Linear)'); grid on;
common_style(gca);

% Dynamic Linear Limits (Steps of 10)
max_mape = max(T1.MAPE, [], 'omitnan');
if max_mape > 0
    upper_limit = ceil(max_mape / 10) * 10;
    if upper_limit == 0, upper_limit = 10; end
    ylim([0, upper_limit]); yticks(0:10:upper_limit);
else
    yticks('auto');
end

saveas(f_sum, fullfile(outputFolder, 'Summary_Accuracy.png'));
close(f_sum);
fprintf('Saved Summary Graph.\n');

%% 4. Time Series Loop
uniqueCountries = unique(T2.Country);
fprintf('Generating Time Series Graphs for %d countries...\n', length(uniqueCountries));

f_ts = figure('Color', 'w', 'Visible', 'off', 'Position', [100, 100, 800, 900]);

for i = 1:length(uniqueCountries)
    % Clear previous plot content from the reused figure
    clf(f_ts); 
    
    currentCountry = uniqueCountries{i};
    if iscell(currentCountry), currentCountry = currentCountry{1}; end
    
    set(f_ts, 'Name', currentCountry);

    idx = strcmp(T2.Country, currentCountry);
    countryData = T2(idx, :);
    [~, sortIdx] = sort(countryData.Year);
    countryData = countryData(sortIdx, :);
    
    % Skip if data is missing/empty
    if height(countryData) == 0, continue; end
    
    % Layout setup
    t_sub = tiledlayout(f_ts, 2, 1, 'TileSpacing', 'loose', 'Padding', 'loose');
    t_sub.Units = 'normalized';
    t_sub.OuterPosition = [0 0 1 0.92]; 
    
    title(t_sub, {['Analysis: ' currentCountry], ''}, 'FontSize', 15, 'FontWeight', 'bold');
    
    % --- PLOT 1 ---
    nexttile;
    plot(countryData.Year, countryData.Actual, '-o', 'LineWidth', 1.5, 'MarkerSize', 5); hold on;
    plot(countryData.Year, countryData.Predicted, '--x', 'LineWidth', 1.5, 'MarkerSize', 5);
    ylabel('Value'); lifted_title_ind('Real vs Predicted'); 
    legend('Actual','Predicted', 'Location', 'best'); grid on;
    xticks(countryData.Year); xtickformat('%.0f');
    common_style(gca);
    
    % --- PLOT 2 ---
    nexttile;
    hasPct = ismember('PctError', T2.Properties.VariableNames);
    if hasPct
        plotData = countryData.PctError;
        bar(countryData.Year, plotData, 'FaceColor', [0.5 0.5 0.5]); 
        ylabel('% Error'); lifted_title_ind('Percentage Error (Positive=Over, Negative=Under)');
    else
        plotData = countryData.Residual;
        bar(countryData.Year, plotData, 'FaceColor', [0.6 0.6 0.6]); 
        ylabel('Residual'); lifted_title_ind('Residuals');
    end
    yline(0, 'k', 'LineWidth', 1.5); grid on;
    
    % --- SCALE LOGIC ---
    % Uses 'omitnan' to prevent crashes on missing data
    min_val = min(plotData, [], 'omitnan'); 
    max_val = max(plotData, [], 'omitnan');
    
    if isempty(min_val) || isnan(min_val), min_val = 0; max_val = 0; end
    
    range_val = max_val - min_val;
    
    % Scalable "Multiple of 10" Logic
    if range_val == 0
        step = 10;
    else
        % Aim for roughly 8-10 ticks
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
        
        
        if step < 10, step = 10; end
        
        step = ceil(step / 10) * 10;
    end

    lower_lim = floor(min_val / step) * step;
    upper_lim = ceil(max_val / step) * step;
    
    if lower_lim == upper_lim
        lower_lim = lower_lim - step; upper_lim = upper_lim + step;
    end
    
    ylim([lower_lim, upper_lim]);
    yticks(lower_lim:step:upper_lim);
    xticks(countryData.Year); xtickformat('%.0f');
    common_style(gca);
    
    cleanName = strrep(currentCountry, ' ', '_'); 
    saveas(f_ts, fullfile(outputFolder, ['TimeSeries_' cleanName '.png']));

end

close(f_ts);
fprintf('Done! All formatted graphs saved to: %s\n', fullfile(pwd, outputFolder));