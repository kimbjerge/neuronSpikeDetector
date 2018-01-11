clear all;
close all;
%clc;

CorrelationType = 'Laplacian';
AlgorithmToTest = CorrelationType;

PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
%DiectoryToEvaluate = 'C:\Users\Morten Buhl\Desktop\Simulation_10min_30kHz_2Noise_DefVals';
addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate,'\rez.mat'));
EmouseGroundTruth = load(strcat(DiectoryToEvaluate, '\eMouseGroundTruth.mat'));
pathToFibonacciLib = strcat(PrePath, 'Matlab libs\Fibonacci');
addpath(pathToFibonacciLib);
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
channelsToTest = 9;%1:2:31;%1:2:31;
NumberOfTemplateSamplesUsed = 17; %11:6:61
ShowThresholdAnalysisFigure = 'NO';
RunTemplateSamplesTest = 'YES';
RunningGaussianScalaTest = 'NO';


if strcmp(CorrelationType, 'SSD') == 1
    ThresholdToTest = fliplr(1*10^8:0.1*10^8:5*10^8); 
elseif strcmp(CorrelationType, 'SAD') == 1
    ThresholdToTest = fliplr(3*10^5:0.5*10^4:4.5*10^5); 
elseif strcmp(CorrelationType, 'NSSD') == 1
    ThresholdToTest = fliplr(0.1:0.01:1.6); 
elseif strcmp(CorrelationType, 'LaplacianNSSD') == 1
    ThresholdToTest = fliplr(0.01:0.005:1); 
elseif strcmp(CorrelationType, 'LaplacianNSAD') == 1
    ThresholdToTest = fliplr(0.05:0.05:1);   
elseif strcmp(CorrelationType, 'XCOR_1D') == 1
    ThresholdToTest = 3000:100:40000; 
elseif strcmp(CorrelationType, 'XCOR_2D') == 1
    ThresholdToTest = 3000:100:40000; 
elseif strcmp(CorrelationType, 'XCOR_FFT') == 1
    ThresholdToTest = 1:500:3000;     
elseif strcmp(CorrelationType, 'NSAD') == 1
    ThresholdToTest = fliplr(0.2:0.02:1); 
else
    ThresholdToTest = 0.2:0.02:1; % NXCOR
end

for X = 1 : numel(NumberOfTemplateSamplesUsed);

    templateSampleSizeEvaluating = NumberOfTemplateSamplesUsed(X);
    
for K = 1 : numel(channelsToTest)

    
    numberOfChannelToEvaluate = channelsToTest(K);
    
   
    channels = num2str(numberOfChannelToEvaluate);
    if strcmp(RunTemplateSamplesTest, 'YES')
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/CorrelationResultMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/SpikeOffsetMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/TemplatesTestingMatrix.mat'));
    else
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/CorrelationResultMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/SpikeOffsetMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType,'/',channels, '_Channels/TemplatesTestingMatrix.mat'));
    end
  

    %% 
    tic
    mainCounter = 1;
    counter = 1;
    for Y = 1: MaximumNumberOfTemplates
        if numel(find(TemplatesTestingMatrix == Y)) > 0

            templateCurrentlyTesting = Y;

            [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, rez, fs, templateSampleSizeEvaluating);

            if strcmp(RunningGaussianScalaTest, 'YES') == 1
                rez_st3_templateRelevant(:,1) = floor(rez_st3_templateRelevant(:,1)./2)+1;
            end

            grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, EmouseGroundTruth, fs, templateSampleSizeEvaluating, rez );

            %% Fibonacci         
            b = 1;
            a = 0;
            finalRange = 0.02;
            numberOfIterations = 0;
            epsilon = 0.01;
            maxSearch = 50;


            range = finalRange/(b-a);
            fibonacciArray = [];
            %find number of required iterations
            for I = 1 : maxSearch
                fibonacciArray(I) = fibonacciMB(I); 
                if  fibonacciArray(I) >= (1+2*epsilon)/range;
                    numberOfIterations = I - 1;
                    break;
                end
            end

            kept = 0;

            if Y == 35
                break1 = 1;
            end
                
            
            if numberOfIterations ~= 0
                for k=1:numberOfIterations % Fibonacci loop
                    pa = 1 - (fibonacciArray(numberOfIterations-k+1)/fibonacciArray(numberOfIterations-k+2));
                    pb = pa;

                    if k == numberOfIterations
                       if kept == a 
                           pb = pb - epsilon;
                       else
                           pa = pa - epsilon;
                       end
                    end

                    x1 = a+pa*(b-a);
                    x2 = b-(pb)*(b-a);
                    
                 
                   if kept == b || kept == 0
                        [finalResultPeaksx1, finalResultTimesx1] = GetValuesAboveThreshold(CorrelationResultMatrix(:,Y), x1, IsAlgorithmSimilarityBased);
                        totalSamplesx1 = size(CorrelationResultMatrix);
                        totalSamplesx1 = totalSamplesx1(1);

                        %[Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, 'NO');
                        %[precision, recall] = GenerateConfusionMatrixWithSlack(finalResultTimes, rez_st3_templateRelevant,3);
                        [precisionx1, recallx1, falloutx1, TPx1, TNx1, FPx1, FNx1] = GenerateConfusionMatrixFromGTWithSlack(finalResultTimesx1, grundTruth, 3, totalSamplesx1);
                   end

                   if kept == a || kept == 0
                        % Estimaing the value function for x2;
                        [finalResultPeaksx2, finalResultTimesx2] = GetValuesAboveThreshold(CorrelationResultMatrix(:,Y), x2, IsAlgorithmSimilarityBased);
                        totalSamplesx2 = size(CorrelationResultMatrix);
                        totalSamplesx2 = totalSamplesx2(1);

                        %[Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, 'NO');

                        %[precision, recall] = GenerateConfusionMatrixWithSlack(finalResultTimes, rez_st3_templateRelevant,3);
                        [precisionx2, recallx2, falloutx2, TPx2, TNx2, FPx2, FNx2] = GenerateConfusionMatrixFromGTWithSlack(finalResultTimesx2, grundTruth, 3, totalSamplesx2);
                   end
                    
          


                    fx1 = precisionx1*PrecisionWeight + recallx1*RecallWeight;
                    fx2 = precisionx2*PrecisionWeight + recallx2*RecallWeight;

                    if fx1<fx2 || (precisionx2 < 0.9 && precisionx1 < 0.9)
                       a=x1;
                       kept = a;
                       precisionx1 = precisionx2;
                       recallx1 = recallx2;
                       %x1=x2; fx1=fx2;
                       %x2=b-p*(b-a);
                       %fx2=fhandle(x2);
                    else
                        b=x2;
                        kept = b;
                        precisionx2 = precisionx1;
                        recallx2 = recallx1;
                        %x2=x1; fx2=fx1;
                        %x1=a+p*(b-a);
                        %fx1=fhandle(x1);
                    end
                end
                if fx1<fx2
                    x=x2;
                    precision = precisionx2;
                    recall = recallx2;
                else
                    x=x1;
                    precision = precisionx1;
                    recall = recallx1;
                end
                %disp(x)
                
            end

            %% Original cont.    





            OptimalThreshold(counter) = x;
