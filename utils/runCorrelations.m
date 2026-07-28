function results = runCorrelations(X,Y)
%==========================================================================
% runCorrelations.m
%
% Calculates Pearson correlations and linear regressions between all
% variables contained in X and Y.
%
% INPUT
% -----
% X.Data
% X.VariableNames
%
% Y.Data
% Y.VariableNames
%
% OUTPUT
% ------
% results : table
%
%==========================================================================

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

%% Sort by p-value

%results = sortrows(results, {'XVariable','r2'}, {'ascend','descend'});
%results = sortrows(results,'p','ascend');

end