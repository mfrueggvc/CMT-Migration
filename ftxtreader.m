clc; clear;
clc; clear;

[fn, fp] = uigetfile({'*.pdf;*.txt', 'PDF or TXT files'}, 'Select your UN file');

if isequal(fn,0)
    error(' No file selected. Please choose a PDF or TXT file.');
end

filename = fullfile(fp, fn);
disp("✅ File selected: " + filename)
[~,~,ext]=fileparts(filename);
if strcmpi(ext,'.pdf'); txt=extractFileText(filename); else; txt=fileread(filename); end
L = splitlines(string(txt)); L = strtrim(L); L = L(~cellfun(@isempty,L));
isnum = @(s) ~isempty(regexp(s,'^\d{1,3}([ ,]\d{3})*(\.\d+)?$|^\d+(\.\d+)?$','once'));
tonum = @(s) str2double(strrep(strrep(s,' ',''),',',''));
noDigits = @(s) isempty(regexp(s,'\d','once'));
hasLetters = @(s) ~isempty(regexp(s,'[A-Za-zÀ-ÖØ-öø-ÿ]','once'));
bad = ["country or area","pays ou zone","population","surface","area","density","densité","superficie","table","tables","note","notes","source","sources","annex"];
gender = ["male","hommes","female","femmes"];
isCountry = @(s) noDigits(s) && hasLetters(s) && ~any(contains(bad,lower(s))) && ~any(contains(gender,lower(s)));
years = ["2024","2022","2015","2010"];
C=[]; Y=[]; P=[]; A=[]; D=[];
N = numel(L);
i=1;
while i<=N
    s = L(i);
    if isCountry(s)
        country = s;
        jend = min(N,i+200);
        blk = L(i+1:jend);
        idxBoth = find(contains(lower(blk), "both sexes") | contains(lower(blk),"tous les sexes"),1,'first');
        popVal = NaN; popYear = NaN;
        if ~isempty(idxBoth)
            b2 = blk(idxBoth+1:end);
            yidx=[]; ysel="";
            for y = years
                k = find(b2==y,1,'first');
                if ~isempty(k); yidx=k; ysel=y; break; end
            end
            if ~isempty(yidx)
                after = b2(yidx+1:end);
                kv = find(arrayfun(@(x)isnum(x), after),1,'first');
                if ~isempty(kv); popVal = tonum(after(kv)); popYear = str2double(ysel); end
            end
        end
        areaVal = NaN;
        ia = find(contains(lower(blk),"surface area") | contains(lower(blk),"superficie") | contains(lower(blk),"area (km"),1,'first');
        if ~isempty(ia)
            a2 = blk(ia+1:end);
            ka = find(arrayfun(@(x)isnum(x), a2),1,'first');
            if ~isempty(ka); areaVal = tonum(a2(ka)); end
        end
        densVal = NaN;
        id = find(contains(lower(blk),"density") | contains(lower(blk),"densité"),1,'first');
        if ~isempty(id)
            d2 = blk(id+1:end);
            kd = find(arrayfun(@(x)isnum(x), d2),1,'first');
            if ~isempty(kd); densVal = tonum(d2(kd)); end
        end
        if ~isempty(popYear) && ~isnan(popVal)
            C = [C; country]; Y = [Y; popYear]; P = [P; popVal]; A = [A; areaVal]; D = [D; densVal];
        end
    end
    i=i+1;
end
T = table(C, Y, P, A, D, 'VariableNames', {'Country','Year','Population','Area','Density'});
T = sortrows(unique(T,'rows'), {'Country','Year'});
writetable(T,'UN_clean_country_year_pop_area_density.xlsx');
disp(head(T,15));