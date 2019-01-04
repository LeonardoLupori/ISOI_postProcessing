function [ROImask, ROIpos, nRoi] = getRoi(pathToFile)

% ROImask = getRoi(pathToFile)
% [ROImask, ROIpos] = getRoi(pathToFile)
% [ROImask, ROIpos, nRoi] = getRoi(pathToFile)
% 
% getRoi extract the ROIs from a matfile
% 
% INPUT
% pathToFile: a string containing the full path to a matfile
% 
% OUTPUT
% ROImask: a nxmxp logical matrix, in each p dimension there is a ROI mask
% ROIpos: a struct containing the XY positions of each ROI (for redrawing)
% nRoi: a scalar specifying the number of ROIs (same as size(ROImask,3))
% 
% Leonardo Lupori 12/05/2016

if nargin < 1
    [fileName,pathName,FilterIndex] = uigetfile('.mat');
    if FilterIndex == 0
        return
    end
else
    [pathName,fileName,ext] = fileparts(pathToFile);
    pathName = [pathName '\'];
    fileName = [fileName ext];
end

mf = matfile([pathName fileName]);

if misField(mf,'ROImask')
    ROImask = mf.ROImask;
else
    error('ROImask not found in the selected file.')
end

if misField(mf,'nRoi')
    nRoi = mf.nRoi;
else
    error('nRoi not found in the selected file.')
end

if misField(mf,'ROIpos')
    ROIpos = mf.ROIpos;
else
    error('ROIpos not found in the selected file.')
end