close all; clear all; clc

%% Analysis parameters and Files fetching
% This parameters are the one used in the script. The struct used in later
% parts is the Parameters struct.
% You can modify or add new parameters to the struct

defaultParameters.treshold          = 0.3;
defaultParameters.startFrame        = 16;
defaultParameters.endFrame          = 36;
defaultParameters.spatialFilter     = 7;
defaultParameters.temporalFilter    = 1;
defaultParameters.roiClosing        = 5;
defaultParameters.filter4Slope       = 5;
defaultParameters.filter4SlopeDiff   = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREFERENCE FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modify this path to point to the preferences file in your computer
prefFile = 'C:\Users\Leonardo\Documents\MATLAB\IOS\ISOI_postProcessing\preferences.mat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist('handles','var') && isfield(handles,'refineRoiFig') && ishandle(handles.refineRoiFig)
    close(handles.refineRoiFig);
end
if exist('handles','var') && isfield(handles,'generalFigure') && ishandle(handles.generalFigure)
    close(handles.generalFigure);
end
if exist('handles','var') && isfield(handles,'slopeFigure') && ishandle(handles.slopeFigure)
    close(handles.slopeFigure);
end
if exist('handles','var') && isfield(handles,'drawRorFigure') && ishandle(handles.drawRorFigure)
    close(handles.drawRorFigure);
end
if exist('handles','var') && isfield(handles,'rorFigure') && ishandle(handles.rorFigure)
    close(handles.rorFigure);
end
if exist('handles','var') && isfield(handles,'RoRslopeFigure') && ishandle(handles.RoRslopeFigure)
    close(handles.RoRslopeFigure);
end

clc;
fprintf([repmat('*',1,40) '\n IOS analysis for single-eye recordings. \n'])
fprintf([repmat('*',1,40) '\n\n']);
fprintf('Insert the analysis parameters...');
dlg_title = 'Parameters';
prompt = fieldnames(defaultParameters);
num_lines = [1, length(dlg_title)+25];
defAns = cell(numel(fieldnames(defaultParameters)),1);
for i=1:numel(fieldnames(defaultParameters))
    names = fieldnames(defaultParameters);
    defAns{i,1} = num2str(defaultParameters.(names{i}));
end
answer = inputdlg(prompt,dlg_title,num_lines,defAns,'on');
%
if ~isempty(answer)
    for i=1:numel(answer)
        names = fieldnames(defaultParameters);
        parameters.(names{i}) = str2double(answer{i});
    end
    fprintf('\tparameters accepted.\n');
else
    fprintf('\taborted\n');
    clear all
    return
end
clearvars -except parameters handles prefFile

if exist(prefFile, 'file')
    prefs = matfile(prefFile,'Writable',true);
else
    prefs = matfile(prefFile,'Writable',true);
    prefs.defPath = 'C:\';
end

% Scelta dei files da analizzare
fprintf('Select the files for analysis...')
[FileName,PathName,FilterIndex] = uigetfile(prefs.defPath,'MultiSelect','on');
if FilterIndex ~= 0
    if iscell(FileName) % more than 1 files have been selected
        for i = 1:length(FileName)
            m = matfile([PathName FileName{i}]);
            % Check if data are already readable (e.g., if dR/R has been done)
            if ~misField(m,'drorMovie')
                if i==1
                    fprintf('\n')
                end
                fprintf('\tPreprocessing... ')
                tic
                preprocComplete = ios_preprocessing([PathName FileName{i}]);
                if preprocComplete
                    fprintf(['end. [%4.2f' 's]'], toc);
                else
                    fprintf('Failed.');
                end
                if i ~= 1
                    fprintf('\n')
                end
            end
            if i == 1
                fprintf('\n')
                time = m.time;
                stimulus = m.stimulus;
                movies = zeros(size(m.drorMovie,1),size(m.drorMovie,2),...
                    size(m.drorMovie,3),length(FileName));
            else
                if m.time(1,1)~= time(1) || m.time(1,end)~= time(end)
                    error(['Mismatch in the time vector of recording: ' FileName{i}])
                end
            end
            movies(:,:,:,i) = m.drorMovie;
            fprintf(['\tFile: "' FileName{i} '" LOADED.\n'])
        end
        %         avgMovie = mean(movies,4);
    else % only 1 file has been selected
        m = matfile([PathName FileName]);
        stimulus = m.stimulus;
        time = m.time;
        movies = m.drorMovie;
        %         avgMovie = movies;
        fprintf('\n\t1 file loaded.\n')
    end
