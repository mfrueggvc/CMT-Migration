clc; clear; clear all; 

Tg = readtable('gdp.csv');             % Country, Year, GDP
Ts = readtable('table_schooling.csv');       % Country, Year, SchoolYears
Tn = readtable('table_netmigration.csv');    % Country, Year, NetMigration


Tg.Country = upper(strtrim(Tg.Country));
varYears = Tg.Properties.VariableNames(2:end);
Y = stack(Tg, varYears, ...
            'NewDataVariableName','GDP', ...
            'IndexVariableName','Year');

Y.Year = str2double(Y.Year);
Ts.Country = upper(strtrim(Ts.Country));
Tn.Country = upper(strtrim(Tn.Country));

T = innerjoin(innerjoin(Tg, Ts, 'Keys', {'Country','Year'}), Tn, 'Keys', {'Country','Year'});

T.GDPn = normalize(T.GDP);
T.Schooln = normalize(T.SchoolYears);

Ttrain = T(T.Year <= 2005, :); 
Tpred  = T(T.Year > 2005, :);

Xtrain = [ones(height(Ttrain),1), Ttrain.GDPn, Ttrain.Schooln];
ytrain = Ttrain.NetMigration;
b = Xtrain \ ytrain;  

Tout = [Ttrain; Tpred];
writetable(Tout, 'net_migration_predictions.csv');

disp('Coefficienti stimati:');
disp(b);

OUT = Tpred(:, {'Country','Year','PredictedNetMigration'});
writetable(OUT, 'predicted_netmigration.csv');