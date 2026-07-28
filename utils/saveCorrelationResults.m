function outputFile = saveCorrelationResults(results, X, Y, excelFile, outputPath)
%==========================================================================
% saveCorrelationResults.m
%
% Saves correlation results together with all analysis settings.
%
% INPUT
% -----
% results     Table with correlation results
% X           Structure returned by selectData() for X
% Y           Structure returned by selectData() for Y
% excelFile   Original Excel file
% outputPath  Output directory
%
% OUTPUT
% ------
% outputFile  Full path of saved Excel file
%
%==========================================================================

%% Check output directory

if ~exist(outputPath,'dir')
    error('Output directory does not exist.');
end

%% Create results folder

resultsFolder = fullfile(outputPath,'CorrelationResults');

if ~exist(resultsFolder,'dir')
    mkdir(resultsFolder);
end

%% Ask for file name

answer = inputdlg( ...
    'Enter a name for the output file:', ...
    'Output file', ...
    [1 60], ...
    {'CorrelationAnalysis'});

if isempty(answer)
    error('Analysis cancelled by user.');
end

baseName = strtrim(answer{1});

if isempty(baseName)
    baseName = 'CorrelationAnalysis';
end

%% Timestamp

timestamp = datetime("now","Format","uuuuMMdd'T'HHmmss"); %datestr(now,'yyyy-mm-dd_HH-MM-SS');

fileName = sprintf('%s_%s.xlsx',baseName,timestamp);

outputFile = fullfile(resultsFolder,fileName);

%% Save correlation table

writetable(results,outputFile,'Sheet','Correlations');

%% Create settings table

Parameter = {

    'Original Excel file'
    'Date'
    'Time'

    'X Sheet'
    'X ID variable'
    'X Grouping variable'
    'X Selected categories'
    'X Variables'

    'Y Sheet'
    'Y ID variable'
    'Y Grouping variable'
    'Y Selected categories'
    'Y Variables'

    };

Value = {

    excelFile
    datestr(now,'dd-mmm-yyyy')
    datestr(now,'HH:MM:SS')

    X.Sheet
    X.IDVariable
    X.GroupingVariable
    strjoin(string(X.SelectedCategories),', ')
    strjoin(string(X.VariableNames),', ')

    Y.Sheet
    Y.IDVariable
    Y.GroupingVariable
    strjoin(string(Y.SelectedCategories),', ')
    strjoin(string(Y.VariableNames),', ')

    };

settings = table(Parameter,Value);

%% Save settings

writetable(settings,outputFile,...
    'Sheet','Settings',...
    'WriteVariableNames',true);

%% Display message

fprintf('\n');
fprintf('=========================================\n');
fprintf('Correlation analysis saved successfully.\n');
fprintf('%s\n',outputFile);
fprintf('=========================================\n');

end