function editEye(allRecordings,hObject,callbackdata)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
newEyes = t.Data(:,2);

if isequal(newEyes,allRecordings(:,2)) % User didn't change any eye field
else % user changed some fields
    changed = find(cellfun(@strcmpi,newEyes,allRecordings(:,2))==0);
    fprintf('EYE CHANGES:\n')
    for j=1:length(changed)
        fprintf(['\t' allRecordings{j,2} '->' newEyes{j,1} ' in Rec: ' allRecordings{changed(j),3} '\n'])
    end
end

end

