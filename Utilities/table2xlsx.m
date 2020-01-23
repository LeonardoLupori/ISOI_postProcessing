function table2xlsx(table)
% table2xlsx(table)
%
%table2xlsx create a xlsx (Excel) file with all the monodimensional fields
%of the given table. 
%It displays an interactive GUI for saving the file.

names = table.Properties.VariableNames;
validColumns = [];
for i=1:size(names,2)
    data = table.(names{i});
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
%     if isstring(data)
%         validColumns = [validColumns i];
%     end
end

FilterSpec = '*.xlsx';
defaultName = '.\SummaryTable.xlsx';
[FileName,PathName,FilterIndex] = uiputfile(FilterSpec,'Save excel data Table',defaultName);
if FilterIndex
    writetable(table(:,validColumns),[PathName FileName])
end
