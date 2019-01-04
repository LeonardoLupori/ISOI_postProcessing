close all;
clear all;
clc
%% Analysis parameters and Files fetching
% This parameters are the one used in the script. The struct used in later
% parts is the Parameters struct.
% You can modify or add new parameters to the struct

defaultParameters.treshold          = 0.3;
defaultParameters.startFrame        = 16;
defaultParameters.endFrame          = 36;
defaultParameters.spatialFilter     = 5;
defaultParameters.temporalFilter    = 1;
defaultParameters.roiClosing        = 5;
defaultParameters.filter4Slope       = 5;
defaultParameters.filter4SlopeDiff   = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREFERENCE FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modify this path to point to the preferences file in your computer
prefFile = 'C:\Users\Leonardo\Documents\MATLAB\IOS\PostProcessingTOOLBOX_1.2\scoring_binocularity\preferences.mat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Close existing analysis figures

clc;
fprintf([repmat('*',1,40) '\n IOS analysis for Binocularity. \n'])
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

% Matfile, stored in the hdd, with the analysis preferences
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
        % Count the number of contra and ipsi recordings to initialize the
        % arrays
        numContraRec = 0;
        numIpsiRec = 0;
        numUnallocatedRec = 0;
        for i = 1:length(FileName)
            m = matfile([PathName FileName{i}]);
            if strcmpi(m.shutter,'CONTRA')
                numContraRec = numContraRec+1;
            elseif strcmpi(m.shutter,'IPSI')
                numIpsiRec = numIpsiRec+1;
            else
                numUnallocatedRec = numUnallocatedRec+1;
            end
        end
        % Initialize the arrays and load the recordings
        for i = 1:length(FileName)
            m = matfile([PathName FileName{i}]);
            if i == 1
                fprintf('\n')
                time = m.time;
                stimulus = m.stimulus;
                contraMovies = zeros(size(m.drorMovie,1),size(m.drorMovie,2),...
                    size(m.drorMovie,3),length(FileName));
                ipsiMovies = zeros(size(m.drorMovie,1),size(m.drorMovie,2),...
                    size(m.drorMovie,3),length(FileName));
            else
                if m.time(1,1)~= time(1) || m.time(1,end)~= time(end)
                    error(['Mismatch in the time-vector of recording: ' FileName{i}])
                end
            end
            movies(:,:,:,i) = m.drorMovie;
            fprintf(['\tFile: "' FileName{i} '" LOADED as ' m.shutter '\n'])
        end
        %         avgMovie = mean(movies,4);
    else % only 1 file has been selected
        fprintf('\n\tOnly 1 file loaded. Binocularity analysis stopped\n')
        return
    end
else
    %     clear all
    fprintf('aborted.\n')
    return
end
prefs.defPath = PathName;
clearvars -except parameters prefs time movies stimulus handles
%%


%%

if exist('handles','var') && isfield(handles,'filetableFig') && ishandle(handles.filetableFig)
    close(handles.filetableFig);
end
tablewidth = 740;
handles.filetableFig = figure('color',[1 1 1],...
    'position',[550 500 tablewidth 280],...
    'name','Select recordings and eyes');

data = {'uno000000000000000000000000000000000000000000000','CONTRA',10,true;...
    'due','IPSI',15,true};
rowname = [];
columnname = {'File','Eye','Sums','Select'};
columneditable = [false true false true];
columnformat = {'char',{'CONTRA','IPSI'},'numeric','logical'};
t = uitable('data',data,...
    'unit','normalized',...
    'position',[0 0 1 1],...
    'rowname',rowname,...
    'columnwidth',{tablewidth*0.65,tablewidth*0.15,tablewidth*0.1,tablewidth*0.1},...
    'columneditable',columneditable,...
    'columnname',columnname,...
    'columnformat',columnformat);
jScroll = findjobj(t);
jTable  = jScroll.getViewport.getView;
jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
drawnow;

clc




