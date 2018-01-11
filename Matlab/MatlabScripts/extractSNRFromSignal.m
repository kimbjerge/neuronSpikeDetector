% clear all;
% close all;
% clc;
% 
% %% Setup
% AlgorithmToTest = 'Laplacian'; %SobelNXCOR
% 
% % ------------ Path/Directory ---------------
% %PrePath = 'D:\Dropbox\Master Engineer\Master Thesis\';
% %PrePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\';
% PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
% 
% DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
% %DiectoryToEvaluate = 'C:\Users\Morten Buhl\Desktop\Simulation_10min_30kHz_2Noise_DefVals';
% addpath(DiectoryToEvaluate);
% DirectoryFiltering = strcat(PrePath,'Generated_Emouse_Data\Filtering');
% addpath(DirectoryFiltering);
% load(strcat(DiectoryToEvaluate, '\rez.mat'));
% EmouseGroundTruth = load(strcat(DiectoryToEvaluate, '\eMouseGroundTruth.mat'));
% pathToNPYMaster = strcat(PrePath, 'masterProject\npy-matlab-master');
% pathToFFTXCORLib = strcat(PrePath, 'Matlab libs\XCoor using FFT'); % Leave out if not using XCOR_FFT algorithm
% pathToFibonacciLib = strcat(PrePath, 'Matlab libs\Fibonacci');
% pathToNormXcorr2General = strcat(PrePath, 'Matlab libs\normxcoor2_general');
% PathToFilteredData = strcat(DiectoryToEvaluate, '\FilteredData');
% % ------------- Signal setup -----------------
% MaximumChannelsToUse = 32;
% NumberOfChannelsToInvestigate = 5; % Should be odd
% ChannelsToInvestigate = 1:32; % If findTemplateOffsetAndChannelAutomatic YES: this is aut. overwritten!
% fs = 30000; % Hz
% filter = 'YES';
% filterType = 'Kilosort';
% signalGain = 1; % gg
% signalOffset = 0; % seconds
% signalLength_s = 10; % seconds
% % ---------------- Template -------------------
% templateGain = 10; % gg %20000 for SAD/SSD
% templateCurrentlyTesting = 30; % The template we are matching against. This is overwritten runtime
% templateSpikeOffset = 19; % sample offset
% findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
% MaximumNumberOfTemplates = 64;
% NumberOfTemplateSamplesUsed = 17; % 61
% MaximumNumberOfTemplateSamples = 61;
% % ------------- Sample size -----------------
% ConfLevel = '99%';
% ErrorMargin = 0.01;
% % -------------- Matching Setup ---------------
% threshold = repmat(.25000,1,MaximumNumberOfTemplates);
% HandleDriftChannel = 1;
% IsAlgorithmSimilarityBased = IsAlgorithmSimilarityBasedFunc(AlgorithmToTest);
% 
% if strcmp(AlgorithmToTest, 'LSAD') == 1 || strcmp(AlgorithmToTest, 'SSD') == 1 || ...
%     strcmp(AlgorithmToTest, 'SAD') == 1 || strcmp(AlgorithmToTest, 'LSSD') == 1 
% 
%     templateGain = 2000;
% end
% 
% % --------------- Debug/Figures ---------------
% ViewFiguresRunning = 'NO';
% 
% TemplatesToTest = 1:MaximumNumberOfTemplates;
% TemplatesToTestElements = numel(TemplatesToTest);
% SelectSpecificTemplatesToAvoidUsing = [64];
% TimeBaseSlack = 0;
% templateSize = 61;
% 
% 
% %% - Variables 
% NumberOfChannelsToInvestigate = 9;
% templateSizeTestingThisRound = 17;
counter = 1;
firstRun = 1;

for I = TemplatesToTest(1) : TemplatesToTest( TemplatesToTestElements )
    fprintf('Analysing spikes regarding template: %.0f\n', I);
    tic
    templateCurrentlyTesting = I;
    %% Get template for the test
    template = PrepareTemplate( TemplatesFile, templateCurrentlyTesting, [1:32], ...
                                                                     templateGain, pathToNPYMaster, 'NO', 'NO');

    %% Investigate if template is matched to signal by Kilosort
    [ templatesPresent, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged(rez, MaximumNumberOfTemplates, isKiloSortTemplateMerged, signalLength_s, signalOffset, fs);

    %% Find relevant channels to investigate based on the template signal                                                             
    if templatesPresent(templateCurrentlyTesting) > 0 && numel(find(SelectSpecificTemplatesToAvoidUsing == templateCurrentlyTesting)) == 0

        if strcmp(findTemplateOffsetAndChannelAutomatic, 'YES')
           [ mainChannel, templateSpikeOffset, ~ ] = GetTemplateInfo( template ); 
        end

        %% Get Data for the test
        if firstRun == 1
            signal = PrepareData( RecordFile, 1:MaximumChannelsToUse, rez, signalOffset, ...
                                                                                 signalLength_s, signalGain, fs, ViewFiguresRunning, ShowFunctionExcTime);

            firstRun = 0;
        end     
   
        %% Get ground truth!
        %grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, EmouseGroundTruth, fs, templateSizeTestingThisRound, rez );
        if strcmp(UsingSimulatedData, 'YES')
            grundTruth = ExtractGroundTruthInfoUnaffected( signalOffset, signalLength_s, templateCurrentlyTesting, EmouseGroundTruth, fs, rez );
            
            SpikeValue = zeros(1, numel(grundTruth.gtRes));
            
            for X = 1 : numel(grundTruth.gtRes)
    %             figure;
    %             surf(signal(grundTruth.gtRes(X)-templateSpikeOffset:grundTruth.gtRes(X)-templateSpikeOffset+templateSize,:));
    %             title('Unfiltered Raw Data')
    %             xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude') 
                SpikeValue(X) = signal(grundTruth.gtRes(X)-1, mainChannel); 
            end
        else
            [rez_st3_templateRelevant] = ExtractKilosortInfoUnaffected( signalOffset, signalLength_s , templateCurrentlyTesting, rez, fs, isKiloSortTemplateMerged );
             
            for X = 1 : numel(rez_st3_templateRelevant(:,1))
                SpikeValue(X) = signal(rez_st3_templateRelevant(X,1), mainChannel); 
            end
        end
        signal1D = reshape(signal,[1 MaximumChannelsToUse*signalLength_s*fs]);
        
        signal1D_rms = rms(signal1D);
        
        snr(counter) = abs(mean(SpikeValue)) / signal1D_rms;
        counter = counter + 1;        
        %fprintf('SNR of template(%.0f) is: %.2f dB \n',templateCurrentlyTesting, 20*log10(snr(counter-1)));
        
    else
         %fprintf('WARNING: The requested template(%.0f) is not present in the kilosort data!!! - A comparison would not make sense!\n', templateCurrentlyTesting);
    end


    ElapsedTime = toc;
    %fprintf('Processing this template(%.0f) took %.2f seconds.\n\n',templateCurrentlyTesting, ElapsedTime);
end

fprintf('\nCombined SNR is: %.2f dB \n', 20*log10(mean(snr)));
