function pAdj = benjaminiHochbergFDR(pValues)
%==========================================================================
% benjaminiHochbergFDR.m
%
% Computes Benjamini-Hochberg FDR-adjusted p-values.
% NaN p-values (e.g. correlations that could not be computed) are ignored
% and returned as NaN.
%
% INPUT
% -----
% pValues : vector of p-values
%
% OUTPUT
% ------
% pAdj    : vector of FDR-adjusted p-values (same size as pValues)
%
%==========================================================================
pAdj = nan(size(pValues));

valid = ~isnan(pValues);
p = pValues(valid);
m = numel(p);

if m == 0
    return
end

[pSorted, sortIdx] = sort(p);

rank = (1:m)';
pAdjSorted = pSorted .* m ./ rank;

% Enforce monotonicity (cumulative minimum from the largest p-value backward)
for i = m-1:-1:1
    pAdjSorted(i) = min(pAdjSorted(i), pAdjSorted(i+1));
end

% Cap at 1
pAdjSorted = min(pAdjSorted,1);

% Restore original order
pAdjValid = nan(m,1);
pAdjValid(sortIdx) = pAdjSorted;

pAdj(valid) = pAdjValid;

end