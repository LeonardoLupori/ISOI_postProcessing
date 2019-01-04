%% USER PARAMETERS
clear all; clc
StartingFolder = 'C:\Recordings\';
SpatialFilter = 12;
tresholdROI = 0.2;
startBound = 16; % 0.5 sec
endBound = 36; % 2.5sec
ROIclosing = 3;

%% FILES SELECTION
[FileNames,PathName,FilterIndex] = uigetfile(StartingFolder,'MultiSelect','on');
if FilterIndex ~= 0 % l'user made a selection
    if iscell(FileNames)    % the selection consists in more than one file
        Movies = cell(length(FileNames), 3);
        fprintf('%i files selected. \n' , length(FileNames));
        for i = 1:length(FileNames)
            nome = FileNames{i};
            m = matfile([PathName nome]);
            Movies{i,1} = m.drorMovie;
            Movies{i,2} = m.shutter;
            Movies{i,3} = nome;
        end
    end
    % Automatically divide files between contralateral and ipsilateral
    ipsiMovies = Movies(strcmp(Movies(:,2),'IPSI'),:);      % Cella con rec IPSI
    fprintf('%i files automatically identified as IPSILATERAL recordings: \n', sum(strcmp(Movies(:,2),'IPSI')))
    ipsiList = Movies(strcmp(Movies(:,2),'IPSI'),3);
        for i= 1:size(ipsiList,1)
            fprintf(['\t\t' ipsiList{i} '\n'])
        end
    contraMovies = Movies(strcmp(Movies(:,2),'CONTRA'),:);  % Cella con rec CONTRA
    fprintf('%i files automatically identified as CONTRALATERAL recordings: \n', sum(strcmp(Movies(:,2),'CONTRA')))
    contraList = Movies(strcmp(Movies(:,2),'CONTRA'),3);
        for i= 1:size(contraList,1)
            fprintf(['\t\t' contraList{i} '\n'])
        end
    % create 4D-array with space-filtered IPSI recording
    dim = ndims(ipsiMovies{1,1});
    ipsiArray = cat(dim+1,ipsiMovies{:,1});         
    unfiltIpsiIMG = mean(mean(ipsiArray(:,:,startBound:endBound,:),4),3);
    for i = 1:size(ipsiArray,4)
        ipsiArray(:,:,:,i) = filterMovie(ipsiArray(:,:,:,i),SpatialFilter); % Filtered IPSI array
    end
    % create 4D-array with space-filtered CONTRA recording
    dim = ndims(contraMovies{1,1});
    contraArray = cat(dim+1,contraMovies{:,1});     
    unfiltContraIMG = mean(mean(contraArray(:,:,startBound:endBound,:),4),3);
    for i = 1:size(contraArray,4)
        contraArray(:,:,:,i) = filterMovie(contraArray(:,:,:,i),SpatialFilter); % Filtered CONTRA array
    end
%   Load time and stimulus parameters from the last recording

% NB si potrebbe fare di volta in volta e checkare che siano uguali!!!
    time = m.time;
    stimulus = m.stimulus;
else
    return
end

%% Visualizzazione preliminare
% Trovare la ROI sull'ipsi & Disegnare una ROR
% img = mean(ipsiArray,4);
% img = mean(ipsiArray(:,:,startBound:endBound),3);
img = mean(mean(ipsiArray(:,:,startBound:endBound,:),4),3);
range = max(img(:)) - min(img(:));
absTreshROI = min(img(:)) + range*tresholdROI;
maschera = img<absTreshROI;
closing = strel('disk', ROIclosing);
maschera = imclose(maschera,closing);
poly = mask2poly(maschera,'exact');
ax = axes;
imagesc(img)
axis square; axis off; title('Draw a ROR')
hold on
plot(poly(2:end,1),poly(2:end,2),'g','Linewidth',2)
hold off
colormap gray
[RORmask RORpos] = drawRoi(ax);
close(gcf);

%% Timeline delle ROI C e I singole e mediate con i label
for i = 1:size(ipsiArray,4)
    tIpsi(i,:) =  timeline(roiMovie(ipsiArray(:,:,:,i),maschera));
    t_ror_ipsi(i,:) = timeline(roiMovie(ipsiArray(:,:,:,i),RORmask));
