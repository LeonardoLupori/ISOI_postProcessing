function varargout = iosPostprocessing(varargin)

% Last Modified by GUIDE v2.5 23-Aug-2016 15:57:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @iosPostprocessing_OpeningFcn, ...
    'gui_OutputFcn',  @iosPostprocessing_OutputFcn, ...
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


% --- Executes just before iosPostprocessing is made visible.
function iosPostprocessing_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iosPostprocessing (see VARARGIN)

% Choose default command line output for iosPostprocessing
handles.output = hObject;
if exist('iosPostprocessing_preferences.mat', 'file')
    handles.prefFile = matfile('iosPostprocessing_preferences','Writable',true);
    if ~isempty(handles.prefFile.currentFile)
        [pathstr,name,ext] = fileparts(handles.prefFile.currentFile);
        handles.currentFolder = [pathstr '\'];
    else
        handles.currentFolder = handles.prefFile.defaultPath;
    end
else
    createPreferences()
    handles.prefFile = matfile('iosPostprocessing_preferences','Writable',true);
    handles.currentFolder = handles.prefFile.defaultPath;
end

guidata(hObject, handles);
updateFolderName(hObject, handles.currentFolder) % aggiorna il nome della cartella header
fillList(hObject)                               % riempie la lista files
contents = cellstr(get(handles.fileList,'String'));
handles.currentFile = [handles.currentFolder '\' contents{get(handles.fileList,'Value')}];
updateInfos(hObject, {handles.currentFile})       % aggiornare le infos
statusBar(handles.txtStatus,['Current file: ' contents{get(handles.fileList,'Value')}],[1 1 1])
set(handles.chkBxBatch,'Value', 0);
set(handles.btnPreproc,'enable','off');
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = iosPostprocessing_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in btnBrowse.
function btnBrowse_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
if isfield(handles,'currentFolder')
    folder_name = uigetdir(handles.currentFolder,'Choose a directory');
else
    folder_name = uigetdir([],'Choose a directory');
end
if folder_name == 0
    return
else
    handles.currentFolder = folder_name;
end
guidata(hObject, handles);
updateFolderName(hObject, folder_name)
fillList(hObject)                           % fill the name list
if get(handles.chkBxBatch, 'Value')         % Updates max num of selectable files based on the new folder
    numFiles = size(get(handles.fileList,'String'),1);
    set(handles.fileList,'Max',numFiles);
else
    set(handles.fileList, 'Max', 1);
end
contents = cellstr(get(handles.fileList,'String')); % update the current file handle
filename = contents{get(handles.fileList,'Value')};
handles.currentFile = [handles.currentFolder '\' filename];
if exist('iosPostprocessing_preferences.mat', 'file')
    handles.prefFile.currentFile = handles.currentFile; % update the preferences with the current file
else
    createPreferences()
    handles.prefFile = matfile('iosPostprocessing_preferences','Writable',true);
    handles.prefFile.currentFile = handles.currentFile; % update the preferences with the current file
end
guidata(hObject, handles);
updateInfos(hObject, {handles.currentFile})
statusBar(handles.txtStatus,['Current file: ' filename],[1 1 1])

% --- Executes on selection change in fileList.
function fileList_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
contents = cellstr(get(hObject,'String'));
selection = get(hObject,'Value');
filename = (contents(selection));
currentFile = cell(size(selection,2),1);
for i=1:size(selection,2)
    currentFile{i} = strcat(handles.currentFolder, '\', filename{i});
end
handles.currentFile = currentFile;

if exist('iosPostprocessing_preferences.mat', 'file')
    handles.prefFile.currentFile = handles.currentFile{1}; % update the preferences with the current file
else
    createPreferences()
    handles.prefFile = matfile('iosPostprocessing_preferences','Writable',true);
    handles.prefFile.currentFile = handles.currentFile{1}; % update the preferences with the current file
end
updateInfos(hObject, handles.currentFile)       % aggiornare le infos

if size(selection,2)>1
    statusBar(handles.txtStatus,[num2str(size(selection,2)) ' Files Selected.'],[1 1 1])
else
    statusBar(handles.txtStatus,['Current file: ' filename{1}],[1 1 1])
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function fileList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in btnVisualize.
function btnVisualize_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
[pathstr,name,ext] = fileparts(handles.currentFile{1});
iosVisualize({[pathstr '\']},{[name ext]});

% --- Executes on button press in chkBxBatch.
function chkBxBatch_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
batchBool = get(hObject,'Value');
if batchBool == true
    numFiles = size(get(handles.fileList,'String'),1);
    set(handles.fileList, 'Max', numFiles)
    set(handles.btnVisualize, 'Enable', 'Off')
    set(handles.btnPreproc, 'Enable', 'On')
    set(handles.btnBrowse,'Enable', 'Off')
else
    set(handles.fileList, 'Value', 1)
    set(handles.fileList, 'Max', 1)
    contents = cellstr(get(handles.fileList,'String'));
    filename = contents{get(handles.fileList,'Value')};
    statusBar(handles.txtStatus,['Current file: ' filename],[1 1 1])
    set(handles.btnVisualize, 'Enable', 'On')
    set(handles.btnPreproc, 'Enable', 'Off')
    set(handles.btnBrowse,'Enable', 'On')
end
guidata(hObject, handles);

% --- Executes on button press in btnPreproc.
function btnPreproc_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
numFiles = length(handles.currentFile);

for i=1:numFiles
    name = handles.currentFile{i};
    m = matfile(name,'Writable', true);
    if ~misField(m,'drorMovie')
        fprintf('Preprocessing... ')
        tic
        preprocComplete = ios_preprocessing(m);
        if preprocComplete
            fprintf(['File %i/%i processed. [Processing time:%4.2f' 's] \n'], i, numFiles, toc);
        else
            h = warndlg(['Preprocessing of "' handles.currentFile{i} '" has failed!']);
            waitfor(h);
        end
    else
        fprintf('File %i/%i already preprocessed. \n', i, numFiles);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fillList(hObject)
handles = guidata(hObject);
contents = dir(handles.currentFolder);
filenames = {contents.name};            % cell with all the filenames
inc = 1;
for i = 1:length(filenames)             % select only files .mat as valid
    [~,~,ext] = fileparts(filenames{i});
    if strcmpi(ext,'.mat')
        validNames{inc} = filenames{i};
        inc = inc+1;
    end
end
if exist('validNames','var')
    set(handles.fileList,'String',validNames')
    set(handles.fileList,'Value',1)
else
    set(handles.fileList,'String','No Files.')
    set(handles.fileList,'Value',1)
end

function updateInfos(hObject, filepath)
handles = guidata(hObject);
if length(filepath)>1
    set(handles.txtEye,'String','Eye: N/A')
    set(handles.txtRec,'String','Rec: N/A')
    set(handles.txtSums,'String','Sums: N/A')
    set(handles.txtContr,'String','Contr: N/A')
    set(handles.txtSpfreq,'String','S.Fr: N/A')
    set(handles.txtRaw,'String','Raw: N/A')
    set(handles.txtRois,'String','ROIs: N/A')
    set(handles.txtRor,'String','RORs: N/A')
    return
end


m = matfile(filepath{1});
if misField(m, 'stimulus')
    stim = m.stimulus;
else
    stim = [];
end

% Eye
if misField(m,'shutter')
    if strcmpi(m.shutter,'Disconnected')
        set(handles.txtEye,'String',['Eye: ' 'N/A'])
    else
        set(handles.txtEye,'String',['Eye: ' m.shutter])
    end
else
    set(handles.txtEye,'String','Eye: N/A')
end
% REC and Number of sums
if misField(m,'incomplete')
    set(handles.txtRec,'String','Rec: Incomp')
    set(handles.txtSums,'String',['Sums: ' num2str(m.incomplete)])
elseif misField(m,'avgMovie') && misField(m,'repetitions')
    set(handles.txtRec,'String','Rec: ok')
    set(handles.txtSums,'String',['Sums: ' num2str(m.repetitions)])
else
    set(handles.txtRec,'String','Rec: N/A')
    set(handles.txtSums,'String','Sums: N/A')
end
% Contrast
if ~isempty(stim)
    set(handles.txtContr,'String',['Contr: ' num2str(stim.contrast)])
else
    set(handles.txtContr,'String','Contr: N/A')
end
% Spatial frequency
if ~isempty(stim)
    set(handles.txtSpfreq,'String',['S.Fr: ' num2str(stim.cdeg)])
else
    set(handles.txtSpfreq,'String','S.Fr: N/A')
end
% Raw data
if misField(m,'rawData')
    set(handles.txtRaw,'String','Raw: yes')
else
    set(handles.txtRaw,'String','Raw: no')
end
% Number of ROIs
if misField(m,'nRoi')
    set(handles.txtRois,'String',['ROIs: ' num2str(m.nRoi)])
else
    set(handles.txtRois,'String','ROIs: N/A')
end
% Number of RORs
if misField(m,'nRor')
    set(handles.txtRor,'String',['RORs: ' num2str(m.nRor)])
else
    set(handles.txtRor,'String','RORs: N/A')
end

function updateFolderName(hObject, folder_name)

handles = guidata(hObject);
% splitted = strsplit(folder_name,'\'); 
splitted = regexp(folder_name,'\','split');
if size(splitted,2)>3
    shortFold = ['..\' splitted{end-2} '\' splitted{end-1} '\' splitted{end}];
else
    shortFold = folder_name;
end
set(handles.txtFolder, 'String', shortFold)
