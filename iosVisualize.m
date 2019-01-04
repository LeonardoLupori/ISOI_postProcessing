function varargout = iosVisualize(varargin)
% SYNTAX
% iosVisualize
% iosVisualize(path,filename)
% 
% DESCRIPTION
% iosVisualize is a simple GUI for visualization of IOS data. If called
% without arguments, it lets you browse for a matfile to visualize.
% path: a string
% filename: a string
%  
% See also: timeline

% Last Modified by GUIDE v2.5 19-Jan-2016 14:53:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iosVisualize_OpeningFcn, ...
                   'gui_OutputFcn',  @iosVisualize_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before iosVisualize is made visible.
function iosVisualize_OpeningFcn(hObject, eventdata, handles, varargin)
if ~isempty(varargin)
    handles.filePath = varargin{1}{1};
    handles.fileName = varargin{2}{1};
else
    if exist('iosPostprocessing_preferences.mat', 'file')
        m = matfile('iosPostprocessing_preferences','Writable',true);
    else
        createPreferences()
        m = matfile('iosPostprocessing_preferences','Writable',true);
    end
    FilterSpec = [m.defaultPath '*.mat'];
    DialogTitle = 'Choose an IOS recording';
    [FileName,PathName,FilterIndex] = uigetfile(FilterSpec,DialogTitle);
    if FilterIndex ~= 0
        handles.filePath = PathName;
        handles.fileName = FileName;
        m.defaultPath = PathName;
        % Check if is a valid ios recording matfile
        mFile = matfile([handles.filePath handles.fileName],'Writable', true);
        isValid = misField(mFile,'avgMovie') && misField(mFile,'stimulus')  && misField(mFile,'repetitions');
        if ~isValid
            fprintf('Selected file is not a recording. \n')
            handles.closeNow = 1;
        end
    else
        handles.closeNow = 1;
    end  
end
% Choose default command line output for iosVisualize
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = iosVisualize_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% preprocessamento
handles = guidata(hObject);
if isfield(handles, 'closeNow') && handles.closeNow == 1
    figure1_CloseRequestFcn(hObject, eventdata, handles)
else
    statusBar(handles.statusBar,'processing...',[1 1 .7])
    preprocessingVisualize(hObject);
    handles = guidata(hObject);
    if misField(handles.matfile, 'filtSize')
        handles.filtMovie = filterMovie(handles.drorMovie,handles.matfile.filtSize);
    else
        handles.filtMovie = filterMovie(handles.drorMovie,str2double(get(handles.edtSpaceFilter,'String')));
    end
    guidata(hObject, handles);
    updateGraphicsTimeline(hObject)
    updateGraphicsTimeBounds(hObject)
    updateGraphicsAvgImage(hObject)
    statusBar(handles.statusBar)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% MAIN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in btnRefresh.
function btnRefresh_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
if exist('iosPostprocessing_preferences.mat', 'file')
    m = matfile('iosPostprocessing_preferences','Writable',true);
else
    createPreferences()
    m = matfile('iosPostprocessing_preferences','Writable',true);
end

if ~isempty(m.currentFile) %&& ~strcmp(m.currentFile, [handles.filePath handles.fileName])
    [path,name,est] = fileparts(m.currentFile);
    handles.filePath = [path '\'];
    handles.fileName = [name est];
    guidata(hObject, handles);
    statusBar(handles.statusBar,'processing...',[1 1 .7])
    preprocessingVisualize(hObject);
    handles = guidata(hObject);
    handles.filtMovie = filterMovie(handles.drorMovie,str2double(get(handles.edtSpaceFilter,'String')));
    guidata(hObject, handles);
    updateGraphicsTimeline(hObject)
    updateGraphicsTimeBounds(hObject)
    updateGraphicsAvgImage(hObject)
    statusBar(handles.statusBar)
end

function edtSpaceFilter_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
filter = str2double(get(handles.edtSpaceFilter,'String'));
statusBar(handles.statusBar,'Filtering and processing...',[1 1 .7])
handles.filtMovie = filterMovie(handles.drorMovie,filter);
handles.matfile.filtSize = filter;
guidata(hObject, handles);
updateGraphicsTimeline(hObject)
updateGraphicsTimeBounds(hObject)
updateGraphicsAvgImage(hObject)
statusBar(handles.statusBar)
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edtSpaceFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtSpaceFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtTimeFilter_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'Filtering and processing...',[1 1 .7])
updateGraphicsTimeline(hObject)
statusBar(handles.statusBar)

