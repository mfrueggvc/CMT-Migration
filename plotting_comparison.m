% Clear environment
clear; clc; close all;

% --- CONFIGURATION ---
detailedFile = 'comparison_results.csv';
summaryFile = 'summary_comparison_results.csv';
% ---------------------

% 1. Plot Accuracy Bar Chart (Using Summary File)
if isfile(summaryFile)
    summaryData = readtable(summaryFile);
    
    figure('Name', 'Accuracy by Country', 'Color', 'w');
    % Sort by MAE for better visualization
    summaryData = sortrows(summaryData, 'MAE', 'descend');
    
    bar(categorical(summaryData.Country), summaryData.MAE);
    title('Prediction Error by Country (MAE)');
    ylabel('Mean Absolute Error (Lower is better)');
    xlabel('Country');
    grid on;
else
    disp('Error: Summary file not found. Run the C program first.');
end

% 2. Plot Actual vs Predicted (Using Detailed File)
if isfile(detailedFile)
    detailedData = readtable(detailedFile);
    
    % Choose a country to plot (e.g., 'Brazil' or 'Total')
    % Change this variable to plot different countries
    targetCountry = 'Brazil'; 
    
    idx = strcmp(detailedData.Country, targetCountry);
    
    if any(idx)
        countryData = detailedData(idx, :);
        
        figure('Name', ['Results: ' targetCountry], 'Color', 'w');
        plot(countryData.Year, countryData.Actual, '-o', 'LineWidth', 2, 'DisplayName', 'Actual');
        hold on;
        plot(countryData.Year, countryData.Predicted, '-x', 'LineWidth', 2, 'DisplayName', 'Predicted');
        
        title(['Net Migration: ' targetCountry]);
        xlabel('Year');
        ylabel('Migration Value');
        legend('show');
        grid on;
    else
        disp(['Country ' targetCountry ' not found in detailed results.']);
    end
else
    disp('Error: Detailed results file not found.');
end