else
    %     clear all
    fprintf('aborted.\n')
    return
end
prefs.defPath = PathName;
clearvars -except parameters prefs time movies stimulus handles prefFile

% Data filtering
% movies = movies(:,1:(end/2),:,:); % Metà SINISTRA
% movies = movies(:,(end/2)+1:end,:,:); % Metà DESTRA

% Filtering in space
if parameters.spatialFilter > 1
    fprintf('Average filtering in space (%ipixels square kernel)...',parameters.spatialFilter);
    filteredMovies = zeros(size(movies));
    for i=1:size(movies,4);
        filteredMovies(:,:,:,i) = filterMovie(movies(:,:,:,i),parameters.spatialFilter);
    end
    fprintf('end.\n')
end
% Filtering in time
if parameters.temporalFilter > 1
    fprintf('Moving average filtering in time (%ipt window)...',parameters.temporalFilter);
    for i=1:size(movies,4)
        for row=1:size(movies,1)
            for col=1:size(movies,2)
                filteredMovies(row,col,:,i) = moving(squeeze(filteredMovies(row,col,:,i)), parameters.temporalFilter);
            end
        end
    end
    fprintf('end.\n')
end
% Select which 4d matrix to use for further processing
moviesToUse = filteredMovies;
avgMovieToUse = mean(moviesToUse,4);
clearvars -except parameters prefs handles time movies moviesToUse avgMovieToUse stimulus prefFile

% Preliminary plots

% Average image between the time boundaries
avgImage = mean(avgMovieToUse(:,:,parameters.startFrame:parameters.endFrame),3);
% Timelines of the whole image
timelines = timeline(moviesToUse);
% Find the ROI based on a relative threshold
mask = avgImage < imThresh(avgImage,parameters.treshold,'bottom');
closingKernel = strel('disk', parameters.roiClosing);
mask = imclose(mask,closingKernel);
% Apply the ROI to all the movies. Create new 4D matrix "roiMovies"
roiMovies = zeros(size(moviesToUse));
for i=1:size(moviesToUse,4)
    roiMovies(:,:,:,i) = roiMovie(moviesToUse(:,:,:,i),mask);
end
% Timeline of the signal inside the ROI
roiTimelines = timeline(roiMovies);
avgRoiTimeline = mean(roiTimelines,2);
% Peak amplitude inside the time boundaries
[peak,ind] = min(avgRoiTimeline(parameters.startFrame:parameters.endFrame,1));
% The first derivative of the avg timeline inside the ROI
lowPassedTimeline = moving(avgRoiTimeline,parameters.filter4Slope);
derivative = moving(diff(lowPassedTimeline),parameters.filter4SlopeDiff);
[slope, slopeInd] = min(derivative);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Manually refine ROI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the Avg image with the automatic ROI based on the threshold
if exist('handles','var') && isfield(handles,'refineRoiFig') && ishandle(handles.refineRoiFig)
    close(handles.refineRoiFig);
end
handles.refineRoiFig = figure('color',[1 1 1],'name','Refine ROI',...
    'position',[345 300 650 540]);