% --- Executes during object creation, after setting all properties.
function edtTimeFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtTimeFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popFrom.
function popFrom_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
handles.matfile.avgStart = get(hObject,'value');
updateGraphicsTimeBounds(hObject)
updateGraphicsAvgImage(hObject)
statusBar(handles.statusBar)
% --- Executes during object creation, after setting all properties.
function popFrom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popFrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popTo.
function popTo_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
handles.matfile.avgEnd = get(hObject,'value');
updateGraphicsTimeBounds(hObject)
updateGraphicsAvgImage(hObject)
statusBar(handles.statusBar)
% --- Executes during object creation, after setting all properties.
function popTo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% EXPORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in btnExportTimeline.
function btnExportTimeline_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
FilterSpec = '*.mat';
DialogTitle = 'Save Timeline matfile';
defaultPath = handles.filePath;
[~,name,~] = fileparts(handles.fileName); % remove extension from filename
defaultName = [name '_timeline'];
[FileName,PathName,FilterIndex] = uiputfile(FilterSpec,DialogTitle,[defaultPath filesep defaultName]);
if FilterIndex ~= 0
    matObj = matfile([PathName FileName], 'Writable', true);
    fileExist = misField([PathName FileName], 'roi');
    if fileExist
        delete([PathName FileName]);
    end
    timeFilter = str2double(get(handles.edtTimeFilter,'String'));
    roi = get(handles.popRoi,'value')-1;
    if roi % if the roi is different from "full image"
        roiMaschere = handles.matfile.ROImask;
        matObj.roi = moving(timeline(roiMovie(handles.filtMovie,roiMaschere(:,:,roi))),timeFilter);
        fprintf('Timeline of the selected roi')
    else
        matObj.roi = moving(timeline(handles.filtMovie),timeFilter);
        fprintf('Timeline of the full image')
    end
    
    ror = get(handles.popRor,'value')-1;
    if ror % if the ror is different from "none"
        rorMaschere = handles.matfile.RORmask;
        matObj.ror = moving(timeline(roiMovie(handles.filtMovie,rorMaschere(:,:,ror))),timeFilter);
        matObj.RoiMinusRor = matObj.roi-matObj.ror;
        fprintf(', ror,')
    end
    matObj.time = handles.time;
    fprintf(' and "time" variable saved. \n')
end
statusBar(handles.statusBar)

% --- Executes on button press in btnExportImage.
function btnExportImage_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
FilterSpec = '*.mat';
DialogTitle = 'Save Image matfile';
defaultPath = handles.filePath;
[~,name,~] = fileparts(handles.fileName); % remove extension from filename
defaultName = [name '_iosImage'];
[FileName,PathName,FilterIndex] = uiputfile(FilterSpec,DialogTitle,[defaultPath filesep defaultName]);
if FilterIndex ~= 0
    matObj = matfile([PathName FileName], 'Writable', true);
    fileExist = misField([PathName FileName], 'image');
    if fileExist
        delete([PathName FileName]);
    end
    avgStart = get(handles.popFrom,'Value');
    avgEnd = get(handles.popTo,'Value');
    matObj.image = nanmean(handles.filtMovie(:,:,avgStart:avgEnd),3);
    fprintf('Average Image')
    roi = get(handles.popRoi,'value')-1;
    if roi % if the roi is different from "full image"
        positions = handles.matfile.ROIpos;
        masks = handles.matfile.ROImask;
        matObj.ROIpos =  positions.(['pos' num2str(roi)]);
        matObj.ROImask = masks(:,:,roi);
        fprintf(' and current ROI')
    end
    
    ror = get(handles.popRor,'value')-1;
    if ror % if the ror is different from "none"
        positions = handles.matfile.RORpos;
        masksRor = handles.matfile.RORmask;
        matObj.RORpos =  positions.(['pos' num2str(ror)]);
        matObj.RORmask = masksRor(:,:,ror);
        
        
        rorTimeline = timeline(roiMovie(handles.filtMovie,masksRor));
        size1 = size(handles.filtMovie,1);
        size2 = size(handles.filtMovie,2);
        rerefMovie = handles.filtMovie - (repmat(reshape(rorTimeline,1,1,[]),[size1 size2 1]));
        matObj.rereferencedImage = nanmean(rerefMovie(:,:,avgStart:avgEnd),3);
        fprintf(' and ROR')
    end
    fprintf(' saved. \n')
