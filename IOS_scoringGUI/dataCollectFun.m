function dataCollectFun(startFolder)

if nargin < 1
    startFolder = 'C://';
end

varsToCategorize = {'eye','timepoint','genotype','treatment'};
finalSorting = {'miceNumber'};
varsToSave = {'tabResults', 'tabResultsROR'};

% Fetch all the analysis files
[FileName,PathName,FilterIndex] = uigetfile(startFolder,'Multiselect','on');
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

% get the folder where to save files
tit = 'Select where to save analysis results';
temp = strfind(PathName,'\');
path = PathName(1:temp(end-1));
selpath = uigetdir(path,tit);
if selpath == 0
    return
end

% Remove multidimensional fields in the tabResults table that make Excel angry
names = tabResults.Properties.VariableNames;
validColumns = [];
for i=1:size(names,2)
    data = tabResults.(names{i});
    if isnumeric (data)
        validColumns = [validColumns i];
    end
    if iscategorical(data)
        validColumns = [validColumns i];
    end
    if iscell(data)
        if ischar(data{1,1})
            validColumns = [validColumns i];
        end
    end
end

% Remove multidimensional fields in the tabResultsROR table that make Excel angry
namesROR = tabResultsROR.Properties.VariableNames;
validColumnsROR = [];
for i=1:size(namesROR,2)
    data = tabResultsROR.(namesROR{i});
    if isnumeric (data)
        validColumnsROR = [validColumnsROR i];
    end
    if iscategorical(data)
        validColumnsROR = [validColumnsROR i];
    end
    if iscell(data)
        if ischar(data{1,1})
            validColumnsROR = [validColumnsROR i];
        end
    end
end

% Actually save data
matfilePath = [selpath filesep 'SummaryTables_' datestr(today,'yyyymmdd') '.mat'];
save(matfilePath,'tabResults','tabResultsROR')
writetable(tabResults(:,validColumns),[selpath filesep 'resultsRAW_' datestr(today,'yyyymmdd') '.xlsx'])
writetable(tabResultsROR(:,validColumnsROR),[selpath filesep 'resultsROR_' datestr(today,'yyyymmdd') '.xlsx'])