imagesc(avgImage);
colormap gray; axis square; axis off; colorbar(gca);
title('ROI refining');
hold on
originalMaskPath = mask2poly(mask,'exact');
plot(originalMaskPath(2:end,1),originalMaskPath(2:end,2),'linewidth',2,'color','b');
legend(['Auto ' num2str(parameters.treshold*100) '% ROI'])
hold off
% Ask the user to confirm or refine the ROI
button = '';
fprintf('Confirm the ROI... ');
isROImodified = 0; % 0: automatic ROI, 1:refined, 2:imported
while ~strcmpi(button,'yes')
    question = 'Confirm the ROI?';
    button = questdlg(question,'ROI refinment','yes','refine','import','yes');
    switch button
        case 'yes'
            fprintf('confirmed.\n');
            if exist('newMask','var')
                mask = newMask;
            end
        case 'refine'
            fprintf('draw... ');
            figure(handles.refineRoiFig);
            if exist('r','var') && ishandle(r)
                delete(r);
                hold on
                plot(originalMaskPath(2:end,1),originalMaskPath(2:end,2),'linewidth',2,'color','b');
                legend(['Auto ' num2str(parameters.treshold*100) '% ROI'])
                hold off
            end
            [userROI, ~]= drawRoi(gca);
            temp = mask-userROI;
            if max(temp(:)) == 1
                isROImodified = 1;
            end
            clear temp
            newMask = userROI & mask;
            imagesc(avgImage);
            colormap gray; axis square; axis off; colorbar(gca);
            title('ROI refining');
            hold on
            maskPath = mask2poly(newMask,'exact');
            r = plot(maskPath(2:end,1),maskPath(2:end,2),'linewidth',2,'color','g');
            legend('Manually corrected ROI');
            hold off
        case 'import' % Per importare ROI da file esterni
            DialogTitle = 'Select a file for ROI import';
            [FileName,PathName,FilterIndex] = uigetfile([prefs.defPath '*.mat'],DialogTitle);
            if FilterIndex
                m = matfile([PathName FileName]);
                temp = m.results;
                newMask = temp.ROImask;
                if exist('r','var') && ishandle(r)
                    delete(r);
                    hold on
                    plot(originalMaskPath(2:end,1),originalMaskPath(2:end,2),'linewidth',2,'color','b');
                    legend(['Auto ' num2str(parameters.treshold*100) '% ROI'])
                    hold off
                end
                imagesc(avgImage);
                colormap gray; axis square; axis off; colorbar(gca);
                title('ROI refining');
                hold on
                maskPath = mask2poly(newMask,'exact');
                r = plot(maskPath(2:end,1),maskPath(2:end,2),'linewidth',2,'color','g');
                legend('Imported ROI');
                hold off
                clear m temp
                fprintf(' ROI imported...');
                isROImodified = 2;
            end
        case ''
            fprintf('ROI confirmation aborted.\n');
            % Cancellare le variabili inutili e ripartire
            if exist('handles','var') && isfield(handles,'refineRoiFig') && ishandle(handles.refineRoiFig)
                close(handles.refineRoiFig);
            end
            return
    end
end
if exist('handles','var') && isfield(handles,'refineRoiFig') && ishandle(handles.refineRoiFig)
    close(handles.refineRoiFig);
end
clearvars originalMaskPath button question userROI newMask maskPath

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figura generale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('handles','var') && isfield(handles,'generalFigure') && ishandle(handles.generalFigure)
    close(handles.generalFigure);
end
fprintf('Generating "Overview" figure...');
handles.generalFigure = figure('color',[1 1 1],'name','Overview',...
    'Position', [10 250 860 500]);
% Average Image
subplot(2,3,1)
imagesc(avgImage)
axis off; axis square; colormap gray
title(['Avg img (' num2str(time(parameters.startFrame)) ' - '...
    num2str(time(parameters.endFrame)) ')s'])
% ROI mask by threshold
subplot(2,3,4)
imagesc(mask)
axis off; axis square; colormap gray
if isROImodified == 0
    titolo = ['Auto-ROI (' num2str(parameters.treshold*100) '%)'];
elseif isROImodified == 1
    titolo = 'Manually corrected ROI';
elseif isROImodified == 2
    titolo = 'Imported ROI';
end
title(titolo)
% Timeline plot inside the ROI
subplot(2,3,[2 3])
plot(time,roiTimelines,'linewidth',1,'color',[.7 .7 1])
hold on
plot(time,avgRoiTimeline,'linewidth',2,'color','r')
xlabel('Time [s]'); ylabel('dR/R')
hold off
[ylimits,~] = drawTimelineRefs(gca);
hold on
r = rectangle('Position',[time(parameters.startFrame),ylimits(1),...
    time(parameters.endFrame)-time(parameters.startFrame),ylimits(2)-ylimits(1)],...
    'facecolor',[0.9 1 0.9],'edgecolor',[0.9 1 0.9]);
