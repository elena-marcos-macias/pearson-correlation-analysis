function saveSignificantCorrelationSheets(results, X, Y, excelFile, outputFile)
%==========================================================================
% saveSignificantCorrelationSheets.m
%
% Adds one sheet per correlation with |r| > 0.6 to an existing Excel file,
% containing the raw data used to compute that specific correlation.
% Optionally, splits the Y variable values into separate columns according
% to a grouping variable (e.g. Sex), for plotting purposes. Only categories
% actually present among the animals used in each correlation are added
% as columns.
%
% INPUT
% -----
% results    : table returned by runCorrelations.m
% X          : structure returned by selectData() for X
% Y          : structure returned by selectData() for Y
% excelFile  : original Excel file (same one used in selectData.m), used
%              to look up the grouping variable if requested
% outputFile : full path to the Excel file where sheets will be added
%              (e.g. the outputFile returned by saveCorrelationResults.m)
%
% Sheet layout
% ------------
% Column 1       : Animal ID           (header empty)
% Column 2       : X variable values   (header = X variable name)
% Column 3       : Y variable values   (header = Y variable name)
% Column 4+      : Y variable values split by grouping category
%                  (only categories present among the animals in THIS sheet)
%
%==========================================================================
%% Check inputs
if ~exist(outputFile,'file')
    error('Excel file not found: %s', outputFile);
end

%% Check IDs are aligned between X and Y
if numel(X.ID) ~= numel(Y.ID)
    warning(['X.ID and Y.ID have different lengths. Sheets will be ' ...
        'generated using X.ID; please verify animal alignment.']);
end

%% Select rows with |r| > 0.6
sigRows = find(abs(results.r) > 0.6);

if isempty(sigRows)
    fprintf('No correlations with |r| > 0.6 found. No sheets added.\n');
    return
end

%% ------------------------------------------------------------------------
% Ask ONCE whether a grouping variable should be used for plotting
% -------------------------------------------------------------------------
useGrouping = questdlg( ...
    'Do you want to use a grouping variable for plotting purposes?', ...
    'Grouping variable', ...
    'Yes','No','No');

if isempty(useGrouping)
    error('Analysis cancelled by user.');
end

groupID = [];
groupCategoryData = [];

if strcmp(useGrouping,'Yes')

    %% Select sheet (from the SAME excelFile used in selectData)
    [~, sheetNames] = xlsfinfo(excelFile);
    if isempty(sheetNames)
        error('No sheets found in Excel file.');
    end

    [idxSheet, tf] = listdlg( ...
        'PromptString','Select the sheet containing the grouping variable', ...
        'SelectionMode','single', ...
        'ListString',sheetNames);
    if ~tf
        error('No sheet selected.');
    end
    groupSheet = sheetNames{idxSheet};

    %% Read sheet
    Tgroup = readtable(excelFile, ...
        'Sheet', groupSheet, ...
        'VariableNamingRule', 'preserve');

    groupVarNames = string(Tgroup.Properties.VariableNames);

    %% Select ID column
    [idxID, tf] = listdlg( ...
        'PromptString','Select the column containing the animal IDs', ...
        'SelectionMode','single', ...
        'ListString',cellstr(groupVarNames), ...
        'ListSize',[350 400]);
    if ~tf
        error('No ID column selected.');
    end
    groupIDName = groupVarNames(idxID);

    %% Select grouping variable column
    [idxGroupVar, tf] = listdlg( ...
        'PromptString','Select the grouping variable', ...
        'SelectionMode','single', ...
        'ListString',cellstr(groupVarNames), ...
        'ListSize',[350 400]);
    if ~tf
        error('No grouping variable selected.');
    end
    groupVarName = groupVarNames(idxGroupVar);

    %% Extract ID and category data as strings (for robust matching)
    groupID = string(Tgroup.(groupIDName));
    groupCategoryData = string(Tgroup.(groupVarName));

    fprintf('Grouping variable selected: %s\n', groupVarName);

end

%% ------------------------------------------------------------------------
% Loop over significant correlations
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=========================================\n');
fprintf('Adding sheets for %d correlation(s) with |r| > 0.6\n', numel(sigRows));
fprintf('=========================================\n');

for k = 1:numel(sigRows)

    row = sigRows(k);

    xVarName = results.XVariable{row};
    yVarName = results.YVariable{row};

    %% Locate corresponding columns in X.Data / Y.Data
    ixCol = find(strcmp(X.VariableNames, xVarName),1);
    iyCol = find(strcmp(Y.VariableNames, yVarName),1);

    if isempty(ixCol) || isempty(iyCol)
        warning('Could not locate data for %s vs %s. Skipping.', ...
            xVarName, yVarName);
        continue
    end

    xData = X.Data(:,ixCol);
    yData = Y.Data(:,iyCol);
    animalID = X.ID;

    %% Keep only animals actually used in the correlation (remove NaN pairs)
    idx = ~(isnan(xData) | isnan(yData));

    animalID = animalID(idx);
    xData    = xData(idx);
    yData    = yData(idx);

    %% Build base table for this sheet
    IDColumnName = ' ';   % empty-looking header

    % If X and Y share the same variable name, make the column headers
    % unique (e.g. "mPFC_r_X" / "mPFC_r_Y") so table() does not error out.
    xColName = xVarName;
    yColName = yVarName;
    if strcmp(xColName, yColName)
        xColName = sprintf('%s_X', xVarName);
        yColName = sprintf('%s_Y', yVarName);
    end

    T = table(animalID, xData, yData, ...
        'VariableNames', {IDColumnName, xColName, yColName});

    %% Add grouping columns if requested
    if strcmp(useGrouping,'Yes')

        animalIDstr = string(animalID);

        %% Find each animal's category (only among animals in THIS sheet)
        animalCategory = strings(numel(animalIDstr),1);
        for a = 1:numel(animalIDstr)
            matchIdx = find(groupID == animalIDstr(a),1);
            if ~isempty(matchIdx)
                animalCategory(a) = groupCategoryData(matchIdx);
            end
        end

        %% Categories actually present among THESE animals only
        presentCategories = unique(animalCategory,'stable');
        presentCategories = presentCategories(presentCategories ~= "" & ~ismissing(presentCategories));

        if numel(presentCategories) < 2
            warning(['Fewer than 2 categories found among the animals used in ' ...
                '%s vs %s. Grouping columns not added for this sheet.'], ...
                xVarName, yVarName);
        else

            for c = 1:numel(presentCategories)

                thisCategory = presentCategories(c);
                colValues = nan(numel(animalID),1);

                matchAnimals = (animalCategory == thisCategory);
                colValues(matchAnimals) = yData(matchAnimals);

                % Sanitize category name for use as a valid table variable name
                colName = matlab.lang.makeValidName(thisCategory);

                T.(colName) = colValues;

            end

        end

    end

    %% Build sheet name (sanitized and truncated to Excel's 31-char limit)
    sheetName = sprintf('%s_&_%s', xVarName, yVarName);
    sheetName = regexprep(sheetName,'[\\/?*\[\]:]','_');
    if strlength(sheetName) > 31
        sheetName = extractBefore(sheetName,32);
    end

    %% Write sheet
    writetable(T, outputFile, 'Sheet', sheetName);

    fprintf('  Sheet added: %s\n', sheetName);

end

fprintf('=========================================\n');

end