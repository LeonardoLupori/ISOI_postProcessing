function bool = exportImage(analysisFilePath, valuesRange, rereferenced, cropLimits)

% bool = exportImage(analysisFilePath);
% bool = exportImage(analysisFilePath, valuesRange);
% bool = exportImage(analysisFilePath, valuesRange, rereferenced);
% bool = exportImage(analysisFilePath, valuesRange, rereferenced, cropLimits);
% 
% ARGUMENTS
% analysisFilePath: Full path to the analysis file
% valuesRange(optional): 2 elements vector containing the black and white values
% rereferenced(optional): Logical value indicating whether to use the
% rereferenced image or not (default: false)
% cropLimits(optional): 4 element vector containing the limits for cropping. (x and y 
% coordinates starting from the top left). 
% 
% Leonardo Lupori - 2018 oct 22

if nargin < 2
    cropLimits = NaN;
    rereferenced = false;
    valuesRange = NaN;
elseif nargin < 3 
    rereferenced = false;
    cropLimits = NaN;
elseif nargin < 4
    cropLimits = NaN;
else
    if ~islogical(rereferenced)
        error('Field "rereferenced" needs to be a logical value (true or false).')
    end
end

bool = false;
m = matfile(analysisFilePath);

if rereferenced
    temp = m.resultsROR;
    img = temp.avgRereferencedImage;
else
    temp = m.results;
    img = temp.avgImage;
end

% This step is to rescale the image data in the desired valuesRange and at
% the same time scaling it back between 0 and 1.
% It should work. If you don't understand it... neither I

if all(isnan(valuesRange)) || isempty(valuesRange)
    rescaledImage = img - min(img(:)); 
    rescaledImage = rescaledImage/ (max(img(:)) - min(img(:)));    
else
    % Check that the values are ascending
    if valuesRange(2)-valuesRange(1) < 0
    error('valuesRange must be an ascending 2-element vector.')
    end
    
    rescaledImage = img - valuesRange(1); 
    rescaledImage = rescaledImage/(valuesRange(2) - valuesRange(1));
end

% Generate default Name 
[FilterSpec,name,~] = fileparts(m.Properties.Source);
DialogTitle = 'Save IOS image';
temp = strsplit(name,'_');
DefaultName = ['responseImage_' temp{end-1} '_' temp{end} '.tif'];

% Let the user change the save path or filename
[FileName,PathName,FilterIndex] = uiputfile([FilterSpec filesep DefaultName],DialogTitle);
% Eventually crop the image
if isnan(cropLimits)
else
    rescaledImage = rescaledImage(cropLimits(3):cropLimits(4), cropLimits(1):cropLimits(2));
end

% Save the image
if FilterIndex
    imwrite(rescaledImage,[PathName FileName])
    bool = true;
else
    bool = false;
end
