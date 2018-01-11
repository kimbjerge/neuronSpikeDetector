clear all;
close all;
clc;

CorrelationType = 'NXCOR_2D_General';
AlgorithmToTest = CorrelationType;

PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate,'\rez.mat'));
% ------------- Signal setup -----------------
fs = 30000; % Hz
signalOffset = 0; % seconds
signalLength_s = 10; % seconds
% ---------------- Template -------------------
findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
MaximumNumberOfTemplates = 64;
% -------------- Matching Setup ---------------
if strcmp(AlgorithmToTest, 'XCOR_2D') == 1 || strcmp(AlgorithmToTest, 'XCOR_1D') == 1 || ...
   strcmp(AlgorithmToTest, 'XCOR_2D_GPU') == 1 || strcmp(AlgorithmToTest, 'NXCOR_2D') == 1 || ...
   strcmp(AlgorithmToTest, 'NXCOR_2D_GPU') == 1 || strcmp(AlgorithmToTest, 'NXCOR_2D_General') == 1

    IsAlgorithmSimilarityBased = 'YES'; % 'YES' for correlation based, 'NO' for difference based
else
    IsAlgorithmSimilarityBased = 'NO'; % 'YES' for correlation based, 'NO' for difference based
end
% --------------- Debug/Figures ---------------
OptimizeTheThresholdsIndividually = 'YES';
PrecisionWeight = 0.7;
RecallWeight = 1 - PrecisionWeight;
% ----------------- Test SETUP ----------------
channelsToTest = 15;

for K = 1 : numel(channelsToTest)

    numberOfChannelToEvaluate = channelsToTest(K);
    %ThresholdToTest = fliplr(0.5*10^8:0.1*10^8:10*10^8);
    ThresholdToTest = 0.1:0.01:0.9;
    channels = num2str(numberOfChannelToEvaluate);
    load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/CorrelationResultMatrix.mat'));
    load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/SpikeOffsetMatrix.mat'));
    load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/TemplatesTestingMatrix.mat'));

    %% 
    mainCounter = 1;
    for I = 1 : (numel(ThresholdToTest))
        thresHoldThisRun = ThresholdToTest(I);
            counter = 1;
            for Y = 1: MaximumNumberOfTemplates
                if numel(find(TemplatesTestingMatrix == Y)) > 0

                    templateCurrentlyTesting = Y;

                    [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, rez, fs );

                    [finalResultPeaks, finalResultTimes] = GetValuesAboveThreshold(CorrelationResultMatrix(:,Y), thresHoldThisRun, IsAlgorithmSimilarityBased);

                    [Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, 'NO');

                    [precision, recall] = GenerateConfusionMatrix(finalResultTimes, rez_st3_templateRelevant);

                    HitrateArray(counter) = Hitrate;
                    AccuracyArray(counter) = Accuracy;
                    extraSpikesArray(counter) = extraSpikes;
                    precisionArray(counter) = precision;
                    recallArray(counter) = recall;
                    counter = counter + 1;
                end  
            end

            meanPrecision(mainCounter) = mean(precisionArray);
            stdPrecision(mainCounter) = std(precisionArray);
            meanRecall(mainCounter) = mean(recallArray);
            stdrecall(mainCounter) = std(recallArray);
            mainCounter = mainCounter + 1;      
    end

    figure;
    plot(ThresholdToTest,meanPrecision)
    hold on;
    plot(ThresholdToTest,stdPrecision, 'g');
    hold on;
    plot(ThresholdToTest,meanRecall, 'r');
    hold on;
    plot(ThresholdToTest,stdrecall, 'm');
    hold off;
    title(['Threshold Analysis ' CorrelationType,' - Channelwidth: ', num2str(numberOfChannelToEvaluate)]);
    legend('Mean Precision', 'STD Precision', 'Mean Recall', 'STD Recall');
    xlabel('Threshold values');
    ylabel('Rate');
    
    
    OptimalThresholdTemplate = zeros(1, MaximumNumberOfTemplates);
    MatrixToOptimize = (meanPrecision.*PrecisionWeight)+(meanRecall.*RecallWeight);
    [OptimalThresholdValue,OptimalThresholdInd]  = max(MatrixToOptimize);
    
    OptimalThresholdTemplate = repmat(ThresholdToTest(OptimalThresholdInd), 1, MaximumNumberOfTemplates);
    
    fprintf(CorrelationType);
    fprintf('\nMaximum Obtainable precisionrate using combined threshold: %.3f\n', meanPrecision(OptimalThresholdInd));
    fprintf('Maximum Obtainable Recallrate using combined threshold: %.3f\n', meanRecall(OptimalThresholdInd));
    fprintf('Selected combined threshold is: %.3f\n', ThresholdToTest(OptimalThresholdInd));
    pathToSaveTheFile = strcat(DiectoryToEvaluate, '\OptimalThreshold\', CorrelationType, '\channels_', num2str(channelsToTest)); 
    if exist(pathToSaveTheFile) == 0
        mkdir(pathToSaveTheFile);
    end
    save(strcat(pathToSaveTheFile, '\OptimalCombinedTemplateThresholdMap.mat'),'OptimalThresholdTemplate','-v7.3');
    
end

