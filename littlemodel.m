clc;

clear;
%%
GDP = [1000; 5000; 10000; 20000; 40000; 60000];
Emigration = [15; 10; 7; 4; 2; 1];

GDP = GDP(:); Emigration = Emigration(:);
X = [ones(size(GDP)) GDP]
beta = X \ Emigration

%%
disp('Intercept and slope:');
disp(beta.');

x = input('Enter GDP per capita (USD): ');
y_pred = beta(1) + beta(2)*x;
fprintf('Estimated emigration rate: %.2f per 1000 inhabitants\n', y_pred);

figure;
plot(GDP, Emigration, 'o', 'MarkerFaceColor', 'b'); hold on;
x_line = linspace(min(GDP), max(GDP), 200).';
y_line = beta(1) + beta(2)*x_line;
plot(x_line, y_line, 'r-', 'LineWidth', 1.5);
xlabel('GDP per capita (USD)');
ylabel('Emigration rate (per 1000 people)');
title('Simple Emigration Estimation (No Toolbox)');
legend('Data', 'Fitted line');
grid on;

clear