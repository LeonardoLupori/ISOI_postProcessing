function preprocessingVisualize(hObject)
% preprocessingVisualize(handle)
% 
% preprocessingVisualize is a function designed to perform useful
% preprocessing routines for the visualization of an IOS data from a
% matfile in a GUI.
% It accepts as an input the handle to the GUI (often hObject) in which
% there must be a matfile object of the desired matfile.
% 
% What is done:
% 1- Check if data are already readable (e.g., if dR/R has been done)
% 2- Import variable Time from matfile and update the GUI
% 3- Import variable Filtersize from matfile and update the GUI
% 4- Import ROIs and RORs from matfile and update the GUI
% 5- Import variable drorMovie from matfile and update the GUI



handles = guidata(hObject);
handles.matfile = matfile([handles.filePath handles.fileName],'Writable', true);
prefMatfile = matfile('iosPostprocessing_preferences','Writable',true);

% Check if data are already readable (e.g., if dR/R has been done)
if ~misField(handles.matfile,'drorMovie')
    fprintf('Preprocessing... ')
    tic
    preprocComplete = ios_preprocessing(handles.matfile);
    if preprocComplete
        fprintf(['end. [%4.2f' 's] \n'], toc);
    else
        fprintf('Failed. \n');
    end
end

% Time
handles.time = handles.matfile.time;
if misField(handles.matfile,'avgStart')
    set(handles.popFrom,'String',handles.time,'Value',handles.matfile.avgStart)
else
    set(handles.popFrom,'String',handles.time,'Value',prefMatfile.defaultAvgStart)
end
if misField(handles.matfile,'avgEnd')
    set(handles.popTo,'String',handles.time,'Value',handles.matfile.avgEnd)
else
    set(handles.popTo,'String',handles.time,'Value',length(handles.time))
end
% Filtsize
if misField(handles.matfile,'filtSize')
    set(handles.edtSpaceFilter,'String',num2str(handles.matfile.filtSize))
else
    set(handles.edtSpaceFilter,'String',num2str(prefMatfile.defaultSpaceFilter))
end
% ROI
if misField(handles.matfile, 'nRoi') && handles.matfile.nRoi~=0
    nomiRoi = {'Full Image'};
    for i = 1:(handles.matfile.nRoi)
        nomiRoi{i+1,1} = ['ROI:' num2str(i)];
    end
    set(handles.popRoi, 'String', nomiRoi);
    set(handles.popRoi, 'Value', 1);
else
    set(handles.popRoi, 'String', 'Full Image');
    set(handles.popRoi, 'Value', 1);
end

% ROR
if misField(handles.matfile, 'nRor') && handles.matfile.nRor~=0
    nomiRor = {'None'};
    for i = 1:(handles.matfile.nRor)
        nomiRor{i+1,1} = ['ROR:' num2str(i)];
    end
    set(handles.popRor, 'String', nomiRor);
    set(handles.popRor, 'Value', 1);
else
    set(handles.popRor, 'String', 'None');
    set(handles.popRor, 'Value', 1);
end

%  drorMovie
handles.drorMovie = handles.matfile.drorMovie;

% Update filename in the gui header
set(handles.txtFilename,'String',handles.fileName);

guidata(hObject, handles);
