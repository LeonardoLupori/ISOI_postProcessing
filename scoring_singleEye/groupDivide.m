function groupedTable = groupDivide(dataTable)
% groupedTable = groupDivide(dataTable)
% 
% Choose wich output variable analyze
varsToAvoid = {'miceID','miceNumber','miceLabel','miceCage','genotype','eye','timepoint'};
common = intersect(dataTable.Properties.VariableNames,varsToAvoid);
list = setxor(dataTable.Properties.VariableNames,common);
[ind,valid] = listdlg('listString',list,'PromptString','Choose output variable',...
    'SelectionMode','single');
if valid == 0
    return
end
outputVar = list{ind};
% Choose grouping factors
list = varfun(@iscategorical,dataTable,'output','uniform');
list = dataTable.Properties.VariableNames(list);
[ind,valid] = listdlg('listString',list,'PromptString','Choose sorting variables',...
    'SelectionMode','multiple');
if valid == 0
    return
end
sortingVar = list(ind);
% Grouping and organizing
[G, groupedTable] = findgroups(dataTable(:,sortingVar));
f = size(outputVar,2);
groupedData = splitapply(@(x){(x)},dataTable(:,outputVar),G);
groupedTable.(outputVar) = groupedData;
