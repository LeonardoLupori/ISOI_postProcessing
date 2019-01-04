function [RORmask, RORpos, nRor] = getRor(pathToFile)

% RORmask = getRor(pathToFile)
% [RORmask, RORpos] = getRor(pathToFile)
% [RORmask, RORpos, nRor] = getRor(pathToFile)
% 
% getRor extract the RORs from a matfile
% 
% INPUT
% pathToFile: a string containing the full path to a matfile
% 
% OUTPUT
% RORmask: a nxmxp logical matrix, in each p dimension there is a ROR mask
% RORpos: a struct containing the XY positions of each ROR (for redrawing)
% nRor: a scalar specifying the number of RORs (same as size(RORmask,3))
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

if misField(mf,'RORmask')
    RORmask = mf.RORmask;
else
    error('RORmask not found in the selected file.')
end

if misField(mf,'nRor')
    nRor = mf.nRor;
else
    error('nRor not found in the selected file.')
end

if misField(mf,'RORpos')
    RORpos = mf.RORpos;
else
    error('RORpos not found in the selected file.')
end