function bool=ios_preprocessing(pathToFile)

% bool=ios_preprocessing(pathToFile)
% 
% ios_preprocessing prepares data for deltaR on R.
% 
% It creates the following variables inside the matfile:
% 
%   time: time vector [expressed in seconds]
%   drorMovie: the dR/R of the entire movie (prestim+poststim frames)
%   avgStart: the starting frame from which the avgImage is calculated
%   avgEnd: the last frame to which the avgImage is calculated
%   avgImage: the average image of the dR/R between frame avgStart and avgEnd
% 
% see also dRoR

if nargin<1
error('This function needs at least one arg');
end
bool = true;
if  isobject(pathToFile)
    reg = pathToFile;
    reg.Properties.Writable=true;
elseif exist(pathToFile)
    reg = matfile(pathToFile,'Writable',true); 
else 
    warning('File not found.')
    bool = false;
end

isValid = misField(reg,'avgMovie') && misField(reg,'stimulus')  && misField(reg,'repetitions');

if ~isValid
    warning('File not Recognized')
    bool = false;
else
    if misField(reg,'rawData')
        fprintf(' [this file contains raw data] ')
    end
    stim = reg.stimulus;
    
    %% Preprocessing 
    if isfield(stim, 'framerate')
    reg.time =-stim.preStim:1/stim.framerate:stim.postStim-(1/stim.framerate);
    else
        reg.time =-stim.preStim:1/stim.frameRate:stim.postStim-(1/stim.frameRate);
    end
    avgMovie = reg.avgMovie;
    avgBase = avgMovie(:,:,1:stim.preStimTriggers);
    reg.drorMovie = dRoR(reg.avgMovie,avgBase);
  
    reg.avgImage = mean(reg.drorMovie(:,:,reg.avgStart:reg.avgEnd),3);
end
