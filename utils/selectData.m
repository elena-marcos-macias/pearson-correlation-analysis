function S = selectData(excelFile, axisName)
%==========================================================================
% selectData.m
%
% Selects one set of variables (X or Y) from an Excel workbook.
%
% OUTPUT
% ------
% S.ID              Animal IDs
% S.Data            Numeric matrix (animals x variables)
% S.VariableNames   Variable names
% S.Sheet           Selected sheet
% S.Experiments     Selected experiments
%
%==========================================================================

fprintf('\n');
fprintf('==============================\n');
fprintf(' Select variables for %s\n', axisName);
fprintf('==============================\n');

%% ------------------------------------------------------------------------
% Obtain sheet names
% -------------------------------------------------------------------------

[~, sheetNames] = xlsfinfo(excelFile);

if isempty(sheetNames)
    error('No sheets found in Excel file.');
end

[idx, tf] = listdlg( ...
    'PromptString', sprintf('Select sheet for %s', axisName), ...
    'SelectionMode', 'single', ...
    'ListString', sheetNames);

if ~tf
    error('No sheet selected.');
end

sheet = sheetNames{idx};

fprintf('Selected sheet: %s\n', sheet);

%% ------------------------------------------------------------------------
% Read table
% -------------------------------------------------------------------------

T = readtable(excelFile, ...
    'Sheet', sheet, ...
    'VariableNamingRule', 'preserve');

%% ------------------------------------------------------------------------
% Select ID variable
% -------------------------------------------------------------------------

varNames = string(T.Properties.VariableNames);

[idxID, tf] = listdlg( ...
    'PromptString','Select the column containing the animal IDs', ...
    'SelectionMode','single', ...
    'ListString',cellstr(varNames), ...
    'ListSize',[350 400]);

if ~tf
    error('No ID column selected.');
end

IDvariable = varNames(idxID);

fprintf('Selected ID column: %s\n',IDvariable);

%% ------------------------------------------------------------------------
% Ask whether a grouping variable should be used
% -------------------------------------------------------------------------

useGrouping = questdlg( ...
    sprintf('Do you want to use a grouping variable to filter %s data?',axisName), ...
    'Grouping variable', ...
    'Yes','No','No');

if isempty(useGrouping)
    error('Analysis cancelled by user.');
end

if strcmp(useGrouping,'Yes')

    %% ------------------------------------------------------------------
    % Select grouping variable
    % ---------------------------------------------------------------------

    [idxGroup, tf] = listdlg( ...
        'PromptString','Select the grouping variable', ...
        'SelectionMode','single', ...
        'ListString',cellstr(varNames), ...
        'ListSize',[350 400]);

    if ~tf
        error('No grouping variable selected.');
    end

    groupVariable = varNames(idxGroup);

    fprintf('Grouping variable: %s\n',groupVariable);

    %% ------------------------------------------------------------------
    % Read available categories
    % ---------------------------------------------------------------------

    groupData = T.(groupVariable);

    % Convert everything to string
    if isnumeric(groupData)

        groupData = string(groupData);

    elseif iscell(groupData)

        groupData = string(groupData);

    elseif iscategorical(groupData)

        groupData = string(groupData);

    else

        groupData = string(groupData);

    end

    categories = unique(groupData,'stable');

    categories = ["<All>"; categories];

    %% ------------------------------------------------------------------
    % Select categories
    % ---------------------------------------------------------------------

    [idxCat, tf] = listdlg( ...
        'PromptString','Select category/categories', ...
        'SelectionMode','multiple', ...
        'ListString',cellstr(categories), ...
        'ListSize',[350 400]);

    if ~tf
        error('No category selected.');
    end

    selectedCategories = categories(idxCat);

    %% ------------------------------------------------------------------
    % Filter table
    % ---------------------------------------------------------------------

    if ~ismember("<All>",selectedCategories)

        idx = ismember(groupData,selectedCategories);

        T = T(idx,:);

    end

else

    %% ------------------------------------------------------------------
    % No grouping variable -> use all rows
    % ---------------------------------------------------------------------

    groupVariable = "<None>";
    selectedCategories = "<All>";

    fprintf('No grouping variable selected. Using all animals.\n');

end

fprintf('%d animals selected.\n',height(T));

%% ------------------------------------------------------------------------
% Extract IDs
% -------------------------------------------------------------------------

ID = T.(IDvariable);

%% ------------------------------------------------------------------------
% Variables available
% -------------------------------------------------------------------------

varNames = string(T.Properties.VariableNames);

exclude = ismember(varNames,["ID","Experiment"]);

availableVariables = varNames(~exclude);

[idxVar, tf] = listdlg( ...
    'PromptString', sprintf('Select %s variable(s)',axisName), ...
    'ListString', cellstr(availableVariables), ...
    'SelectionMode','multiple', ...
    'ListSize',[350 400]);

if ~tf
    error('No variables selected.');
end

selectedVariables = availableVariables(idxVar);

%% ------------------------------------------------------------------------
% Extract data
% -------------------------------------------------------------------------

data = zeros(height(T),length(selectedVariables));

for k = 1:length(selectedVariables)

    data(:,k) = T.(selectedVariables(k));

end

%% ------------------------------------------------------------------------
% Store output
% -------------------------------------------------------------------------

S = struct;

S.ID = ID;

S.Data = data;

S.VariableNames = cellstr(selectedVariables);

S.Sheet = sheet;

S.GroupingVariable = groupVariable;

S.SelectedCategories = selectedCategories;

S.IDVariable = IDvariable;

S.GroupingVariable = groupVariable;

S.SelectedCategories = selectedCategories;

fprintf('\nVariables selected:\n');

disp(selectedVariables')

end