
clc; clear;

filename = 'SYB67_1_202411_Population, Surface Area and Density.txt';
rawText = fileread();

expr = '(?<Country>[A-Z][A-Za-z\s\.\-\(\)éèëêïîàç\'']+)\s+(?<Year>\d{4})\s+(?<Total>\d+\.\d+)';

tokens = regexp(rawText, expr, 'names');

% 3️⃣ Converte in tabella MATLAB
T = struct2table(tokens);

% 4️⃣ Conversione tipi di dato
T.Year = str2double(T.Year);
T.Total = str2double(T.Total);

% 5️⃣ Rimuove duplicati e ordina alfabeticamente
T = unique(T, 'rows');
T = sortrows(T, {'Country','Year'});

% 6️⃣ Mostra un'anteprima
disp('Prime righe della tabella estratta:');
disp(T(1:15,:));

% 7️⃣ (Opzionale) Salva in Excel per controllare
writetable(T, 'UN_Population_Simplified.xlsx');
disp('✅ Dati salvati in UN_Population_Simplified.xlsx');
