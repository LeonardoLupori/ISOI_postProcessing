function absoluteThreshold = imThresh(X, relativeThreshold, mode)

% absoluteThreshold = imTresh(X, relativeThreshold, mode)
% 
% Generate an absolute treshold value froma a percentual relative value
% INPUT
% X: A numerical array
% relativeTreshold: a number between 0 and 1
% mode: a string. 
%   'bottom' (default) calculate the threshold from the negative peak value.
%   'top' calculate the threshold from the positive peak value.

if nargin < 2
    mode = 'bottom';
end
minimo = min(X(:));
massimo = max(X(:));
range = massimo - minimo;
if strcmpi(mode,'bottom')
    absoluteThreshold = minimo + range*relativeThreshold;
elseif strcmpi(mode,'top')
    absoluteThreshold = massimo - range*relativeThreshold;
end