end
statusBar(handles.statusBar)

% --- Executes on button press in btnExportStat.
function btnExportStat_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
% Shutter position
if misField(handles.matfile, 'shutter')
    expStat.shutter = handles.matfile.shutter;
else
    expStat.shutter = 'UNKNOWN';
end
% Peak amplitude and latency
format shortE
avgStart = get(handles.popFrom,'Value');
avgEnd = get(handles.popTo,'Value');
[expStat.peakROI ind] = min(handles.roidata(avgStart:avgEnd));
%expStat.latencyROI = handles.matfile.time(1,ind);
if get(handles.popRor,'value')-1 && isfield(handles,'rordata')
roiror = handles.roidata-handles.rordata;
[expStat.peakROI_minus_ROR ind] = min(roiror(avgStart:avgEnd));
end
expStat.peak_To_Peak = handles.roidata(avgStart)-expStat.peakROI;
expStat.avgROI = mean(handles.roidata(avgStart:avgEnd));
if get(handles.popRor,'value')-1 && isfield(handles,'rordata')
expStat.avgROI_minus_ROR = mean(roiror(avgStart:avgEnd));
%expStat.latencyROIminusROR = handles.matfile.time(1,ind);
end
% Area
roi = get(handles.popRoi,'value')-1;
if roi
    MaschereRoi = handles.matfile.ROImask;
    roiPixels = sum(sum(MaschereRoi(:,:,roi)));
    expStat.areaROI = (roiPixels*16)/1e6; % area in mm^2
else
    expStat.areaROI = 'Full Image';
end
ror = get(handles.popRor,'value')-1;
if ror
    MaschereRor = handles.matfile.RORmask;
    rorPixels = sum(sum(MaschereRor(:,:,ror)));
    expStat.areaROR = (rorPixels*16)/1e6; % area in mm^2
end
statSummary(expStat,[handles.filePath handles.fileName]);
format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% ROI and ROR  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in popRor.
function popRor_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
updateGraphicsTimeline(hObject)
updateGraphicsTimeBounds(hObject)
updateGraphicsAvgImage(hObject)
statusBar(handles.statusBar)
% --- Executes during object creation, after setting all properties.
function popRor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popRor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in btnNewRor.
function btnNewRor_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
updateGraphicsAvgImage(hObject,0)
statusBar(handles.statusBar,'Draw a ROR...',[.3 1 .3])
[newMask, newPos]= drawRoi(handles.axAvgImg);
% Writing the ROI in the matfile
if ~isempty(newMask)
    if ~misField(handles.matfile,'nRor')
        handles.matfile.nRor = 1;
        handles.matfile.RORmask = newMask;
        RORpos.(['pos' num2str(handles.matfile.nRor)]) = newPos;
        handles.matfile.RORpos = RORpos;
    else
        handles.matfile.nRor = handles.matfile.nRor +1;
        handles.matfile.RORmask = cat(3, handles.matfile.RORmask, newMask);
        RORpos = handles.matfile.RORpos;
        RORpos.(['pos' num2str(handles.matfile.nRor)]) = newPos;
        handles.matfile.RORpos= RORpos;
    end
    guidata(hObject,handles);
    % Update GUI data
    nomiRor = {'None'};
    for i = 1:(handles.matfile.nRor)
        nomiRor{i+1,1} = ['ROR: ' num2str(i)];
    end
    set(handles.popRor, 'String', nomiRor);
    set(handles.popRor, 'Value', handles.matfile.nRor+1);
    % Update graphics
    guidata(hObject, handles);
    updateGraphicsTimeline(hObject)
    updateGraphicsTimeBounds(hObject)
    updateGraphicsAvgImage(hObject)
    fprintf('New ROR written of file. \n');
    statusBar(handles.statusBar)
end

