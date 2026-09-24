%% ========================================================================
% CorrelationAnalysis.m
%
% Main script for Pearson correlation analysis between two sets of variables.
%
% Workflow
% --------
% 1. Select Excel file
% 2. Select X variables (sheet, ID column, optional grouping filter, variables)
% 3. Select Y variables (sheet, ID column, optional grouping filter, variables)
% 4. Check that animal IDs match between X and Y
% 5. Ask whether to apply FDR correction for multiple comparisons and,
%    if so, which grouping to use (single family vs. per-Y-variable family)
%    and which p-value (raw or FDR-adjusted) to use as significance criterion
% 6. Compute Pearson correlations and linear regressions (with optional
%    FDR-adjusted p-values)
% 7. Save results and analysis settings to Excel
% 8. Save one Excel sheet per correlation with |r| > 0.6, containing the
%    raw data used (optionally split by a grouping variable)
% 9. Plot and save a correlation heatmap (cells with |r| > 0.6 annotated;
%    marked with '*' if significant by raw p, or '+' if significant by
%    FDR-adjusted p, depending on the chosen criterion)
%
% Required functions (utils/)
% ----------------------------
% selectData.m
% checkAnimalOrder.m
% runCorrelations.m
% benjaminiHochbergFDR.m
% saveCorrelationResults.m
% saveSignificantCorrelationSheets.m
% plotCorrelationHeatmap.m
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
% Multiple comparisons correction (FDR)
% -------------------------------------------------------------------------
applyFDR = questdlg( ...
    'Do you want to apply FDR correction for multiple comparisons?', ...
    'Multiple comparisons correction', ...
    'Yes','No','No');

if strcmp(applyFDR,'Yes')

    fdrChoice = questdlg( ...
        sprintf(['How do you want to group correlations for FDR correction?\n\n' ...
        'Option 1: all correlations belong to a single family of tests.\n' ...
        'Option 2: each Y variable is corrected as an independent family.']), ...
        'FDR correction method', ...
        'Option 1','Option 2','Option 1');

    if isempty(fdrChoice)
        error('Analysis cancelled by user.');
    end

    if strcmp(fdrChoice,'Option 1')
        correctionOption = 'global';
    else
        correctionOption = 'perY';
    end

    % Ask which p-value to use as the significance criterion
    significanceChoice = questdlg( ...
        sprintf(['Which p-value do you want to use to decide which correlations\n' ...
        'are significant (for the detail sheets and the heatmap asterisks)?']), ...
        'Significance criterion', ...
        'Raw p','Adjusted p (FDR)','Adjusted p (FDR)');

    if isempty(significanceChoice)
        error('Analysis cancelled by user.');
    end

    if strcmp(significanceChoice,'Raw p')
        pColumnForSignificance = 'p';
    else
        pColumnForSignificance = 'p_adj';
    end

else
    correctionOption = 'none';
    pColumnForSignificance = 'p';
end

%% ------------------------------------------------------------------------
% Run correlations
% -------------------------------------------------------------------------

fprintf('\nRunning correlations...\n');

results = runCorrelations(X,Y,correctionOption);

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

outputFile = saveCorrelationResults(results, X, Y, excelFile, filePath, correctionOption, pColumnForSignificance);

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
plotCorrelationHeatmap(results, filePath, pColumnForSignificance);

disp(' ');
disp('Heat Map saved.')