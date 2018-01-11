clear all; clc; close all;

TemplateFilePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\Generated_Emouse_Data\Simulation_10min_30kHz_DefVals\templates.npy';                                       
TemplateToTest = 64;
ChannelsInTemplateToUse = [1:32];
TemplateGain = 10;
NPYPath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\masterProject\npy-matlab-master';

%% - Setup
NumberOfSamplesInTemplate = 82;
TemplateSampleStart = 22;
ChannelsToRunTemplateMatchingAgainst = ChannelsInTemplateToUse;


%% - Get Template data
addpath(NPYPath);    
template1 = readNPY(TemplateFilePath);

x = template1(TemplateToTest,:,:);
template = squeeze(x);
template = double(template);
template = template((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);


x = template1(5,:,:);
template2 = squeeze(x);
template2 = double(template2);
template2 = template2((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);

x = template1(17,:,:);
template3 = squeeze(x);
template3 = double(template3);
template3 = template3((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);

x = template1(20,:,:);
template4 = squeeze(x);
template4 = double(template4);
template4 = template4((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);

x = template1(31,:,:);
template5 = squeeze(x);
template5 = double(template5);
template5 = template5((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);




x = template1(2,:,:);
template6 = squeeze(x);
template6 = double(template6);
template6 = template6((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);

x = template1(62,:,:);
template7 = squeeze(x);
template7 = double(template7);
template7 = template7((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);


%% - Mulitply Template
if strcmp(TemplateGain, 'Squared');
    template = template.^2;
    template2 = template2.^2;
    template3 = template3.^2;
    template4 = template4.^2;
    template5 = template5.^2;
    template6 = template6.^2;
    template7 = template7.^2;
else
    template = template .* TemplateGain;
    template2 = template2 .* TemplateGain;
    template3 = template3 .* TemplateGain;
    template4 = template4 .* TemplateGain;
    template5 = template5 .* TemplateGain;
    template6 = template6 .* TemplateGain;
    template7 = template7 .* TemplateGain;
end


figure
surf(template)
title(['Template ' num2str(TemplateToTest)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude')   

%% Good ones plot
figure('pos',[0 0 1000 600]);
azimuth = -27;
zenith = 10;

subplot(2,2,1);
surf(template2)
hold on;
view(azimuth,zenith);
axis tight
title(['Template ' num2str(5)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude')   

subplot(2,2,2);
surf(template3)
hold on;
view(azimuth,zenith);
axis tight
title(['Template ' num2str(17)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude')   

subplot(2,2,3);
surf(template4)
hold on;
view(azimuth,zenith);
axis tight
title(['Template ' num2str(20)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude') 

subplot(2,2,4);
surf(template5)
hold on;
view(azimuth,zenith);
axis tight
title(['Template ' num2str(31)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude') 

%% Bad ones plots
figure('pos',[500 500 1000 400]);

subplot(1,2,1);
surf(template6)
hold on;
view(azimuth,zenith);
axis tight
title(['Template ' num2str(2)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude')   

subplot(1,2,2);
surf(template7)
hold on;
view(azimuth,zenith);
axis tight
title(['Template ' num2str(62)])
xlabel('Channel [#]'),ylabel('Samples'), zlabel('Amplitude')   