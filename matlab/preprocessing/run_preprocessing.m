% run_preprocessing.m
% Master script: generates all processed CSVs inside data/processed/.

clc; clear; close all;

thisFile    = mfilename('fullpath');
preprocDir  = fileparts(thisFile);
projectRoot = fileparts(preprocDir);

rawDir       = fullfile(projectRoot, 'data', 'raw');
processedDir = fullfile(projectRoot, 'data', 'processed');

if ~exist(processedDir, 'dir')
    mkdir(processedDir);
end

addpath(preprocDir);

fprintf("=== PREPROCESSING START ===\n");
fprintf("Raw directory:       %s\n", rawDir);
fprintf("Processed directory: %s\n\n", processedDir);

fprintf("GDP...\n");
preprocess_GDP(rawDir, processedDir);

fprintf("Schooling...\n");
preprocess_Schooling(rawDir, processedDir);

fprintf("Unemployment...\n");
preprocess_Unemployment(rawDir, processedDir);

fprintf("Net Migration...\n");
preprocess_NetMigration(rawDir, processedDir);

fprintf("Homicide...\n");
preprocess_Homicide(rawDir, processedDir);

fprintf("\n=== PREPROCESSING COMPLETE ===\n");
fprintf("All cleaned datasets saved to: %s\n", processedDir);
