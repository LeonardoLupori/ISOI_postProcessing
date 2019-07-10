function [ mask pos ]= drawRoi(ax)
% [ mask pos ]= drawRoi(ax)
%
% Allows toy to draw a free hand ROI on the axes specified by ax.
% 
% INPUT
% ax : axes handle;
% 
% OUTPUT
% mask : maschera della roi [1 dentro i pixel selezionati 0 altrimenti];
% pos : coordinate della roi [plot(pos(:,1),pos(:,2)),axis ij ricostruisce
% la roi];
%
% see also roiMovie

h = imfreehand(ax);

if ~isempty(h)
    mask = createMask(h);
    pos = getPosition(h);
else
    mask =[];
    pos =[];
end