plot(time(parameters.startFrame+ind-1),peak,'marker','s','color','k','markersize',7,'linewidth',1.7);
uistack(r,'bottom')
hold off
title('ROI timelines')
% Istogramma ampiezze
subplot(2,3,5)
amplitude = roiMovies(:,:,parameters.startFrame:parameters.endFrame,:);
amplitude = nanmean(nanmean(amplitude,3),4);
histogram(amplitude);
title('Ampl histogram'); xlabel('Amplitude dR/R')
% Plot timeline di tutta l'immagine
subplot(2,3,6)
plot(time,timelines,'linewidth',1,'color',[.6 .6 1])
hold on
plot(time,timeline(mean(moviesToUse,4)),'linewidth',2,'color','r')
xlabel('Time [s]'); ylabel('dR/R')
hold off
[ylimits, ~] = drawTimelineRefs(gca);
hold on
r = rectangle('Position',[time(parameters.startFrame),ylimits(1),...
    time(parameters.endFrame)-time(parameters.startFrame),ylimits(2)-ylimits(1)],...
    'facecolor',[0.9 1 0.9],'edgecolor',[0.9 1 0.9]);
uistack(r,'bottom')
hold off
title('Full-img timel.')
fprintf(' end.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure of the 1st derivative for the slope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('handles','var') && isfield(handles,'slopeFigure') && ishandle(handles.slopeFigure)
    close(handles.slopeFigure);
end
fprintf('Generating "Slope monitor" figure...');
handles.slopeFigure = figure('color',[1 1 1],'position',[900 345 650 420],...
    'name','ROI Slope monitor');
plot(time,lowPassedTimeline,'linewidth',1.8)
title('Response Slope')
hold on
plot(time,avgRoiTimeline,'linewidth',1.2,'color',[.1 .8 .1])
plot(time(1:end-1),derivative,'color',[1 .3 .3],'linewidth',1.5)
windowLine = 8;
try
    line([time(slopeInd-windowLine) time(slopeInd+windowLine)],...
        [lowPassedTimeline(slopeInd)-(slope*windowLine) lowPassedTimeline(slopeInd)+(slope*windowLine)],...
        'color',[0 0 0],'linewidth',.7)
catch
end
plot(time(slopeInd),slope,'color',[0 .5 0],'marker','s','linewidth',1.5)
hold off
legend('Timeline low-pass','Timeline','1st derivative','Predicted slope',...
    'location','best')
xlabel('Time [s]'); ylabel('dR/R'); grid on
fprintf('end.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STRUCT di risultati
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% results.drorMovie = avgMovieToUse;
results.fullImgTimeline = timelines;
results.roiTimeline = roiTimelines;
results.avgAmplitude = mean(mean(roiTimelines(parameters.startFrame:parameters.endFrame,:),1),2);
results.peakAmplitude = peak;
results.latency2peak = time(parameters.startFrame+ind-1);
results.avgImage = avgImage;
results.ROImask = mask;
results.area = sum(mask(:));
results.SNR = abs(peak) / mean(std(roiTimelines(1:stimulus.preStimTriggers,:),[],1));
results.slope = slope*stimulus.framerate;
results.latency2MaxSlope = time(slopeInd);

%% Analisis based on ROR
if exist('handles','var') && isfield(handles,'drawRorFigure') && ishandle(handles.drawRorFigure)
    close(handles.drawRorFigure);
end

handles.drawRorFigure = figure('color',[1 1 1],'name','ROR drawing',...
    'position',[335 161 715 585]);
imagesc(avgImage);
colormap gray; axis square; axis off;
title('Draw a Region of Reference')
fprintf('Draw a Region of Reference (RoR)...')
[RORmask, ~]= drawRoi(gca);
if sum(RORmask(:)) > 0
    fprintf(' RoR accepted.\n');
    close(handles.drawRorFigure);
else
    fprintf(' Empty ROR!\n');
    warning('You selected an empty RoR.')
end
% Apply the ROR to all the movies. Create new 4D matrix "rorMovies"
rorMovies = zeros(size(moviesToUse));
for i=1:size(moviesToUse,4)
    rorMovies(:,:,:,i) = roiMovie(moviesToUse(:,:,:,i),RORmask);
end
% Timeline of the signal inside the ROR
rorTimelines = timeline(rorMovies);
% Rereferenced Movies
temp = reshape(rorTimelines,[1 1 size(rorTimelines,1) size(rorTimelines,2)]);
rerefMovies = bsxfun(@minus,moviesToUse,temp);
% Average rereferenced image between the time boundaries
clear temp
avgRereferencedMovie = mean(rerefMovies,4);
avgRereferencedImage = mean(avgRereferencedMovie(:,:,parameters.startFrame:parameters.endFrame),3);
% Apply the ROI to all the rereferenced movies. Update old 4D matrix "rerefMovies"
for i=1:size(rerefMovies,4)
    rerefMovies(:,:,:,i) = roiMovie(rerefMovies(:,:,:,i),mask);
end
% Timelines of the ROI rereferenced
rerefTimelines = timeline(rerefMovies);
avgRerefTimeline = mean(rerefTimelines,2);
% Peak
[RORpeak,RORind] = min(avgRerefTimeline(parameters.startFrame:parameters.endFrame,1));
% The first derivative of the avg timeline inside the ROI
lowPassedRerefTimeline = moving(avgRerefTimeline,parameters.filter4Slope);
derivativeROR = moving(diff(lowPassedRerefTimeline),parameters.filter4SlopeDiff);
[slopeRoR, slopeIndRoR] = min(derivativeROR);

% Graphics
fprintf('Generating "Rereferenced Data" figure...');
if exist('handles','var') && isfield(handles,'rorFigure') && ishandle(handles.rorFigure)
    close(handles.rorFigure);
end

handles.rorFigure = figure('color',[1 1 1],'name','Rereferenced processing',...
    'position',[5 210 860 500]);
% Image with ROI and ROR
subplot(2,3,1)
imagesc(avgRereferencedImage)
axis off; axis square; colormap gray
title(['Avg reref img (' num2str(time(parameters.startFrame)) ' - '...
    num2str(time(parameters.endFrame)) ')s'])
tempROI = mask2poly(mask,'exact');
tempROR = mask2poly(RORmask,'exact');
hold on
plot(tempROI(2:end,1),tempROI(2:end,2),'linewidth',1.6,'color','b');
plot(tempROR(2:end,1),tempROR(2:end,2),'linewidth',1.6,'color','g');
hold off
legend('ROI','ROR')
% Plot of ROI-ROR timeline
subplot(2,3,[2 3])
plot(time,rerefTimelines,'linewidth',1,'color',[.7 .7 1])
hold on
plot(time,avgRerefTimeline,'linewidth',2,'color','r')
xlabel('Time [s]'); ylabel('dR/R')
hold off
[ylimits,~] = drawTimelineRefs(gca);
hold on
r = rectangle('Position',[time(parameters.startFrame),ylimits(1),...
    time(parameters.endFrame)-time(parameters.startFrame),ylimits(2)-ylimits(1)],...
    'facecolor',[0.9 1 0.9],'edgecolor',[0.9 1 0.9]);
plot(time(parameters.startFrame+RORind-1),RORpeak,'marker','s','color','k','markersize',7,'linewidth',1.7);
uistack(r,'bottom')
hold off
title('ROI-ROR timelines')
% Timeline of the ROI
subplot(2,3,4)
plot(time,roiTimelines,'linewidth',1,'color',[.7 .7 1])
hold on
plot(time,avgRoiTimeline,'linewidth',1.6,'color','b')
xlabel('Time [s]'); ylabel('dR/R')
hold off
[ylimits,~] = drawTimelineRefs(gca);
hold on
r = rectangle('Position',[time(parameters.startFrame),ylimits(1),...
    time(parameters.endFrame)-time(parameters.startFrame),ylimits(2)-ylimits(1)],...
    'facecolor',[0.9 1 0.9],'edgecolor',[0.9 1 0.9]);
plot(time(parameters.startFrame+ind-1),peak,'marker','s','color','k','markersize',7,'linewidth',1.7);
uistack(r,'bottom')
hold off
title('ROI timelines')
% Timeline of the ROR
subplot(2,3,5)
plot(time,rorTimelines,'linewidth',1,'color',[.7 .7 1])
hold on
plot(time,mean(rorTimelines,2),'linewidth',1.6,'color','g')
xlabel('Time [s]'); ylabel('dR/R')
hold off
[ylimits,~] = drawTimelineRefs(gca);
hold on
r = rectangle('Position',[time(parameters.startFrame),ylimits(1),...
    time(parameters.endFrame)-time(parameters.startFrame),ylimits(2)-ylimits(1)],...
    'facecolor',[0.9 1 0.9],'edgecolor',[0.9 1 0.9]);
uistack(r,'bottom')
hold off
title('ROR timelines')
fprintf(' end.\n');
% Table of results
subplot(2,3,6)
dat = {'Avg ampl',mean(avgRoiTimeline(parameters.startFrame:parameters.endFrame)), mean(avgRerefTimeline(parameters.startFrame:parameters.endFrame));...
    'Peak ampl',peak,RORpeak;...
    'Latency',time(parameters.startFrame+ind-1),time(parameters.startFrame+RORind-1);...
    'Slope',slope*stimulus.framerate,slopeRoR*stimulus.framerate};
t = uitable(handles.rorFigure,'Data',dat);
plot(3);
pos = get(subplot(2,3,6),'position');
delete(subplot(2,3,6))
set(t,'units','normalized','position',pos,'rowName',[],'ColumnName',{'Parameter','ROI','ROI-ROR'})
jScroll = findjobj(t);
jTable  = jScroll.getViewport.getView;
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure of the 1st derivative for the slope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting
if exist('handles','var') && isfield(handles,'RoRslopeFigure') && ishandle(handles.RoRslopeFigure)
    close(handles.RoRslopeFigure);
end
fprintf('Generating "Rereferenced Slope monitor" figure...');
handles.RoRslopeFigure = figure('color',[1 1 1],'position',[875 300 650 420],... 
    'name','Rereferenced Slope monitor');
plot(time,lowPassedRerefTimeline,'linewidth',1.8)
title('Rereferenced Response Slope')
hold on
plot(time,avgRerefTimeline,'linewidth',1.2,'color',[.1 .8 .1])
plot(time(1:end-1),derivativeROR,'color',[1 .3 .3],'linewidth',1.5)
windowLine = 8;
try
line([time(slopeIndRoR-windowLine) time(slopeIndRoR+windowLine)],...
    [lowPassedRerefTimeline(slopeIndRoR)-(slopeRoR*windowLine) lowPassedRerefTimeline(slopeIndRoR)+(slopeRoR*windowLine)],...
    'color',[0 0 0],'linewidth',.7)
catch ME
end
plot(time(slopeIndRoR),slopeRoR,'color',[0 .5 0],'marker','s','linewidth',1.5)
hold off
legend('Timeline low-pass','Timeline','1st derivative','Predicted slope',...
    'location','best')
xlabel('Time [s]'); ylabel('dR/R'); grid on
fprintf('end.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put all the calculations in a result structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% resultsROR.rereferencedMovie = avgRereferencedMovie;
resultsROR.fullImgTimeline = timelines;
resultsROR.rereferencedTimeline = rerefTimelines;
resultsROR.roiTimeline = roiTimelines;
resultsROR.rorTimeline = rorTimelines;
resultsROR.avgAmplitude = mean(mean(rerefTimelines(parameters.startFrame:parameters.endFrame,:),1),2);
resultsROR.peakAmplitude = RORpeak;
resultsROR.latency2peak = time(parameters.startFrame+RORind-1);
resultsROR.avgImage = avgImage;
resultsROR.avgRereferencedImage = avgRereferencedImage;
resultsROR.ROImask = mask;
resultsROR.RORmask = RORmask;
resultsROR.ROIarea = sum(mask(:));
resultsROR.RORarea = sum(RORmask(:));
resultsROR.SNR = abs(RORpeak) / mean(std(rerefTimelines(1:stimulus.preStimTriggers,:),[],1));
resultsROR.slope = slopeRoR*stimulus.framerate;
resultsROR.latency2MaxSlope = time(slopeIndRoR);

%% Informations and Save the analysis
clearvars -except parameters prefs handles results resultsROR prefFile

% Try to find default informations
info.dateOfAnalysis = datestr(now,'yyyy-mm-dd_HH-MM-SS');
pathParts = strsplit(prefs.defPath,'\');
temp = strsplit(pathParts{end-1},'_');
if numel(temp{1}) == 3
    info.miceNumber = [];
    info.miceLabel = temp{1};
else
    info.miceNumber = temp{1};
    info.miceLabel = [];
end
temp = strsplit(pathParts{end-2},'_');
info.miceCage = temp{end};

% Autocomplete info fields based on the previous analysis (infos stored on hdd)
m = matfile(prefFile,'Writable',true);
if misField(m,'defInfo') && isfield(m.defInfo,'genotype')
    temp = m.defInfo;
    info.genotype = temp.genotype;
else
    info.genotype = [];
end
if misField(m,'defInfo') && isfield(m.defInfo,'eye')
    temp = m.defInfo;
    info.eye = temp.eye;
else
    info.eye = [];
end
if misField(m,'defInfo') && isfield(m.defInfo,'treatment')
    temp = m.defInfo;
    info.treatment = temp.treatment;
else
    info.treatment = [];
end
if misField(m,'defInfo') && isfield(m.defInfo,'group')
    temp = m.defInfo;
    info.group = temp.group;
else
    info.group = [];
end
if misField(m,'defInfo') && isfield(m.defInfo,'timepoint')
    temp = m.defInfo;
    info.timepoint = temp.timepoint;
else
    info.timepoint = [];
end
if misField(m,'defInfo') && isfield(m.defInfo,'comments')
    temp = m.defInfo;
    info.comments = temp.comments;
else
    info.comments = [];
end

% Let the user edit the informations before saving
fprintf('Insert recording infos...');
dlg_title = 'infos';
prompt = fieldnames(info);
num_lines = [1, length(dlg_title)+25];
defAns = cell(numel(fieldnames(info)),1);
for i=1:numel(fieldnames(info))
    names = fieldnames(info);
    defAns{i,1} = num2str(info.(names{i}));
end
answer = inputdlg(prompt,dlg_title,num_lines,defAns,'on');
% Put the edited information in the info structure
if ~isempty(answer)
    for i=1:numel(answer)
        names = fieldnames(info);
        if strcmpi(names{i},'miceNumber')
            if ~isempty(answer{i})
                info.(names{i}) = str2double(answer{i});
            else
                info.(names{i}) = [];
            end
        else
            if isempty(answer{i})
                info.(names{i}) = '';
            else
                info.(names{i}) = answer{i};
            end
        end
    end
    m.defInfo = info;
    fprintf('\tinfos accepted.\n');
else
    %     Empty the struct except date if user presses cancel
    fprintf('\taborted. Default infos have been used.\n');
    for i = 1:length(fieldnames(info))
        names = fieldnames(info);
        if strcmpi(names{i},'dateOfAnalysis')
            continue
        else
            info.(names{i}) = '';
        end
    end
end

clearvars -except parameters prefs handles results resultsROR info prefFile

varsToSave = {'info', 'parameters', 'results', 'resultsROR'};

temp = strrep(info.dateOfAnalysis,'-','');
temp = strrep(temp,'_','-');
% temp = strsplit(temp,'_');
% temp = temp{1};
path = [prefs.defPath 'analysis_' temp];
if ~isempty(info.miceNumber)
    path = [path '_' num2str(info.miceNumber)];
    if ~isempty(info.miceCage)
        path = [path '-' info.miceCage];
    end
end
if ~isempty(info.eye)
    path = [path '_' info.eye];
end
path = [path '.mat'];

uisave(varsToSave,path)
