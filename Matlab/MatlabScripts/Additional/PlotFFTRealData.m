clear all;
close all;
clc;

%% Setup

% ------------ Path/Directory ---------------
PrePath = 'E:\liveRecording\';

DiectoryToEvaluate = strcat(PrePath,'liveRecording masterProject');
addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate, '\rez.mat'));
pathToNPYMaster = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\masterProject\npy-matlab-master';
% ------------- Signal setup -----------------
fs = 30000; % Hz
signalOffset = 0; % seconds
signalLength_s = 10; % seconds


RecordLength = signalLength_s; %seconds
SecondsOffset = signalOffset;
RecordSampleRate = fs; %30kHz preferably
TotalSamples = RecordLength*RecordSampleRate;
TotalSamplesOffset = SecondsOffset*RecordSampleRate;

%% Read data

% Read data from file
fileID = fopen(strcat(DiectoryToEvaluate,'\piroska_example_short.dat'));
Data = fread(fileID, 700000000, 'int16');
%Data = fread(fileID, 'int16');
fclose(fileID);

% Get data from file and setup accoring to channel map
NumberOfSamples = TotalSamples;
NumberOfChannelsReal = 32;
channelData = zeros(NumberOfSamples, NumberOfChannelsReal);

invChanMap = (1:32); 

counter = 1;
SampleIndex = 1;
startIndex = (TotalSamplesOffset*NumberOfChannelsReal)+1;
for I = startIndex: (startIndex-1) + NumberOfSamples*NumberOfChannelsReal  
    modules = mod(I,NumberOfChannelsReal);
    
    if modules == 0
    channelData(SampleIndex, invChanMap(32)) = Data(I); 
    else
    channelData(SampleIndex, invChanMap(modules)) = Data(I);
    end
    
    
    if counter >= NumberOfChannelsReal
        counter = 0;
        SampleIndex = SampleIndex + 1;
    end 
    counter = counter + 1;
end

channelData = channelData(:, 1:32);

%% Plot FFT

L = length(channelData);

for fftCounter = 1:32
    fftTest(:,fftCounter) = fft(channelData(:,fftCounter));
    P2(:,fftCounter) = abs(fftTest(:,fftCounter)/L);
end

P1 = P2(1:L/2+1,:);
P1(2:end-1) = 2*P1(2:end-1);

f = fs*(0:(L/2))/L;
f = f(1: L/2);

%// Define the x values
x = f.';
xMat = repmat(x, 1, 32); %// For plot3

%// Define y values
y = 1:32;
yMat = repmat(y, numel(x), 1); %//For plot3

%// Define z values
zMat = P1;

% 3D FFT
figure('pos',[500 500 900 500]);
plot3(xMat(1:50:L/2,:), yMat(1:50:L/2,:), zMat(1:50:L/2,:));
grid;
xlim([0 7500]);
ylim([1 32]);
zlim([0 15]);
title('Single-Sided Amplitude Spectrum of 32 channels');   
xlabel('Frequency (Hz)');
ylabel('Channels');
zlabel('Magnitude');     
view(63,43); %// Adjust viewing angle so you can clearly see data

% Spectrogram
figure('pos',[500 500 900 350]);
spectrogram(channelData(:,5),128,120,128,fs,'yaxis')

% Periodogram
figure('pos',[500 500 900 350]);
[h, w] = periodogram(channelData(:,5));
plot(w*fs/(2*pi),10*log10(abs(h)));
hold on;
grid on;
title([ 'Periodogram Power Spectral Density Estimate' ]);
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');

% Time Domain
channelChosen = 5;
figure('pos',[500 500 900 350]);
plot(channelData(:,channelChosen));
hold on;
grid on;
title([ 'Time Domain Analysis of Channel ', num2str(channelChosen) ]);
xlabel('Samples');
ylabel('Amplitude');


figure('pos',[500 500 900 350]);
surf(channelData(1:1000,:));
hold on;
grid on;
title([ 'Time Domain Analysis' ]);
xlabel('Samples');
ylabel('Amplitude');