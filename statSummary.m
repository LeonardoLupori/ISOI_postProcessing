function varargout = statSummary(varargin)
% STATSUMMARY MATLAB code for statSummary.fig
%      STATSUMMARY, by itself, creates a new STATSUMMARY or raises the existing
%      singleton*.
%
%      H = STATSUMMARY returns the handle to a new STATSUMMARY or the handle to
%      the existing singleton*.
%
%      STATSUMMARY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STATSUMMARY.M with the given input arguments.
%
%      STATSUMMARY('Property','Value',...) creates a new STATSUMMARY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before statSummary_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to statSummary_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help statSummary

% Last Modified by GUIDE v2.5 22-Jan-2016 15:30:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @statSummary_OpeningFcn, ...
                   'gui_OutputFcn',  @statSummary_OutputFcn, ...
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


% --- Executes just before statSummary is made visible.
function statSummary_OpeningFcn(hObject, eventdata, handles, varargin)
handles.structure = varargin{1};
handles.fileName = varargin{2};

nomiStruct = fieldnames(handles.structure);
% for i= 1:size(nomiStruct,1)
%     field = handles.structure.(nomiStruct{i,1});
%     if isnumeric(field)
%         handles.structure.(nomiStruct{i,1}) = num2str(field, '%8.4e');
%     end
% end
handles.data = [fieldnames(handles.structure) struct2cell(handles.structure)];

% Choose default command line output for statSummary
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = statSummary_OutputFcn(hObject, eventdata, handles) 
handles = guidata(hObject);
set(handles.table,'Data',handles.data)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnSave.
function btnSave_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
FilterSpec = '*.mat';
DialogTitle = 'Save statistics matfile';
[defaultPath,name,~] = fileparts(handles.fileName); % remove extension from filename
defaultName = [name '_statistics'];
[FileName,PathName,FilterIndex] = uiputfile(FilterSpec,DialogTitle,[defaultPath filesep defaultName]);
if FilterIndex ~= 0
    fileExist = misField([PathName FileName], 'shutter');
    if fileExist
        delete([PathName FileName]);
    end
    s = handles.structure;
    save([PathName FileName], '-struct', 's')
    fprintf('Statistics matfile saved. \n')
end
