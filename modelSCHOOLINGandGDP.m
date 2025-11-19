clc; clear; clear all; 

Tg = readtable('table_gdp.csv');             % Country, Year, GDP
Ts = readtable('table_schooling.csv');       % Country, Year, SchoolYears
Tn = readtable('table_netmigration.csv');    % Country, Year, NetMigration


Tg.Country = upper(strtrim(Tg.Country));
Ts.Country = upper(strtrim(Ts.Country));
Tn.Country = upper(strtrim(Tn.Country));
