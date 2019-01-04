function [RORmask, RORpos, nRor] = addRor(pathToFile, newROR)

% SYNTAX
% addRor(pathToFile, newROR)
% RORmask = addRor(pathToFile, newROR)
% [RORmask, RORpos] = addRor(pathToFile, newROR)
% [RORmask, RORpos, nRor] = addRor(pathToFile, newROR)
%
% DESCRIPTION
% addRor adds a new ROI to a recording matfile specified with its full path
% name. This function can accept both masks and XY position matrices as a
% new ROI. It automatically detects which input has been given and creates
% a mask (the input is a pos) or a pos vector (if the input is a mask).
% Afterwards it add the new ROI to the matfile.
%
% INPUT
% pathToFile: a string containing the full path to a matfile;
% newROR: either a logical matrix (a 2D mask) or a XY position column matrix (nx2)
% containing the new ROR to add;
%
% OUTPUT
% RORmask: an updated nxmxp logical matrix, in each p dimension there is a
% ROI mask;
% RORpos: an updated struct containing the XY positions of each ROR (for
% redrawing);
% nRor: an updated scalar specifying the number of ROIs (same as
% size(RORmask,3));
% 
% see also: addRoi,  getRoi,  getRor
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
if islogical(newROR) && size(newROR,1)==movieSize(1) && size(newROR,2)==movieSize(2)% if the input is a mask
    whichInput = 'mask';
    newMask = newROR;
    temp = mask2poly(newROR, 'exact');
    newPos = temp(2:end,:);
elseif isnumeric(newROR) && size(newROR,2) == 2 % if the input is a position
    whichInput = 'position';
    newMask = poly2mask(newROR(:,1), newROR(:,2), movieSize(1), movieSize(2));
    newPos = newROR;
else
    error('Unable to detect the new ROI type. Masks must be logical, while pos must be 2xN matrix')
end

% update the fields in the matfile

if misField(mf,'RORmask') && mf.nRor>0 % If there are already RORs in the matfile 
    masks = mf.RORmask;
    numOfMasks = size(masks,3);
    masks(:,:,numOfMasks+1) = newMask;
    mf.RORmask = masks;
    numOfPos = size(fieldnames(mf.RORpos),1);
    pos = mf.RORpos;
    pos.(['pos' num2str(numOfPos+1)]) = newPos;
    mf.RORpos = pos;
    mf.nRor = mf.nRor+1;
else
    mf.RORmask = newMask;
    mf.RORpos = struct('pos1', newPos);
    mf.nRor = 1;
end

% Create the updated output values
RORmask = mf.RORmask;
RORpos = mf.RORpos;
nRor = mf.nRor;