% --- Executes on button press in btnDelRor.
function btnDelRor_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
ror = get(handles.popRor,'value')-1;
if ror % if the ror is different from "none"
    handles.matfile.nRor = handles.matfile.nRor-1;
    % RORpos
    RORpos = handles.matfile.RORpos;
    RORpos = rmfield(RORpos,['pos' num2str(ror)]); % remove the selected ROIpos
    names = fieldnames(RORpos);
    data = struct2cell(RORpos);
    for i = 1:size(names,1)
       names{i,1} = ['pos' num2str(i)];
    end
    handles.matfile.RORpos = cell2struct(data, names);
    % RORmask
    RORmask = handles.matfile.RORmask;
    RORmask(:,:,ror) = [];
    handles.matfile.RORmask = RORmask;
    guidata(hObject, handles);
    nomiRor = {'None'};
    if handles.matfile.nRor ~= 0
        for i = 1:(handles.matfile.nRor)
            nomiRor{i+1,1} = ['ROR: ' num2str(i)];
        end
    end
    set(handles.popRor, 'String', nomiRor);
    set(handles.popRor,'value',1)
    % Update graphics
    guidata(hObject, handles);
    updateGraphicsTimeline(hObject)
    updateGraphicsTimeBounds(hObject)
    updateGraphicsAvgImage(hObject)
    fprintf(['ROR:' num2str(ror) ' removed from file. \n']);
else
    fprintf('Cannot delete this ROR. \n')
end
statusBar(handles.statusBar)

% --- Executes on selection change in popRoi.
function popRoi_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
updateGraphicsTimeline(hObject)
updateGraphicsTimeBounds(hObject)
updateGraphicsAvgImage(hObject)
statusBar(handles.statusBar)
% --- Executes during object creation, after setting all properties.
function popRoi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popRoi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in btnNewRoi.
function btnNewRoi_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
updateGraphicsAvgImage(hObject,0)
statusBar(handles.statusBar,'Draw a ROI...',[1 1 .7])
[newMask, newPos]= drawRoi(handles.axAvgImg);
% Writing the ROI in the matfile
if ~isempty(newMask)
    if ~misField(handles.matfile,'nRoi')
        handles.matfile.nRoi = 1;
        handles.matfile.ROImask = newMask;
        ROIpos.(['pos' num2str(handles.matfile.nRoi)]) = newPos;
        handles.matfile.ROIpos = ROIpos;
    else
        handles.matfile.nRoi = handles.matfile.nRoi +1;
        handles.matfile.ROImask = cat(3, handles.matfile.ROImask, newMask);
        ROIpos = handles.matfile.ROIpos;
        ROIpos.(['pos' num2str(handles.matfile.nRoi)]) = newPos;
        handles.matfile.ROIpos= ROIpos;
    end
    guidata(hObject,handles);
    fprintf('New ROI written of file. \n');
    % Update GUI data
    nomiRoi = {'Full Image'};
    for i = 1:(handles.matfile.nRoi)
        nomiRoi{i+1,1} = ['ROI: ' num2str(i)];
    end
    set(handles.popRoi, 'String', nomiRoi);
    set(handles.popRoi, 'Value', handles.matfile.nRoi+1);
    % Update graphics
    guidata(hObject, handles);
    updateGraphicsTimeline(hObject)
    updateGraphicsTimeBounds(hObject)
    updateGraphicsAvgImage(hObject)
    statusBar(handles.statusBar)
end
% --- Executes on button press in btnDelRoi.
function btnDelRoi_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
statusBar(handles.statusBar,'processing...',[1 1 .7])
roi = get(handles.popRoi,'value')-1;
if roi % if the roi is different from "Full Image"
    handles.matfile.nRoi = handles.matfile.nRoi-1;
    % ROIpos
    ROIpos = handles.matfile.ROIpos;
    ROIpos = rmfield(ROIpos,['pos' num2str(roi)]); % remove the selected ROIpos
    names = fieldnames(ROIpos);
    data = struct2cell(ROIpos);
    for i = 1:size(names,1)
       names{i,1} = ['pos' num2str(i)];
    end
    handles.matfile.ROIpos = cell2struct(data, names);
    % ROImask
    ROImask = handles.matfile.ROImask;
    ROImask(:,:,roi) = [];
    handles.matfile.ROImask = ROImask;
    guidata(hObject, handles);
    % Update GUI
    nomiRoi = {'Full Image'}; % roi naming
    if handles.matfile.nRoi ~= 0
        for i = 1:(handles.matfile.nRoi)
            nomiRoi{i+1,1} = ['ROI:' num2str(i)];
        end
    end
    set(handles.popRoi, 'String', nomiRoi);
    set(handles.popRoi,'value',1)
    % Update graphics
    guidata(hObject, handles);
    updateGraphicsTimeline(hObject)
    updateGraphicsTimeBounds(hObject)
    updateGraphicsAvgImage(hObject)
    fprintf(['ROI:' num2str(roi) ' removed from file. \n']);
