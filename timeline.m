function T = timeline(X)

% T = timeline(X)
% 
% timeline returns a vector in which the first two dimensions of X are 
% averaged.
% If the input matrix is 4D (i.e., X contains raw data on the fourth 
% dimension), timeline returns a 2D array in which the first
% dimension represent a timeline for each raw recording.
% IMPORTANT: timeline considers the third dimension to be the time
% dimension!
% 
% INPUT
% X: a multidimensional array (3D or 4D)
% 
% OUTPUT
% T: a monodimensional array or a 2D array if the input matrix is 4D (raw data)
% 
% Leonardo Lupori 11/May/2016

if length(size(X)) < 3 || length(size(X)) > 4
    error('The input matrix is not a 3D or a 4D array.')
elseif length(size(X)) == 3
end

reshaped = reshape(X, size(X,1)*size(X,2), size(X,3), []);

if length(size(reshaped)) == 2
    T = nanmean(reshaped,1)';
elseif length(size(reshaped)) == 3
    T = nanmean(reshaped,1);
    T = reshape(T,size(T,2),size(T,3));
end

