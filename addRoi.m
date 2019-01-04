function [ROImask, ROIpos, nRoi] = addRoi(pathToFile, newROI)

% SYNTAX
% addRoi(pathToFile, newROI)
% ROImask = addRoi(pathToFile, newROI)
% [ROImask, ROIpos] = addRoi(pathToFile, newROI)
% [ROImask, ROIpos, nRoi] = addRoi(pathToFile, newROI)
% 
% DESCRIPTION
% addRoi adds a new ROI to a recording matfile specified with its full path
% name. This function can accept both masks and XY position matrices as a
% new ROI. It automatically detects which input has been given and creates
% a mask (the input is a pos) or a pos vector (if the input is a mask).
% Afterwards it add the new ROI to the matfile.
%
% INPUT
% pathToFile: a string containing the full path to a matfile;
% newROI: either a logical matrix (a 2D mask) or a XY position column matrix (nx2)
% containing the new ROI to add;
%
% OUTPUT
% ROImask: an updated nxmxp logical matrix, in each p dimension there is a
% ROI mask;
% ROIpos: an updated struct containing the XY positions of each ROI (for
% redrawing);
% nRoi: an updated scalar specifying the number of ROIs (same as
% size(ROImask,3));
% 
% see also: addRor,   getRoi,   getRor
%
% Leonardo Lupori 17/05/2016

[pathName,fileName,ext] = fileparts(pathToFile);
pathName = [pathName '\'];
fileName = [fileName ext];
whichInput = [];

% Validate the filename and get X and Y resolution of the movie
mf = matfile([pathName fileName], 'Writable', true);
if misField(mf,'avgMovie')
    movieSize = [size(mf.avgMovie,1) size(mf.avgMovie,2)];
else
    error('The selected file is not a valid recording. "avgMovie" field not found.')
end

% Decide whether the input is a mask or a pos
if islogical(newROI) && size(newROI,1)==movieSize(1) && size(newROI,2)==movieSize(2)% if the input is a mask
    whichInput = 'mask';
    newMask = newROI;
    temp = mask2poly(newROI, 'exact');
    newPos = temp(2:end,:);
elseif isnumeric(newROI) && size(newROI,2) == 2 % if the input is a position
    whichInput = 'position';
    newMask = poly2mask(newROI(:,1), newROI(:,2), movieSize(1), movieSize(2));
    newPos = newROI;
else
    error('Unable to detect the new ROI type. Masks must be logical, while pos must be 2xN matrix')
end

% update the fields in the matfile

if misField(mf,'ROImask') && mf.nRoi>0 % If there are already ROIs in the matfile 
    masks = mf.ROImask;
    numOfMasks = size(masks,3);
    masks(:,:,numOfMasks+1) = newMask;
    mf.ROImask = masks;
    numOfPos = size(fieldnames(mf.ROIpos),1);
    pos = mf.ROIpos;
    pos.(['pos' num2str(numOfPos+1)]) = newPos;
    mf.ROIpos = pos;
    mf.nRoi = mf.nRoi+1;
else
    mf.ROImask = newMask;
    mf.ROIpos = struct('pos1', newPos);
    mf.nRoi = 1;
end

% Create the updated output values
ROImask = mf.ROImask;
ROIpos = mf.ROIpos;
nRoi = mf.nRoi;