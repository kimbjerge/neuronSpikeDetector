clear all;
close all;
%clc;

CorrelationType = 'Laplacian';
AlgorithmToTest = CorrelationType;

PrePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
%DiectoryToEvaluate = 'C:\Users\Morten Buhl\Desktop\Simulation_10min_30kHz_2Noise_DefVals';
addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate,'\rez.mat'));
EmouseGroundTruth = load(strcat(DiectoryToEvaluate, '\eMouseGroundTruth.mat'));
% ------------- Signal setup -----------------
fs = 30000; % Hz
signalOffset = 0; % seconds
signalLength_s = 10; % seconds
% ---------------- Template -------------------
findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
MaximumNumberOfTemplates = 64;
% -------------- Matching Setup ---------------
IsAlgorithmSimilarityBased = IsAlgorithmSimilarityBasedFunc(CorrelationType);
% --------------- Debug/Figures ---------------
PrecisionWeight = 0.7;
RecallWeight = 1 - PrecisionWeight;
% ----------------- Test SETUP ----------------
channelsToTest = 5;%1:2:31;%1:2:31;
NumberOfTemplateSamplesUsed = 9; %11:6:61
ShowThresholdAnalysisFigure = 'YES';
RunningGaussianScalaTest = 'NO';

ThresholdToTest = 0.2:0.02:1; % ONLY FOR LAPLACIAN

% figure('rend','painters','pos',[500 500 1000 400]);
% %SubPlot1 = subplot(1,2,1);
% %title('Receiver operating characteristic (ROC)');
% %hold on;
% %xlabel('False positive rate (FPR) (Fallout)');
% %ylabel('True positive rate (TPR) (Recall)');
% 
% %SubPlot2 = subplot(1,2,2);
% xlim([0 0.0005]);
% hold on;
% ylim([0.9 1]);
% title('ROC (zoomed)');
% xlabel('False positive rate (FPR) (Fallout)');
% ylabel('True positive rate (TPR) (Recall)');

figure('rend','painters','pos',[500 500 750 400]);
%SubPlot1 = subplot(1,2,1);
%title('Receiver operating characteristic (ROC)');
%hold on;
%xlabel('False positive rate (FPR) (Fallout)');
%ylabel('True positive rate (TPR) (Recall)');

%SubPlot2 = subplot(1,2,2);
hold on;
legend(CorrelationType,'Location','southeast');
title('Precision-Recall Curve');
xlabel('True positive rate (TPR) (Recall)');
ylabel('Positive predictive value (PPV) (Precision)');


for outer = 1 : 14
    
    if outer == 14
        channelsToTest = 32;
        NumberOfTemplateSamplesUsed = 61;
    end
    
    for X = 1 : numel(NumberOfTemplateSamplesUsed)
        templateSampleSizeEvaluating = NumberOfTemplateSamplesUsed(X);

        for K = 1 : numel(channelsToTest)
            numberOfChannelToEvaluate = channelsToTest(K);

            channels = num2str(numberOfChannelToEvaluate);
           
            load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/CorrelationResultMatrix.mat'));
            load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/SpikeOffsetMatrix.mat'));
            load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/TemplatesTestingMatrix.mat'));


            mainCounter = 1;

            for I = 1 : (numel(ThresholdToTest))
                thresHoldThisRun = ThresholdToTest(I);
                counter = 1;

                for Y = 1: MaximumNumberOfTemplates
                    if numel(find(TemplatesTestingMatrix == Y)) > 0

                        templateCurrentlyTesting = Y;

                        [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, rez, fs, templateSampleSizeEvaluating);

                        if strcmp(RunningGaussianScalaTest, 'YES') == 1
                            rez_st3_templateRelevant(:,1) = floor(rez_st3_templateRelevant(:,1)./2)+1;
                        end

                        grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, EmouseGroundTruth, fs, templateSampleSizeEvaluating, rez );

                        [finalResultPeaks, finalResultTimes] = GetValuesAboveThreshold(CorrelationResultMatrix(:,Y), thresHoldThisRun, IsAlgorithmSimilarityBased);
                        totalSamples = size(CorrelationResultMatrix);
                        totalSamples = totalSamples(1);

                        [Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, 'NO');

                        [precision, recall, fallout, TP, TN, FP, FN] = GenerateConfusionMatrixFromGTWithSlack(finalResultTimes, grundTruth, 3, totalSamples);


                        HitrateArray(counter) = Hitrate;
                        AccuracyArray(counter) = Accuracy;
                        extraSpikesArray(counter) = extraSpikes;
                        precisionArray(counter) = precision;
                        recallArray(counter) = recall;
                        falloutArray(counter) = fallout;

                        counter = counter + 1;
                    end
                end

                meanPrecision(mainCounter) = mean(precisionArray);
                stdPrecision(mainCounter) = std(precisionArray);
                meanRecall(mainCounter) = mean(recallArray);
                stdrecall(mainCounter) = std(recallArray);
                meanFallout(mainCounter) = mean(falloutArray);
                stdFallout(mainCounter) = std(falloutArray);

                mainCounter = mainCounter + 1;  

            end
        end
    end
    
    %plot(SubPlot1,[1 meanFallout],[1 meanRecall]);

    %plot(SubPlot2,[1 meanFallout],[1 meanRecall]);
    
    %plot([1 meanFallout],[1 meanRecall]);
    plot([meanRecall],[meanPrecision]);

    legendText{outer} = strcat(['Size: ', num2str(channelsToTest),' x ', num2str(NumberOfTemplateSamplesUsed)]);

    meanPrecision = 0;
    stdPrecision = 0;
    meanRecall = 0;
    stdrecall = 0;
    meanFallout = 0;
    stdFallout = 0; 
    
    if outer < 14
        channelsToTest = channelsToTest + 2;
        NumberOfTemplateSamplesUsed = NumberOfTemplateSamplesUsed + 4;
    end
end

%plot([0 1],[0 1],'--k');
legend(legendText,'Location','southeast');

print -depsc TemplateSizeRocCurve