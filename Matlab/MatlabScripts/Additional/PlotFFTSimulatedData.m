clear all;
close all;
clc;

%% Setup
% ------------ Path/Directory ---------------
PrePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
addpath(DiectoryToEvaluate);
DirectoryFiltering = strcat(PrePath,'Generated_Emouse_Data\Filtering');
addpath(DirectoryFiltering);
load(strcat(DiectoryToEvaluate, '\rez.mat'));
% ------------- Signal setup -----------------
fs = 30000; % Hz
filter = 'NO';
filterType = 'Cheby2';
signalGain = 1; % gg
signalOffset = 0; % seconds
signalLength_s = 10; % seconds
% --------------- Debug/Figures ---------------
ViewFiguresRunning = 'NO';
ShowFunctionExcTime = 'NO';

%% Read data

    Oldsignal = PrepareData( strcat(DiectoryToEvaluate,'\sim_binary.dat'), 1:32, rez, signalOffset, ...
                                                                 signalLength_s, signalGain, filter, filterType, fs, ViewFiguresRunning, ShowFunctionExcTime);

%% Plot FFT

    % 2D FFT of signal start
    figure;
    plot(Oldsignal);
    title('Signal 10 seconds of 32 channels');
    xlabel('Sample #');
    ylabel('Amplitude');    

    fftVar = fft2(Oldsignal);
    L = length(Oldsignal);
    P2 = abs(fftVar/L);
    P1 = P2(1:L/2+1,:);
    P1(2:end-1) = 2*P1(2:end-1);

    f = fs*(0:(L/2))/L;


    figure;
    plot(f,P1);
    title('Single-Sided Amplitude Spectrum of 32 channels');
    xlabel('Frequency (Hz)');
    ylabel('|A(f)|');          
    % 2D FFT of signal end                  

%     F1=abs(fftshift(fft)/L);
%     %F1=fftshift(P1);
%     %F1=log(abs(fftshift(fft)));
%     % Downsample to make it plotable
%     F2= F1(1:100:300000,:);
%     f = fs*(0:L)/L;
%     %f = f(1:100:300000);
% 
%     figure;
%     surf(F2);
%     xlim([0 32]);
%     ylim([-10000 10000]);
%     xlabel('Channels');
%     ylabel('Frequency (Hz)');
%     zlabel('|A(f)|');     
%     %fft surf

    L = length(Oldsignal);

    for fftCounter = 1:32
        fftTest(:,fftCounter) = fft(Oldsignal(:,fftCounter));
        P2(:,fftCounter) = abs(fftTest(:,fftCounter)/L);
    end
    %fftVar = fft2(Oldsignal);


    P1 = P2(1:L/2+1,:);
    P1(2:end-1) = 2*P1(2:end-1);

    f = fs*(0:(L/2))/L;

    f = f(1:150000);

    %// Define the x values
    x = f.';
    xMat = repmat(x, 1, 32); %// For plot3

    %// Define y values
    y = 1:32;
    yMat = repmat(y, numel(x), 1); %//For plot3

    %// Define z values
    zMat = P1;

    figure('pos',[500 500 900 500]);
    plot3(xMat(1:50:L/2,:), yMat(1:50:L/2,:), zMat(1:50:L/2,:)); %// Make all traces blue
    grid;
    xlim([0 7500]);
    ylim([1 32]);
    zlim([0 7.5]);
    title('Single-Sided Amplitude Spectrum of 32 channels');   
    xlabel('Frequency (Hz)');
    ylabel('Channels');
    zlabel('Magnitude');     
    view(63,43); %// Adjust viewing angle so you can clearly see data





    % -----------------------------------------
%         fftVar = fft2(Oldsignal);
%         L = length(Oldsignal);
%         %P2 = 20*log10(abs(fft/L));
%         P2 = abs(fftVar/L);
%         P1 = P2(1:L/2+1,:);
%         P1(2:end-1) = 2*P1(2:end-1);
% 
%         f = fs*(0:(L/2))/L;
% 
%         f = f(1:150000);
% 
%         %// Define the x values
%         x = f.';
%         xMat = repmat(x, 1, 32); %// For plot3
% 
%         %// Define y values
%         y = 1:32;
%         yMat = repmat(y, numel(x), 1); %//For plot3
% 
%         %// Define z values
%         zMat = P1;
% 
%         figure;
%         plot3(xMat(1:100:L/2,:), yMat(1:100:L/2,:), zMat(1:100:L/2,:)); %// Make all traces blue
%         grid;
%         xlim([0 7500]);
%         ylim([0 32]);
%         xlabel('Frequency (Hz)');
%         ylabel('Channels');
%         zlabel('Magnitude');     
%         view(60,60); %// Adjust viewing angle so you can clearly see data
%                     
figure,
spectrogram(Oldsignal(:,5),128,120,128,fs,'yaxis')



% Time Domain
channelChosen = 5;
figure('pos',[500 500 900 350]);
plot(Oldsignal(:,channelChosen));
hold on;
grid on;
title([ 'Time Domain Analysis of Channel ', num2str(channelChosen) ]);
xlabel('Samples');
ylabel('Amplitude');


figure('pos',[500 500 900 350]);
surf(Oldsignal(1:1000,:));
hold on;
grid on;
title([ 'Time Domain Analysis' ]);
xlabel('Samples');
ylabel('Amplitude');