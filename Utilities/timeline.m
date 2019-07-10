function T = timeline(X,ROI)

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
% ROI: a logical mask of size (size(X,1) , size(X,2))
% 
% OUTPUT
% T: a monodimensional array or a 2D array if the input matrix is 4D (raw data)
% 
% Leonardo Lupori 11/May/2016
% Updated: Leonardo Lupori 04/Lug/2019
%           added functionality for efficiently applying ROIs

if length(size(X)) < 3 || length(size(X)) > 4
    error('The input matrix is not a 3D or a 4D array.')
elseif length(size(X)) == 3
end

% Reshape the matrix so that every image is in a single column along the
% first dimension
reshaped = reshape(X, size(X,1)*size(X,2), size(X,3), []);

if nargin<2  % Standard behavior, if there are no ROIs
    if length(size(reshaped)) == 2
        T = nanmean(reshaped,1)';
    elseif length(size(reshaped)) == 3
        T = nanmean(reshaped,1);
        T = reshape(T,size(T,2),size(T,3));
    end
else % If a ROI has been selected
    if length(size(reshaped)) == 2
        T = nanmean(reshaped(ROI(:),:),1)';
    elseif length(size(reshaped)) == 3
        T = nanmean(reshaped(ROI(:),:,:),1);
        T = reshape(T,size(T,2),size(T,3));
    end
end

