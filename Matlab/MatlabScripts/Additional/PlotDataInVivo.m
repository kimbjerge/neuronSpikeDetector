%clear all;
close all;
%%
% ------------ Path/Directory ---------------
PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\';

%DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
%DiectoryToEvaluate = 'C:\2017-04-21_16-58-45';

DiectoryToEvaluate = 'C:\Users\Morten Buhl\Desktop\2017-04-21_16-58-45';

isKiloSortTemplateMerged = 'NO';

addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate,'\rez.mat'));
pathToNPYMaster = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabLibs\npy-matlab-master';
pathToFunctions = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabFunctions';

RecordFile = strcat(DiectoryToEvaluate, '\piroska_example_short.dat');
TemplateFile = strcat(DiectoryToEvaluate,'\templates.npy');
addpath(pathToFunctions);
% ------------- Signal setup -----------------
MaximumChannelsToUse = 32;
NumberOfChannelsToInvestigate = 32; % Should be odd
ChannelsToInvestigate = 1:32; % If findTemplateOffsetAndChannelAutomatic YES: this is aut. overwritten!
fs = 30000; % Hz
filter = 'NO';
filterType = 'None';
signalGain = 1; % gg
signalOffset = 0; % seconds
signalLength_s = 10; % seconds
% ---------------- Template -------------------
templateGain = 1; % gg %20000 for SAD/SSD
templateCurrentlyTesting = 11; % This template is the best
templateSpikeOffset = 19; % sample offset
findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
MaximumNumberOfTemplates = 64;
% -------------- Matching Setup ---------------
threshold = .25000;
%threshold = 1.5;
%threshold = 3*10^8;
IsAlgorithmSimilarityBased = 'YES'; % 'YES' for correlation based, 'NO' for difference based
templateSizeTestingThisRound = 61;
MaximumNumberOfTemplateSamples = 32;
% --------------- Debug/Figures ---------------
ViewFiguresRunning = 'NO';
ShowProgressBar = 'NO';
ShowFunctionExcTime = 'NO';
PlotCCvsKilosort = 'YES';
TemplatesToTest = 1:64;
TemplatesToTestElements = numel(TemplatesToTest);
ShowComparasionInTheEnd = 'YES';


%% 
TimeStampOfInterest = 41758; % find in rez file

%%                    
template = PrepareTemplate( TemplateFile, templateCurrentlyTesting, [1:32], ...
                             templateGain, pathToNPYMaster, 'YES', ShowFunctionExcTime);
                                                             

%% Investigate if template is matched to signal by Kilosort
[ templatesPresent, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged(rez, MaximumNumberOfTemplates, isKiloSortTemplateMerged, signalLength_s, signalOffset, fs);


%% Find relevant channels to investigate based on the template signal                                                             
if strcmp(findTemplateOffsetAndChannelAutomatic, 'YES')
   [ mainChannel, templateSpikeOffset, ~ ] = GetTemplateInfo( template ); 
end

if NumberOfChannelsToInvestigate < MaximumChannelsToUse

    ChannelsToInvestigate = ChooseChannels(mainChannel,NumberOfChannelsToInvestigate);

    template = template(:,ChannelsToInvestigate);
end

if templateSizeTestingThisRound < MaximumNumberOfTemplateSamples
    template = template(ChooseTemplateSamples(templateSpikeOffset, templateSizeTestingThisRound),:);   
end



%% Get Data for the test

Oldsignal = PrepareDataInVivo( RecordFile, 1:32, rez, signalOffset, ...
                                 signalLength_s, signalGain, filter, filterType, fs, ViewFiguresRunning, ShowFunctionExcTime);
                                                                                                                                                                                 
                    
    %% Channel filter signal              
    %FiltSamples = ChannelFilter( Oldsignal, 1:MaximumChannelsToUse, filterType, signalLength_s, fs, ViewFiguresRunning );
       

 %%   
 [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, rez, fs, templateSizeTestingThisRound, isKiloSortTemplateMerged );
%% Plot
templateSize = size(template);

% figure;
% surf(Oldsignal(TimeStampOfInterest-templateSpikeOffset:TimeStampOfInterest-templateSpikeOffset+templateSize(1),:));
% title('Unfiltered Raw Data')
% xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')

% figure;
% forSaving = Oldsignal(TimeStampOfInterest-(templateSpikeOffset+40):TimeStampOfInterest-(templateSpikeOffset)+templateSize(1)+30,2);
% plot(Oldsignal(TimeStampOfInterest-(templateSpikeOffset+20):TimeStampOfInterest-(templateSpikeOffset)+templateSize(1)+20,2));
% title('Unfiltered Raw Data')
% xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')

%save('forSaving.mat','forSaving','-v7.3');


figure('rend','painters','pos',[200 200 1000 450]);
h = surf(template);
xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
title('Template generated from in-vivo data, template #11')
%print -depsc InVivoTemplate11


figure('rend','painters','pos',[200 200 1000 450]);
h = surf(Oldsignal(1:templateSize(1),:));
xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
title('Unfiltered raw in-vivo data')
%print -depsc InVivoSignalNoSpike



figure('rend','painters','pos',[200 200 900 500]);
h = surf(Oldsignal(TimeStampOfInterest:TimeStampOfInterest+templateSize(1),:));
%colormap jet;
alpha(h, 0.2);
xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
title('Unfiltered raw data overlaid with template #11')
hold on
h1 = surf(template.*6000);
%print -depsc InVivoSignalOverlaidTemplate