end
for i = 1:size(contraArray,4)
    tContra(i,:) =  timeline(roiMovie(contraArray(:,:,:,i),maschera));
    t_ror_Contra(i,:) = timeline(roiMovie(contraArray(:,:,:,i),RORmask));
end

% timelines
subplot(2,3,[1 2])
plot(time,tContra,'Color',[1 .6 .6],'LineWidth',.7)
hold on; cp = plot(time,mean(tContra,1),'r','LineWidth',1.2);
plot(time,tIpsi,'Color',[.6 .6 1],'LineWidth',.7)
ip = plot(time,mean(tIpsi,1),'b','LineWidth',1.2);
yl=get(gca,'YLim');
line([0 0],[-10 10],'color','k');line([-10 10],[0 0],'color','k');
line([time(startBound) time(startBound)],[-10 10],'color','g','LineWidth',.7);
line([time(endBound) time(endBound)],[-10 10],'color','g','LineWidth',.7);
set(gca,'XLim',[time(1) time(end)]); set(gca,'YLim',yl)
% peak detection
tlI = mean(tIpsi,1);
tlC = mean(tContra,1);
[mI,mII] = min(tlI(:,startBound:endBound),[],2);
[mC,mCI] = min(tlC(:,startBound:endBound),[],2);
plot(time(mII+startBound-1),mI,'s','color','b','MarkerSize',7,'MarkerFaceColor','b')
plot(time(mCI+startBound-1),mC,'s','color','r','MarkerSize',7,'MarkerFaceColor','r')
hold off
legend([cp ip],'Contra','Ipsi','location','best')
% immagini
total = cat(3,mean(mean(contraArray(:,:,startBound:endBound,:),4),3),mean(mean(ipsiArray(:,:,startBound:endBound,:),4),3));
clims = [min(total(:)) max(total(:))];
subplot(2,3,3)
contraImg = mean(mean(contraArray(:,:,startBound:endBound,:),4),3); % Fitered Image
imagesc(contraImg,clims)
hold on; plot(poly(2:end,1),poly(2:end,2),'g','Linewidth',1); hold off
colormap gray; axis square; axis off
title('Contra img')
subplot(2,3,6)
ipsiImg = mean(mean(ipsiArray(:,:,startBound:endBound,:),4),3); % Filtered Image
imagesc(ipsiImg,clims)
hold on; plot(poly(2:end,1),poly(2:end,2),'g','Linewidth',1); hold off
colormap gray; axis square; axis off
title('Ipsi img')
% ODI distribution
% c = roiMovie(unfiltContraIMG,maschera);       % ODI con img non filtrate
% i = roiMovie(unfiltIpsiIMG,maschera);         % ODI con img non filtrate
c = roiMovie(contraImg,maschera);   % ODI con img filtrate
i = roiMovie(ipsiImg,maschera);     % ODI con img filtrate
odi = (c(:)-i(:))./(c(:)+i(:));
% odi = (abs(c(:))-abs(i(:)))./(abs(c(:))+abs(i(:)));
subplot (2,3,[4 5])
histogram(odi,-1:.025:1,'FaceColor',[0 0 0]),
yl = get(gca,'YLim'); line([0 0],[0 1000],'color','r'); set(gca,'YLim',yl)
title(['ODI mean:' num2str(nanmean(odi))])
set(gcf,'Position',[420 240 1200 700])

