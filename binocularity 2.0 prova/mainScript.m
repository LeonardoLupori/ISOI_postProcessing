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
prefFile = 'C:\Users\Leonardo\Documents\MATLAB\IOS\PostProcessingTOOLBOX_1.2\scoring_singleEye\preferences.mat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% chiudi fig aperte


% Some welcome pretty text
fprintf([repmat('*',1,46) '\n IOS analysis for OCULAR DOMINANCE recordings. \n'])
fprintf([repmat('*',1,46) '\n\n']);
% Prompt the user to insert analysis parameters
fprintf('Insert the analysis parameters...');
dlg_title = 'Parameters';
prompt = fieldnames(defaultParameters);
num_lines = [1, length(dlg_title)+25];
defAns = cell(numel(fieldnames(defaultParameters)),1);
names = fieldnames(defaultParameters);
for i=1:numel(fieldnames(defaultParameters))
    defAns{i,1} = num2str(defaultParameters.(names{i}));
end
answer = inputdlg(prompt,dlg_title,num_lines,defAns,'on'); % dialog box creation
% collect the user-defined analyisi parameters
if ~isempty(answer)
    for i=1:numel(answer)
        names = fieldnames(defaultParameters);
        parameters.(names{i}) = str2double(answer{i});
    end
    fprintf('\tparameters accepted.\n');
else
    fprintf('\taborted\n');
    clearvars
    return
end
clearvars -except parameters handles prefFile
% opens the general preference file as a mafile object
if exist(prefFile, 'file')
    prefs = matfile(prefFile,'Writable',true);
else
    prefs = matfile(prefFile,'Writable',true);
    prefs.defPath = 'C:\';
end


%% scegli files
fprintf('Select the files for analysis...')
[FileName,PathName,FilterIndex] = uigetfile(prefs.defPath,'MultiSelect','on');
if FilterIndex ~= 0 % A selection has been made
    if ~iscell(FileName) % only 1 file has been selected
        error('Only 1 file selected. Binocularity analysis not possible');
    end
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
            % in the 1st cycle load time vector. Throw an error in case
            % of a time mismatch in later recordings(i>1).
            fprintf('\n')
            time = m.time;
            stimulus = m.stimulus;
            allRecordings = cell(length(FileName),3);
        else
            if m.time(1,1)~= time(1) || m.time(1,end)~= time(end)
                error(['Mismatch in the time vector of recording: ' FileName{i}])
            end
        end
        allRecordings{i,1} = m.drorMovie;
        allRecordings{i,2} = m.shutter;
        allRecordings{i,3} = FileName{i};
        fprintf(['\tFile: "' FileName{i} '" LOADED.\n'])
    end
else % nothing have been selected
    fprintf('aborted.\n')
    return
end
prefs.defPath = PathName;
clearvars -except parameters prefs time allRecordings stimulus handles prefFile

% Show the user the predicted shutter position
tableWidth = 300; % in pixels
columnname = {'Recording Name','Eye'};
columnformat = {'char',{'CONTRA' 'IPSI'}};
t = uitable('data',allRecordings(:,[3,2]),...
    'ColumnName',columnname,...
    'ColumnFormat',columnformat,...
    'ColumnEditable', [false true],...
    'RowName',[],...
    'ColumnWidth', {tableWidth*0.70 tableWidth*0.3},...
    'OuterPosition', [20 20 tableWidth tableWidth*1.5],...
    'DeleteFcn','newEyes = t.Data(:,2);');
f = t.Parent;
set(f, 'Position', [300 200 tableWidth*1.1 tableWidth*1.5*1.1],...
    'Name', 'Edit eyes');

%%

if isequal(newEyes,allRecordings(:,2)) % User didn't change any eye field
else % user changed some fields
    changed = find(cellfun(@strcmpi,newEyes,allRecordings(:,2))==0);
    fprintf('EYE CHANGES:\n')
    for j=1:length(changed)
        fprintf(['\t' allRecordings{j,2} '->' newEyes{j,1} ' in Rec: ' allRecordings{changed(j),3} '\n'])
    end
end



% filtraggio






