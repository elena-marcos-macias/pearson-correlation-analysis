%% ========================================================================
% CorrelationAnalysis.m
%
% Main script for Pearson correlation analysis between two sets of variables.
%
% Workflow
% --------
% 1. Select Excel file
% 2. Select X variables
% 3. Select Y variables
% 4. Check that animal IDs match
% 5. Compute Pearson correlations and linear regressions
% 6. Save results to Excel
%
% Required functions
% ------------------
% selectData.m
% checkAnimalOrder.m
% runCorrelations.m
% saveCorrelationResults.m
%
% ========================================================================

clear
clc

fprintf('\n');
fprintf('===============================================\n');
fprintf('      Pearson Correlation Analysis Tool\n');
fprintf('===============================================\n\n');

%% ------------------------------------------------------------------------
% Add utils folder to path
% -------------------------------------------------------------------------
scriptFolder = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptFolder,'utils'));

%% ------------------------------------------------------------------------
% Select Excel file
% -------------------------------------------------------------------------

[fileName,filePath] = uigetfile( ...
    {'*.xlsx;*.xls','Excel files (*.xlsx,*.xls)'}, ...
    'Select Excel file');

if isequal(fileName,0)
    error('No Excel file selected.');
end

excelFile = fullfile(filePath,fileName);

fprintf('Excel file selected:\n%s\n\n',excelFile);

%% ------------------------------------------------------------------------
% Select X variables
% -------------------------------------------------------------------------

fprintf('-----------------------------------------------\n');
fprintf('SELECT X VARIABLES\n');
fprintf('-----------------------------------------------\n\n');

X = selectData(excelFile,'X');

%% ------------------------------------------------------------------------
% Select Y variables
% -------------------------------------------------------------------------

fprintf('\n-----------------------------------------------\n');
fprintf('SELECT Y VARIABLES\n');
fprintf('-----------------------------------------------\n\n');

Y = selectData(excelFile,'Y');

%% ------------------------------------------------------------------------
% Check IDs
% -------------------------------------------------------------------------

fprintf('\nChecking animal IDs...\n');

checkAnimalOrder(X.ID,Y.ID);

fprintf('OK\n');

%% ------------------------------------------------------------------------
% Run correlations
% -------------------------------------------------------------------------

fprintf('\nRunning correlations...\n');

results = runCorrelations(X,Y);

fprintf('Analysis completed.\n');

%% ------------------------------------------------------------------------
% Display results
% -------------------------------------------------------------------------

disp(' ');
disp('Correlation results')
disp(results)

%% ------------------------------------------------------------------------
% Save results
% -------------------------------------------------------------------------

outputFile = saveCorrelationResults(results, X, Y, excelFile, filePath);

fprintf('\nResults saved successfully.\n');

disp(' ');
disp('Results saved to Excel file.')

%% ------------------------------------------------------------------------
% Save significant correlations Excel sheets
% -------------------------------------------------------------------------
saveSignificantCorrelationSheets(results, X, Y, excelFile, outputFile);

disp(' ');
disp('|r| > 0.6 correlations saved to individual Excel sheets.')


%% ------------------------------------------------------------------------
% Plot correlation heatmap
% -------------------------------------------------------------------------
plotCorrelationHeatmap(results, filePath);

disp(' ');
disp('Heat Map saved.')