%% Misure
Path_parts = regexp(PathName,'\','split');
temp = Path_parts(end-1);
name_parts = regexp(temp{1},'_','split');
answer = inputdlg('Enter mice number.');
% Mice info
results.recordingDate = name_parts{2};
results.cage = Path_parts{end-2};
results.miceID = name_parts{1};
results.miceNumber = answer{1};
% Amplitude
results.contraAmplitude = nanmean(c(:));
results.ipsiAmplitude = nanmean(i(:));
results.odi = nanmean(odi);
% Area
results.areaIpsi_Px = sum(maschera(:));
rang = max(contraImg(:)) - min(contraImg(:));
absTreshROI = min(contraImg(:)) + rang*tresholdROI;
contramaschera = contraImg<absTreshROI;
results.areaContra_Px = sum(contramaschera(:));
% Distributions
results.odiDistribution = odi;
results.contraWaveform = mean(tContra,1);
results.ipsiWaveform = mean(tIpsi,1);
% Peak & latency
results.contraPeak = mC;
results.contraLatency = time(mCI+startBound-1);
results.ipsiPeak = mI;
results.ipsiLatency = time(mII+startBound-1);
% SNR
results.ipsiSNR = abs(mean(min(tIpsi(:,startBound:endBound),[],2)./std(tIpsi(:,1:10),[],2)));
results.contraSNR = abs(mean(min(tContra(:,startBound:endBound),[],2)./std(tContra(:,1:10),[],2)));
% Time
results.time = time;
% ROR
results.ipsiReref_Timeline = mean(t_ror_ipsi,1);
results.contraReref_Timeline = mean(t_ror_Contra,1);
% Save files
[File,Path,FI] = uiputfile([PathName results.miceNumber '_' results.miceID '_' results.recordingDate '-results' '.mat']);
if FI
    mt = matfile([Path filesep File]);
    mt.results = results;
end




%% Rifinire la ROI
ax = axes;
imagesc(img)
axis square; axis off; title('Select the ROI')
hold on
plot(poly(2:end,1),poly(2:end,2),'g','Linewidth',2)
hold off
colormap gray
[newROI, ~] = drawRoi(ax);
maschera = maschera & newROI;
poly = mask2poly(maschera,'exact');
imagesc(img)
axis square; axis off;hold on
plot(poly(2:end,1),poly(2:end,2),'y','Linewidth',2); hold off
%% Plot with ROR
figure;
plot(mean((tIpsi-t_ror_ipsi),1),'color',[.6 .6 1]); hold on;
plot(mean(tIpsi,1),'b');
plot(mean((tContra-t_ror_Contra),1),'color',[1 .6 .6]); hold on;
plot(mean(tContra,1),'r'); hold off
legend('Reref IPSI','IPSI','reref CONTRA','CONTRA')
%% Join 2 results files

[FileName,PathName,FilterIndex] = uigetfile('C:\Users\Leonardo\Desktop\DATI_LSD1\','Multiselect','on');
if FilterIndex
    mf = matfile([PathName FileName{1}],'Writable',true);
    mf2 = matfile([PathName FileName{2}]);
    
    results = mf.results;
    results2 = mf2.results;
    results.contraAmplitude = nanmean([results.contraAmplitude results2.contraAmplitude]);
    results.ipsiAmplitude = nanmean([results.ipsiAmplitude results2.ipsiAmplitude]);
    results.odi = nanmean([results.odi results2.odi]);
    
    results.areaIpsi_Px = nanmean([results.areaIpsi_Px results2.areaIpsi_Px]);
    results.areaContra_Px = nanmean([results.areaContra_Px results2.areaContra_Px]);
    
    for i = 1:length(results.odiDistribution);
        if isnan(results.odiDistribution(i)) && isnan(results2.odiDistribution(i))
            results.odiDistribution(i) = NaN;
        elseif isnan(results.odiDistribution(i)) && ~isnan(results2.odiDistribution(i))
            results.odiDistribution(i) = results2.odiDistribution(i);
        elseif ~isnan(results.odiDistribution(i)) && isnan(results2.odiDistribution(i))
            results.odiDistribution(i) = results.odiDistribution(i);
        elseif ~isnan(results.odiDistribution(i)) && ~isnan(results2.odiDistribution(i))
            results.odiDistribution(i) = nanmean([results.odiDistribution(i) results2.odiDistribution(i)]);
        end
    end
    
    results.contraWaveform = mean([results.contraWaveform; results2.contraWaveform],1);
    results.ipsiWaveform = mean([results.ipsiWaveform; results2.ipsiWaveform],1);
    
    results.ipsiSNR = nanmean([results.ipsiSNR results2.ipsiSNR]);
    results.contraSNR = nanmean([results.contraSNR results2.contraSNR]);
    
    results.ipsiReref_Timeline = mean([results.ipsiReref_Timeline; results2.ipsiReref_Timeline],1);
    results.contraReref_Timeline = mean([results.contraReref_Timeline; results2.contraReref_Timeline],1);
    
    mf.results = results;
end