else
    fprintf('Cannot delete this ROI. \n')
end
statusBar(handles.statusBar)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% SUBFUNCTIONS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);

function updateGraphicsTimeline(hObject)
handles = guidata(hObject);
timeFilter = str2double(get(handles.edtTimeFilter,'String'));
% Timeline
roi = get(handles.popRoi,'value')-1;
names = get(handles.popRoi,'String');
if roi % if the roi is different from "full image"
    RoiMaschere = handles.matfile.ROImask;
    handles.roidata = moving(timeline(roiMovie(handles.filtMovie,RoiMaschere(:,:,roi))),timeFilter);
    roiName = names{roi+1,1};
else
    handles.roidata = moving(timeline(handles.filtMovie),timeFilter);
    roiName = 'Full Image';
end
hRoi = plot(handles.axTimeline, handles.time, handles.roidata,'color',[0 0 1], 'Linewidth', 1.5);
handles.limitsY = drawTimelineRefs(handles.axTimeline);

hold(handles.axTimeline,'on')
ror = get(handles.popRor,'value')-1;
if ror % if the ror is different from "none"
    names = get(handles.popRor,'String');
    rorName = names{ror+1,1};
    RorMaschere = handles.matfile.RORmask;
    handles.rordata = moving(timeline(roiMovie(handles.filtMovie,RorMaschere(:,:,ror))),timeFilter);
    hRor = plot(handles.axTimeline, handles.time, handles.rordata,'color',[.7 1 .7], 'Linewidth', 1);
    set(hRoi,'Linewidth', 0.8, 'color',[.7 .7 1]);
    hRoiRor = plot(handles.axTimeline, handles.time, handles.roidata-handles.rordata ,'color',[1 0 0], 'Linewidth', 1.5);
    legend(handles.axTimeline,[hRoi hRor hRoiRor],{roiName rorName [roiName ' - ' rorName]},'FontSize',7,'Location','best');
    handles.limitsY = drawTimelineRefs(handles.axTimeline);
else
    legend(handles.axTimeline,hRoi,{roiName},'Location','best','FontSize',7);
end
guidata(hObject,handles);
hold(handles.axTimeline,'off')

function updateGraphicsTimeBounds(hObject)
handles = guidata(hObject);
if isfield(handles,'fromLine') && ishandle(handles.fromLine)
    delete(handles.fromLine);
end
if isfield(handles,'toLine') && ishandle(handles.toLine)
    delete(handles.toLine);
end
avgStart = get(handles.popFrom,'Value');
avgEnd = get(handles.popTo,'Value');
% hold(handles.axTimeline,'on')
handles.fromLine = line([handles.time(avgStart) handles.time(avgStart)],[handles.limitsY],'Parent',handles.axTimeline,'color',[.5 .5 0],'linewidth',1.5);
handles.toLine = line([handles.time(avgEnd) handles.time(avgEnd)],[handles.limitsY],'Parent',handles.axTimeline,'color',[.5 .5 0],'linewidth',1.5);
guidata(hObject,handles)
% hold(handles.axTimeline,'off')

function updateGraphicsAvgImage(hObject,drawRoi)
if nargin < 2
    drawRoi = 1;
end
handles = guidata(hObject);
avgStart = get(handles.popFrom,'Value');
avgEnd = get(handles.popTo,'Value');
imagesc(nanmean(handles.filtMovie(:,:,avgStart:avgEnd),3),'parent', handles.axAvgImg)
set(handles.axAvgImg, 'XTickLabel', [], 'YTickLabel', [])
colormap gray

if drawRoi
    roi = get(handles.popRoi,'value')-1;
    hold(handles.axAvgImg,'on')
    if roi % if the roi is different from "full image"
        positions = handles.matfile.ROIpos;
        pos = positions.(['pos' num2str(roi)]);
        plot(handles.axAvgImg,[pos(:,1);pos(1,1)],[pos(:,2);pos(1,2)],...
            'Color',[.3 .3 1],'Linewidth',1)
    end
    ror = get(handles.popRor,'value')-1;
    if ror % if the roi is different from "None"
        positions = handles.matfile.RORpos;
        pos = positions.(['pos' num2str(ror)]);
        plot(handles.axAvgImg,[pos(:,1);pos(1,1)],[pos(:,2);pos(1,2)],...
            'Color','g','Linewidth',1)
    end
    hold(handles.axAvgImg,'off')
end
