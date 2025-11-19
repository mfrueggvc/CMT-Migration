clc; clear; close all

T = readtable('gdp.csv','Delimiter',';');

names = T.Properties.VariableNames;

% individua tutte le colonne che corrispondono a un anno numerico
yearCols = [];
for k = 1:numel(names)
    nk = names{k};
    if all(isstrprop(nk,'digit'))
        yearCols = [yearCols k];
    end
end

countryCol = 1;

out = {};

for r = 1:height(T)
    c = T{r,countryCol}{1};
    for k = yearCols
        y = str2double(names{k});
        v = T{r,k};
        if ~isnan(v)
            out = [out; {c, y, v}];
        end
    end
end

OUT = cell2table(out,'VariableNames',{'Country','Year','GDP'});
writetable(OUT,'GDP_long.txt','Delimiter','\t');




