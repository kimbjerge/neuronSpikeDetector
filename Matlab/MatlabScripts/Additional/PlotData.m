%clear all;
close all;
%%
% ------------ Path/Directory ---------------
%DiectoryToEvaluate = 'Simulation_10min_30kHz_DefVals';
DiectoryToEvaluate = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\Simulation_10min_30kHz_DefVals';
addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate,'\rez.mat'));
pathToNPYMaster = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabLibs\npy-matlab-master';
pathToFunctions = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabFunctions';

RecordFile = strcat(DiectoryToEvaluate, '\sim_binary.dat');
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
templateCurrentlyTesting = 1; % The template we are matching against
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
isKiloSortTemplateMerged = 'YES';

%% 
TimeStampOfInterest = 20317; % Bad template matching score
%TimeStampOfInterest = 293913+19; % Good template matching score



%%                    
template = PrepareTemplate( strcat(DiectoryToEvaluate,'\templates.npy'), templateCurrentlyTesting, [1:32], ...
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

    Oldsignal = PrepareData( RecordFile, 1:MaximumChannelsToUse, rez, signalOffset, ...
                                                                                 signalLength_s, signalGain, fs, ViewFiguresRunning, ShowFunctionExcTime);
                                                                                                                                                                                 
                    
    %% Channel filter signal              
    %FiltSamples = ChannelFilter( Oldsignal, 1:MaximumChannelsToUse, filterType, signalLength_s, fs, ViewFiguresRunning );
       

 %%   
     [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, rez, fs, templateSizeTestingThisRound, isKiloSortTemplateMerged );
%% Plot
templateSize = size(template);

figure;
surf(Oldsignal(TimeStampOfInterest-templateSpikeOffset:TimeStampOfInterest-templateSpikeOffset+templateSize(1),:));
title('Unfiltered Raw Data')
xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')

% figure;
% forSaving = Oldsignal(TimeStampOfInterest-(templateSpikeOffset+40):TimeStampOfInterest-(templateSpikeOffset)+templateSize(1)+30,2);
% plot(Oldsignal(TimeStampOfInterest-(templateSpikeOffset+20):TimeStampOfInterest-(templateSpikeOffset)+templateSize(1)+20,2));
% title('Unfiltered Raw Data')
% xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')

%save('forSaving.mat','forSaving','-v7.3');


figure('rend','painters','pos',[200 200 900 500]);
h = surf(Oldsignal(TimeStampOfInterest:TimeStampOfInterest+templateSize(1),:));
%colormap jet;
alpha(h, 0.2);
xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
title('Unfiltered raw data overlaid with template #1')
hold on
h1 = surf(template.*6000);
%print -depsc SignalOverlaidTemplate