%                 HitrateArray(counter) = Hitrate;
%                 AccuracyArray(counter) = Accuracy;
%                 extraSpikesArray(counter) = extraSpikes;
            precisionArray(counter) = precision;
            recallArray(counter) = recall;
%                 falloutArray(counter) = fallout;
%                     spikes = zeros(1,299939);
%                     spikes(rez_st3_templateRelevant(:,1)) = 1;
%                     
%                     corr([CorrelationResultMatrix(:,Y) spikes'])
            counter = counter + 1;


        end
    end
            

%         meanPrecision(mainCounter) = mean(precisionArray);
%         stdPrecision(mainCounter) = std(precisionArray);
%         meanRecall(mainCounter) = mean(recallArray);
%         stdrecall(mainCounter) = std(recallArray);
%         %meanFallout(mainCounter) = mean(falloutArray);
%         %stdFallout(mainCounter) = std(falloutArray);
% 
%         IndividualPrecisions(mainCounter,:) = precisionArray;
%         IndividualRecalls(mainCounter,:) = recallArray;
%         %IndividualFallouts(mainCounter,:) = falloutArray;
% 
%         mainCounter = mainCounter + 1;       
% 
%     
%     if strcmp(ShowThresholdAnalysisFigure, 'YES') == 1
%         figure;
%         plot(ThresholdToTest,meanPrecision)
%         hold on;
%         plot(ThresholdToTest,stdPrecision, 'g');
%         hold on;
%         plot(ThresholdToTest,meanRecall, 'r');
%         hold on;
%         plot(ThresholdToTest,stdrecall, 'm');
%         hold off;
%         title(['Threshold Analysis ' CorrelationType,' - Channelwidth: ', num2str(numberOfChannelToEvaluate)]);
%         legend('Mean Precision', 'STD Precision', 'Mean Recall', 'STD Recall');
%         xlabel('Threshold values');
%         ylabel('Rate');
%     end
%     
%     % PLOTS ROC CURVE!!!
%     if strcmp(ShowThresholdAnalysisFigure, 'YES') == 1
%         auc = trapz([1 meanFallout],[1 meanRecall]);
%         auc = auc*(-1);
%         
%         figure('rend','painters','pos',[500 500 1000 400]);
%         subplot(1,2,1);
%         plot([1 meanFallout],[1 meanRecall]);
%         hold on;
%         plot([0 1],[0 1],'--k');
%         dim = [.2 .5 .3 .3];
%         str = strcat('AUC:',{' '},num2str(auc));
%         annotation('textbox',dim,'String',str,'FitBoxToText','on');
%         legend(CorrelationType,'Location','southeast');
%         title('Receiver operating characteristic (ROC)');
%         xlabel('False positive rate (FPR) (Fallout)');
%         ylabel('True positive rate (TPR) (Recall)');
%         
%         subplot(1,2,2); 
%         plot([1 meanFallout],[1 meanRecall]);
%         hold on;
%         xlim([0 0.0005]);
%         ylim([0.9 1]);
%         legend(CorrelationType,'Location','southeast');
%         title('ROC (zoomed)');
%         xlabel('False positive rate (FPR) (Fallout)');
%         ylabel('True positive rate (TPR) (Recall)');
%     end
%     
%     % PLOTS Precision-Recall CURVE!!!
%     if strcmp(ShowThresholdAnalysisFigure, 'YES') == 1
%         %auc = trapz([1 meanFallout],[1 meanRecall]);
%         %auc = auc*(-1);
%         
%         figure('rend','painters','pos',[500 500 600 400]);
%         plot([meanRecall],[meanPrecision]);
%         hold on;
%         legend(CorrelationType,'Location','southeast');
%         title('Precision-Recall Curve');
%         xlabel('True positive rate (TPR) (Recall)');
%         ylabel('Positive predictive value (PPV) (Precision)');
%         
%     end
%     
%     IndividualPrecisionsSize = size(IndividualPrecisions);
%     for I = 1 : IndividualPrecisionsSize(2)
%         MatrixToOptimize = (IndividualPrecisions(:,I).*PrecisionWeight)+(IndividualRecalls(:,I).*RecallWeight);
%         [OptimalThresholdValue(I),OptimalThresholdInd(I)]  = max(MatrixToOptimize);
%         OptimalPrecisionValue(I) = IndividualPrecisions(OptimalThresholdInd(I),I);
%         OptimalRecallValue(I) = IndividualRecalls(OptimalThresholdInd(I),I);
%         OptimalThreshold = ThresholdToTest(OptimalThresholdInd);
%     end
    totalTime = toc;
%     figure;
%     plot(ThresholdToTest,IndividualPrecisions(:,1))
%     hold on;
%     plot(ThresholdToTest,IndividualRecalls(:,1), 'g');  
%     hold off,
    
%     meanChannelPrecisionArray(K) = mean(OptimalPrecisionValue)
%     meanChannelRecallArray(K) = mean(OptimalRecallValue)
%     
%     meanChannelPrecisionTemplateSize(X) = mean(OptimalPrecisionValue);
%     meanChannelRecallTemplateSize(X) = mean(OptimalRecallValue);
%     
    OptimalThresholdTemplate = zeros(1, MaximumNumberOfTemplates);
    counterToOptimal = 1;
    for II = 1 : MaximumNumberOfTemplates
       if TemplatesTestingMatrix(II) > 0
        OptimalThresholdTemplate(II) = OptimalThreshold(counterToOptimal);
        counterToOptimal = counterToOptimal + 1;
       end
    end
    fprintf(CorrelationType);
    fprintf(' ChannelWidth: %.0f Channel length: %0.f', numberOfChannelToEvaluate, templateSampleSizeEvaluating);
    fprintf('\nMaximum Obtainable precisionrate using individual threshold: %.4f\n', mean(precisionArray));
    fprintf('Maximum Obtainable Recallrate using individual threshold: %.4f\n', mean(recallArray));
    fprintf('Mean Template threshold estimation: %.2f\n', (totalTime/(counter-1)));
    if strcmp(RunTemplateSamplesTest, 'YES') == 1
        pathToSaveTheFile = strcat(DiectoryToEvaluate, '\OptimalThreshold\', CorrelationType, '\channels_', num2str(numberOfChannelToEvaluate), '\templateSize_', num2str(templateSampleSizeEvaluating)); 
    else
        pathToSaveTheFile = strcat(DiectoryToEvaluate, '\OptimalThreshold\', CorrelationType, '\channels_', num2str(numberOfChannelToEvaluate)); 
    end
        
        if exist(pathToSaveTheFile) == 0
        mkdir(pathToSaveTheFile);
    end
    save(strcat(pathToSaveTheFile, '\OptimalTemplateThresholdMap.mat'),'OptimalThresholdTemplate','-v7.3');
    fprintf('\n************************SAVING ENDED**************************\n\n');
end

% figure;
% plot(channelsToTest, meanChannelPrecisionArray);
% hold on;
% plot(channelsToTest, meanChannelRecallArray);
% hold on;
% hold off;
% 
% 
% figure;
% plot(channelsToTest, meanChannelPrecisionArray./channelsToTest);
% hold on;
% plot(channelsToTest, meanChannelRecallArray./channelsToTest);
% hold off;

end


% figure;
% plot(NumberOfTemplateSamplesUsed, meanChannelPrecisionTemplateSize);
% hold on;
% plot(NumberOfTemplateSamplesUsed, meanChannelRecallTemplateSize);
% hold off;
% 
% LapNXCORStruct.templateSizes = NumberOfTemplateSamplesUsed;
% LapNXCORStruct.meanChannelPrecision = meanChannelPrecisionTemplateSize;
% LapNXCORStruct.meanChannelRecall = meanChannelRecallTemplateSize;
% 
% save('PrecisionRecallMeanTemplateSizeLapNXCOR.mat', 'LapNXCORStruct', '-v7.3');


