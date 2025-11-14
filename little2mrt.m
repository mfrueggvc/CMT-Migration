
clc; clear; close all

% Input tables ("handwritten")
Tg = readtable('table gdp per country by hand .xlsx');          % columns: Country, Year, GDP
Te = readtable('table emigration per country by hand .xlsx');   % columns: Country, Year, EmigRate

% Normalisation helper for country names (no mistakes with maiusc/minusc
normalise_country = @(s) lower(strtrim(string(s)));

% Harmonise textual columns
Tg.Country = normalise_country(Tg.Country);
Te.Country = normalise_country(Te.Country);

% Ensure GDP is numeric
if ~isnumeric(Tg.GDP)
    Tg.GDP = str2double(erase(string(Tg.GDP),{',','$',' '}));
end

% Ensure the emigration rate column has a consistent name
if any(strcmpi(Te.Properties.VariableNames, 'EmigRate'))
    Te = renamevars(Te, 'EmigRate', 'EmigrationRate');
elseif ~any(strcmpi(Te.Properties.VariableNames, 'EmigrationRate'))
    error('Table must contain column Emigration Rate.');
end

% Ensure emigration rates are numeric
if ~isnumeric(Te.EmigrationRate)
    Te.EmigrationRate = str2double(erase(string(Te.EmigrationRate), {',','$',' '}));
end

% Join datasets on country-year combinations that appear in both tables
T = innerjoin(Tg, Te, "Keys", {'Country','Year'});

% Estimate parameters country-by-country
countries = unique(T.Country);
coef = containers.Map('KeyType','char','ValueType','any');
for i = 1:numel(countries)
    c = countries(i);
    Tc = T(T.Country == c, :);
    if height(Tc) >= 3        % reasonable minimal value 
        coef(char(c)) = fit_one(Tc);
    end
end

% Stima pooled for country without enough data 
x1 = log(T.GDP(:));
x2 = double(T.Year(:));
Xpooled = [ones(size(x1)) x1 x2];
b_pooled = Xpooled \ T.EmigrationRate(:);   % [a; b; g]

% Input country, year
country_in = input('Choose Country: ','s');
year_in    = input('Requested Year (es. 2010): ');

key = normalise_country(country_in);
key_char = char(key);

% GDP country/year requuest
rowGDP = Tg(Tg.Country == key & Tg.Year == year_in, :);
if isempty(rowGDP)
    error('GDP not present for country/year chosen.');
end
g = rowGDP.GDP(1);

if isKey(coef, key_char)
    b = coef(key_char);
else
    b = b_pooled;
end

% Predict
y_hat = b(1) + b(2) * log(g) + b(3) * double(year_in);
fprintf('Emigration Estimation %s in %d: %.6g (people left)\n', country_in, year_in, y_hat);

% Hold-out to evaluate predicting capacity
R = [];
for i = 1:numel(countries)
    c = countries(i);
    Tc = T(T.Country == c, :);
    if height(Tc) < 4, continue; end
    % all year without the last one to 
    Tc = sortrows(Tc,'Year');
    Tr = Tc(1:end-1,:); Te1 = Tc(end,:);
    b_c = fit_one(Tr);
    y_pred = b_c(1) + b_c(2) * log(Te1.GDP) + b_c(3) * double(Te1.Year);
    R(end+1,1) = y_pred - Te1.EmigrationRate; %#ok<SAGROW>
end
if ~isempty(R)
    rmse = sqrt(mean(R.^2));
    fprintf('RMSE holdout per-country (last year out): %.4g\n', rmse);
end

% --- Visualise ---
coef_keys = sort(keys(coef));
if isempty(coef_keys)
    warning('Country does not have sufficient data to estimate properly.');
else
    coef_values = cell2mat(values(coef, coef_keys))';
    figure;
    bar(categorical(coef_keys), coef_values, 'grouped');
    xlabel('Paesi');
    ylabel('Coefficienti di emigrazione');
    title('Coefficienti di emigrazione per Paese');
    legend({'Intercept','log(GDP)','Year'}, 'Location','best');
    grid on;
end

function beta = fit_one(Tc)
%FIT_ONE regression coeff for one country 
    x1 = log(Tc.GDP(:));
    x2 = double(Tc.Year(:));
    X  = [ones(size(x1)) x1 x2];
    y  = Tc.EmigrationRate(:);
    beta = X \ y;              % [a_c; b_c; g_c]
end
