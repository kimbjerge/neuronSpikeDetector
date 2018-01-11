%Code to obtain the raster and PETH of each cluster around the light evoked
%timestamp
%And extract the average waveform for: a chosen cluster, before the light,
%after the ligh, and around the pulse of the alser
%Done the 06/09/2017 by MB

clc
clear all
close all

rez_file = 'C:\Users\Morten Buhl\Desktop\2017-04-21_16-58-45\rez.mat';
fid = fopen('C:\Users\Morten Buhl\Desktop\2017-04-21_16-58-45\piroska_example_short.dat', 'r');
events_file = 'C:\Users\Morten Buhl\Desktop\2017-04-21_16-58-45\all_channels.events';

load(rez_file);

cluster_id = 11; %default 6 %This fit from channel 0 is 1 and 1 is 2

NchanTOT = rez.ops.NchanTOT;
dat = fread(fid, [NchanTOT inf], '*int16'); % Number_channels * length of recordings (sample unit)
fclose(fid);
dat = dat(rez.ops.chanMap(rez.connected),:);

%% Organize data with chanMap, remove unconnected channels
if 1
win = [-100:100]';
spikeTimes     = rez.st3(rez.st3(:,2)==cluster_id);

WAVE = NaN(size(dat,1),numel(win),length(spikeTimes));
for i = 1:length(spikeTimes)
    spkwin = spikeTimes(i) + win; 
    WAVE(:,:,i) = dat(:,spkwin);
end


meanWave = mean(WAVE,3);
figure
surf(meanWave,'edgecolor','none')

end
 
