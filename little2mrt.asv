
clc; clear; close all
% THIS PROGRAM CAN PREDICT THE NET MIGRATION OF A TARGET YEAR, IN ORDER TO DO THAT, WE NEED TO HAVE THE GDP OF THAT.   
% read table GDP (columns: Country, Year, GDP, NetMig)
T = readtable('GDP_long.txt','Delimiter','\t');

% 
country_name = input('Choose country: ','s');
idx = strcmp(T.Country, country_name);
Tc = T(idx,:);
% estimation parameters for gdp. loglinear trend 
idx_g = Tc.Year >= 1990 & Tc.Year <= 2023;
Ty = Tc(idx_g,:);
t  = Ty.Year;
lg = log(Ty.GDP);
B = [ones(size(t)) t] \ lg;
c = B(1);
d = B(2);

%create a range of data from a choosen range of time in the past with clear
%datas
idx_est = Tc.Year >= 1990 & Tc.Year <= 2005;
Te = Tc(idx_est,:);

% Variables
x1 = log(Te.GDP);          % ln(GDP)
x2 = (log(Te.GDP)).^2;     % [ln(GDP)]^2
y  = Te.NetMig;            % net migration observed
% Regression matrix
X = [ones(size(x1))  x1  x2];

b = X\y;

% parameters estimation [alpha; beta; gamma]
alpha = b(1);
beta  = b(2);
gamma = b(3);

%  yhat is the reconstruction (for control maybe) 
yhat = X*b;

% minimal output 
disp('alpha, beta, gamma stimati:')
disp(b)


% Calculate residuals and R-squared value
residuals = y - yhat;
SSR = sum(residuals.^2); % Sum of squared residuals
SST = sum((y - mean(y)).^2); % Total sum of squares
R_squared = 1 - (SSR / SST);

% Display the R-squared value
disp(['R-squared: ', num2str(R_squared)]);

% chosing the target year
Target_Year = input ('Year : '); 

% if the year is in the past already, present in the table : 
idx_fut = Tc.Year == target_year;

if any(idx_fut)
    GDP_target = Tc.GDP(idx_fut);          % usa GDP reale
else
    GDP_target = exp(c + d*target_year);   % usa GDP stimato
end
ln1 = log(GDP_target);
ln2 = (log(GDP_target))^2;

X_new = [1 ln1 ln2];

predicted_NetMig = X_new * b;

disp('Prediction net migration:')
disp(predicted_NetMig)