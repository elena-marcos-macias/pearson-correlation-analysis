function checkAnimalOrder(IDx, IDy)
%==========================================================================
% checkAnimalOrder.m
%
% Checks that two ID vectors are identical and in the same order.
%
% INPUT
% -----
% IDx
% IDy
%
%==========================================================================

%% Same number of animals

if numel(IDx) ~= numel(IDy)

    error('The order of the X and Y variables does not match.');

end

%% Convert to string

IDx = string(IDx);
IDy = string(IDy);

%% Compare

if ~all(IDx == IDy)

    disp(table(IDx,IDy))

    error('The order of the X and Y variables does not match.');

end

end