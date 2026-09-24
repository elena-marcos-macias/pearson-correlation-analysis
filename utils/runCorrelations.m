function results = runCorrelations(X,Y,correctionOption)
%==========================================================================
% runCorrelations.m
%
% Calculates Pearson correlations and linear regressions between all
% variables contained in X and Y. Optionally applies Benjamini-Hochberg
% FDR correction for multiple comparisons.
%
% INPUT
% -----
% X.Data
% X.VariableNames
%
% Y.Data
% Y.VariableNames
%
% correctionOption : (optional) how to group correlations for FDR
%                     correction. One of:
%                       'none' (default) - no correction applied
%                       'global'         - all correlations treated as a
%                                          single family of tests
%                       'perY'           - each Y variable corrected as
%                                          an independent family
%
% OUTPUT
% ------
% results : table, with columns XVariable, YVariable, N, r, r2, p,
%           Slope, Intercept, Equation, p_adj, Significant_adj
%           (p_adj and Significant_adj are NaN/false when
%           correctionOption = 'none')
%
%==========================================================================

if nargin < 3 || isempty(correctionOption)
    correctionOption = 'none';
end

%% Number of variables

nX = size(X.Data,2);
nY = size(Y.Data,2);

%% Preallocate output

XVariable = strings(nX*nY,1);
YVariable = strings(nX*nY,1);

N  = zeros(nX*nY,1);

R  = nan(nX*nY,1);
R2 = nan(nX*nY,1);
P  = nan(nX*nY,1);

A  = nan(nX*nY,1);      % slope
B  = nan(nX*nY,1);      % intercept

Equation = strings(nX*nY,1);

row = 1;

%% Loop over all combinations

for ix = 1:nX

    x = X.Data(:,ix);

    for iy = 1:nY

        y = Y.Data(:,iy);

        %--------------------------------------------------------------
        % Remove NaN pairs
        %--------------------------------------------------------------

        idx = ~(isnan(x) | isnan(y));

        xx = x(idx);
        yy = y(idx);

        N(row) = numel(xx);

        %--------------------------------------------------------------
        % Check number of observations
        %--------------------------------------------------------------

        if numel(xx) < 3

            warning('Not enough observations for %s vs %s.', ...
                X.VariableNames{ix}, ...
                Y.VariableNames{iy});

            XVariable(row) = string(X.VariableNames{ix});
            YVariable(row) = string(Y.VariableNames{iy});

            row = row + 1;
            continue

        end

        %--------------------------------------------------------------
        % Pearson correlation
        %--------------------------------------------------------------

        [r,p] = corr(xx,yy,...
            'Type','Pearson',...
            'Rows','complete');

        %--------------------------------------------------------------
        % Linear regression
        %--------------------------------------------------------------

        mdl = fitlm(xx,yy);

        intercept = mdl.Coefficients.Estimate(1);
        slope     = mdl.Coefficients.Estimate(2);

        %--------------------------------------------------------------
        % Save results
        %--------------------------------------------------------------

        XVariable(row) = string(X.VariableNames{ix});
        YVariable(row) = string(Y.VariableNames{iy});

        R(row)  = r;
        R2(row) = r^2;
        P(row)  = p;

        A(row) = slope;
        B(row) = intercept;

        Equation(row) = sprintf( ...
            'y = %.6f*x + %.6f', ...
            slope,intercept);

        row = row + 1;

    end

end

%% Remove unused rows (safety)

valid = XVariable ~= "";

results = table( ...
    XVariable(valid), ...
    YVariable(valid), ...
    N(valid), ...
    R(valid), ...
    R2(valid), ...
    P(valid), ...
    A(valid), ...
    B(valid), ...
    Equation(valid), ...
    'VariableNames',{ ...
    'XVariable',...
    'YVariable',...
    'N',...
    'r',...
    'r2',...
    'p',...
    'Slope',...
    'Intercept',...
    'Equation'});

%% Multiple comparisons correction (FDR, Benjamini-Hochberg)
results.p_adj = nan(height(results),1);
results.Significant_adj = false(height(results),1);

switch correctionOption
    case 'none'
        % no correction applied; p_adj stays NaN

    case 'global'
        results.p_adj = benjaminiHochbergFDR(results.p);
        results.Significant_adj = results.p_adj < 0.05;

    case 'perY'
        yVars = unique(results.YVariable,'stable');
        for i = 1:numel(yVars)
            idx = results.YVariable == yVars(i);
            results.p_adj(idx) = benjaminiHochbergFDR(results.p(idx));
        end
        results.Significant_adj = results.p_adj < 0.05;

    otherwise
        warning('Unknown correctionOption "%s". No correction applied.', correctionOption);
end

%% Sort by p-value

%results = sortrows(results, {'XVariable','r2'}, {'ascend','descend'});
%results = sortrows(results,'p','ascend');

end