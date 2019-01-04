clear all; clc
StartFolder = 'D:\experimental_DATA\iosDATA\exp_fasting_MD\analized_Data';
varsToCategorize = {'eye','timepoint','genotype','treatment'};
finalSorting = {'miceNumber'};
varsToSave = {'tabResults', 'tabResultsROR'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Colleziona tutti i campi in una tabella
[FileName,PathName,FilterIndex] = uigetfile(StartFolder,'Multiselect','on');
if ~FilterIndex
    clear all
    return
end
InfoFieldsToRemove = {'dateOfAnalysis','comments'};
for i = 1:size(FileName,2)
    m = matfile([PathName FileName{i}]);
    info = m.info;
    info = rmfield(info,InfoFieldsToRemove);
    results = m.results;
    if misField(m,'resultsROR')
        resultsROR = m.resultsROR;
    end
    % Fill in 2 structures (tabResults and tabResultsROR) with data from all subjects
    names = fieldnames(info);
    infoFieldsNumber = size(names,1);
    for j=1:infoFieldsNumber
        tabResults(i).(names{j}) = info.(names{j});
        tabResultsROR(i).(names{j}) = info.(names{j});
    end
    names = fieldnames(results);
    for j = 1 : size(names,1)
        tabResults(i).(names{j}) = results.(names{j});
    end
    names = fieldnames(resultsROR);
    for j = 1 : size(names,1)
        tabResultsROR(i).(names{j}) = resultsROR.(names{j});
    end
end
% Convert the 2 structures into tables
tabResults = struct2table(tabResults);
tabResultsROR = struct2table(tabResultsROR);
for i=1:size(varsToCategorize,2)
    tabResults.(varsToCategorize{i}) = categorical(tabResults.(varsToCategorize{i}));
    tabResultsROR.(varsToCategorize{i}) = categorical(tabResults.(varsToCategorize{i}));
end
% Merge infos on the mouse to generate miceID variable
if sum(ismissing(tabResults(:,'miceLabel'))) < 1
    miceID = strcat(tabResults.miceLabel,'-',num2str(tabResults.miceNumber));
else
    miceID = num2str(tabResults.miceNumber);
end
if sum(ismissing(tabResults(:,'miceCage'))) < 1
    miceID = strcat(tabResults.miceCage, '_', miceID);
end
tabResults.miceID = miceID;
tabResultsROR.miceID = miceID;
tabResults = tabResults(:,[end 1:(end-1)]); % Reorder miceID as first variable
tabResultsROR = tabResultsROR(:,[end 1:(end-1)]);
% tabResults(:,{'miceNumber','miceLabel', 'miceCage'}) = []; % Delete old mice informations
% tabResultsROR(:,{'miceNumber','miceLabel', 'miceCage'}) = [];
% Remove empty variables
varsToRemove = [];
for i=1:size(tabResults,2)
    if sum(ismissing(tabResults(:,i))) == size(tabResults,1)
        varsToRemove = [varsToRemove i];
    end
end
tabResults(:,varsToRemove) = []; 
varsToRemove = [];
for i=1:size(tabResultsROR,2)
    if sum(ismissing(tabResultsROR(:,i))) == size(tabResultsROR,1)
        varsToRemove = [varsToRemove i];
    end
end
tabResultsROR(:,varsToRemove) = []; 
% Sorting
tabResults = sortrows(tabResults,finalSorting);
tabResultsROR = sortrows(tabResultsROR,finalSorting);
% Save processed tables
temp = strfind(PathName,'\');
path = [PathName(1:temp(end-1)) 'SummaryTables_' datestr(today,'yyyymmdd')];
uisave(varsToSave,path);
clearvars -except FileName PathName tabResults tabResultsROR