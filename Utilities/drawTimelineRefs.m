function [YLimits XLimits] = drawTimelineRefs(h)
% [YLimits XLimits] = drawTimelineRefs(h)
% 
% drawTimelineRefs draws the reference lines for IOS signals in the axes
% specified by the handle h and optimize the Y and X limits for IOS data
% visualization.
% 
% INPUT
% h: handle of the axes
% 
% OUTPUT
% YLimits: Array with the new Y limits of the axes
% XLimits: Array with the new X limits of the axes
% 
% see also timeline


if ishandle(h) && isfield(get(h), 'Box') %check if h is an axes handle
    handle = h;
else
    error('Invalid handle. The specified handle is not an axes handle.')
end

% Ylimits computation
dataArray = get(handle, 'Children');
numPlots = length(dataArray); % number of datasets in the axes
if ~isempty(dataArray)
    if numPlots == 1 % if there is a single dataset
        datiX = get(dataArray, 'XData');
        datiY = get(dataArray, 'YData');
        XLimits = [min(datiX) max(datiX)];
        YLimits = [min(datiY) max(datiY)];    
    elseif numPlots > 1 % if there are more than one dataset
        XLimits = [inf -inf];
        YLimits = [inf -inf];
        for i = 1:numPlots
            datiX = get(dataArray(i), 'XData');
            if min(datiX) < XLimits(1)
                XLimits(1) = min(datiX);
            end
            if max(datiX) > XLimits(2)
                XLimits(2) = max(datiX);
            end
            datiY = get(dataArray(i), 'YData');
            if min(datiY) < YLimits(1)
                YLimits(1) = min(datiY);
            end
            if max(datiY) > YLimits(2)
                YLimits(2) = max(datiY);
            end 
        end     
    end
    % widen limits
    YLimits = YLimits+(YLimits.*.2);
else
    YLimits = get(handle,'YLim');
    XLimits = get(handle,'XLim');
end

% Plotting of the reference lines
lV = line([0 0],YLimits,'Linewidth', 1.1,'Color', 'K', 'Parent', handle);
lH = line(XLimits ,[0 0],'Linewidth', 1.1,'Color', 'K', 'Parent', handle);

% uistack(lV,'bottom');
% uistack(lH,'bottom');

% Set the new limits
set(handle, 'XLim', XLimits);
set(handle, 'YLim', YLimits);

    