%% Load the results table
clearvars, clc
defaultPath = 'D:\PizzorussoLAB\';
[FileName,PathName,FilterIndex] = uigetfile(defaultPath,'MultiSelect','off');
if FilterIndex ~= 0
    load([PathName filesep FileName]);
end

%% Ocular Dominance analysis for 1 factor experiments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% PARAMETERS FOR THE USER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Choose the results table that you want to perform the analysis with
tableToAnalyze = tabResultsROR;
groupingFactor = 'treatment'; % choose beetween 'treatment' and 'genotype'
desiredVariable = 'avgAmplitude'; % choose the variable of interest
% Variables 'eye' and 'timepoint' are automatically used

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tableToAnalyze.treatment(isundefined(tableToAnalyze.treatment)) = 'none';

% This assumes there are only 2 timepoints.
outputTable = tableToAnalyze(:,{'miceID' groupingFactor 'eye' 'timepoint' desiredVariable});
availableTimepoints = unique(outputTable.timepoint);
[Selection,ok] = listdlg('ListString',availableTimepoints,...
    'SelectionMode','single',...
    'ListSize',[160 100],...
    'Name','Timepoints',...
    'PromptString','Choose the BIN timepoint');
binGroupName = availableTimepoints(Selection);
% Split bin and MD values
bin = outputTable(outputTable.timepoint==binGroupName,:); % table with only bin values
bin.timepoint = []; % remove the timepoint variable now obsolete
md = outputTable(outputTable.timepoint~=binGroupName, {'miceID' 'eye' desiredVariable}); % table with only MD values
% Unstack bin and md values for different eyes and join the results
bin = unstack(bin, desiredVariable,'eye');
bin.odi = (bin.contra-bin.ipsi)./(bin.contra+bin.ipsi);
md = unstack(md, desiredVariable,'eye');
md.odi = (md.contra-md.ipsi)./(md.contra+md.ipsi);
MD_table = join(bin,md,'Keys','miceID');
clearvars -except MD_table tableToAnalyze

%% Export ad a XLSX/CSV file
table2xlsx(MD_table);