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

%cluster_id = 11; %default 6 %This fit from channel 0 is 1 and 1 is 2
fs = 30000;
length = 1000;
numberOfTemplates = 64;
numberOfSpikeTimesAllTemplates = zeros(numberOfTemplates,1);

%% Organize data with chanMap, remove unconnected channels

for i = 1:numberOfTemplates
    spikeTimes     = rez.st3(rez.st3(:,2)==i);
    spikeTimes     = spikeTimes(spikeTimes < (length*fs)); 
    numberOfSpikeTimesAllTemplates(i) = numel(spikeTimes);
end




 
