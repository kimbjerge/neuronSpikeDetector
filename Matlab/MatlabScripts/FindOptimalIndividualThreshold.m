%% Set threshold to test according to  type
if strcmp(CorresponceMatchningToTest, 'SSD') == 1
    ThresholdToTest = fliplr(1*10^8:0.1*10^8:5*10^8); 
elseif strcmp(CorresponceMatchningToTest, 'SAD') == 1
    ThresholdToTest = fliplr(3*10^5:0.5*10^4:4.5*10^5); 
elseif strcmp(CorresponceMatchningToTest, 'NSSD') == 1
    ThresholdToTest = fliplr(0.1:0.01:1.6); 
elseif strcmp(CorresponceMatchningToTest, 'XCOR_1D') == 1
    ThresholdToTest = 3000:100:40000; 
elseif strcmp(CorresponceMatchningToTest, 'XCOR_2D') == 1
    ThresholdToTest = 3000:100:40000; 
elseif strcmp(CorresponceMatchningToTest, 'XCOR_FFT') == 1
    ThresholdToTest = 1:500:3000;     
elseif strcmp(CorresponceMatchningToTest, 'NSAD') == 1
    ThresholdToTest = fliplr(0.2:0.02:1); 
else
    ThresholdToTest = single(0.2:0.02:1); % NXCOR
end

%% Start Evaluating
for X = 1 : numel(NumberOfTemplateSamplesUsed);

    templateSampleSizeEvaluating = NumberOfTemplateSamplesUsed(X);
    
for K = 1 : numel(ChannelsToTest)

    
    numberOfChannelToEvaluate = ChannelsToTest(K);
    
   
    channels = num2str(numberOfChannelToEvaluate);
    if strcmp(RunTemplateSamplesTest, 'YES')
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/CorrelationResultMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/SpikeOffsetMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/templateSize_', num2str(templateSampleSizeEvaluating), '/TemplatesTestingMatrix.mat'));
    else
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/CorrelationResultMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/SpikeOffsetMatrix.mat'));
        load(strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/TemplatesTestingMatrix.mat'));
    end
  

    %% 
    tic
    mainCounter = 1;
    for I = 1 : (numel(ThresholdToTest))
        thresHoldThisRun = ThresholdToTest(I);
            counter = 1;
            fprintf('Analysing template level: %.2f\n', thresHoldThisRun);
            for Y = 1: MaximumNumberOfTemplates
                if numel(find(TemplatesTestingMatrix == Y)) > 0

                    templateCurrentlyTesting = Y;

                    [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, rez, fs, templateSampleSizeEvaluating, isKiloSortTemplateMerged);

%                     if strcmp(RunningGaussianScalaTest, 'YES') == 1
%                         rez_st3_templateRelevant(:,1) = floor(rez_st3_templateRelevant(:,1)./2)+1;
%                     end
                    
                    if strcmp(UsingSimulatedData, 'YES') == 1
                        grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), templateCurrentlyTesting, EmouseGroundTruth, fs, templateSampleSizeEvaluating, rez,isKiloSortTemplateMerged );
                    end
                    
                    result = CorrelationResultMatrix(:,Y);
                    
                    [finalResultPeaks, finalResultTimes] = GetValuesAboveThreshold(result, thresHoldThisRun, IsAlgorithmSimilarityBased);
                    totalSamples = size(CorrelationResultMatrix);
                    totalSamples = totalSamples(1);
                    
                    [Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, 'NO');
                    
                    if strcmp(UsingSimulatedData, 'YES') == 1
                        [precision, recall, fallout, TP, TN, FP, FN] = GenerateConfusionMatrixFromGTWithSlack(finalResultTimes, grundTruth, 3, totalSamples);
                    else
                        [precision, recall, fallout, TP, TN, FP, FN] = GenerateConfusionMatrixWithSlack(finalResultTimes, rez_st3_templateRelevant,3, totalSamples);    
                    end

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
            
            IndividualPrecisions(mainCounter,:) = precisionArray;
            IndividualRecalls(mainCounter,:) = recallArray;
            IndividualFallouts(mainCounter,:) = falloutArray;
            
            mainCounter = mainCounter + 1;       
    end

    
    if strcmp(ShowThresholdAnalysisFigure, 'YES') == 1
        figure;
        plot(ThresholdToTest,meanPrecision)
        hold on;
        plot(ThresholdToTest,stdPrecision, 'g');
        hold on;
        plot(ThresholdToTest,meanRecall, 'r');
        hold on;
        plot(ThresholdToTest,stdrecall, 'm');
        hold off;
        title(['Threshold Analysis ' KernelFilterToTest,' - Channelwidth: ', num2str(numberOfChannelToEvaluate)]);
        legend('Mean Precision', 'STD Precision', 'Mean Recall', 'STD Recall');
        xlabel('Threshold values');
        ylabel('Rate');
    end
    
    % PLOTS ROC CURVE!!!
    if strcmp(ShowThresholdAnalysisFigure, 'YES') == 1
        auc = trapz([1 meanFallout],[1 meanRecall]);
        auc = auc*(-1);
        
        figure('rend','painters','pos',[500 500 1000 400]);
        subplot(1,2,1);
        plot([1 meanFallout],[1 meanRecall]);
        hold on;
        plot([0 1],[0 1],'--k');
        dim = [.2 .5 .3 .3];
        str = strcat('AUC:',{' '},num2str(auc));
        annotation('textbox',dim,'String',str,'FitBoxToText','on');
        legend(KernelFilterToTest,'Location','southeast');
        title('Receiver operating characteristic (ROC)');
        xlabel('False positive rate (FPR) (Fallout)');
        ylabel('True positive rate (TPR) (Recall)');
        
        subplot(1,2,2); 
        plot([1 meanFallout],[1 meanRecall]);
        hold on;
        xlim([0 0.0005]);
        ylim([0.9 1]);
        legend(KernelFilterToTest,'Location','southeast');
        title('ROC (zoomed)');
        xlabel('False positive rate (FPR) (Fallout)');
        ylabel('True positive rate (TPR) (Recall)');
    end
    
    % PLOTS Precision-Recall CURVE!!!
    if strcmp(ShowThresholdAnalysisFigure, 'YES') == 1
        %auc = trapz([1 meanFallout],[1 meanRecall]);
        %auc = auc*(-1);
        
        figure('rend','painters','pos',[500 500 600 400]);
        plot([meanRecall],[meanPrecision]);
        hold on;
        legend(KernelFilterToTest,'Location','southeast');
        title('Precision-Recall Curve');
        xlabel('True positive rate (TPR) (Recall)');
        ylabel('Positive predictive value (PPV) (Precision)');
        
    end
    
    IndividualPrecisionsSize = size(IndividualPrecisions);
    for I = 1 : IndividualPrecisionsSize(2)
        MatrixToOptimize = (IndividualPrecisions(:,I).*PrecisionWeight)+(IndividualRecalls(:,I).*RecallWeight);
        [OptimalThresholdValue(I),OptimalThresholdInd(I)]  = max(MatrixToOptimize);
        OptimalPrecisionValue(I) = IndividualPrecisions(OptimalThresholdInd(I),I);
        OptimalRecallValue(I) = IndividualRecalls(OptimalThresholdInd(I),I);
        OptimalThreshold = ThresholdToTest(OptimalThresholdInd);
    end
    totalTime = toc;
%     figure;
%     plot(ThresholdToTest,IndividualPrecisions(:,1))
%     hold on;
%     plot(ThresholdToTest,IndividualRecalls(:,1), 'g');  
%     hold off,
    
    meanChannelPrecisionArray(K) = mean(OptimalPrecisionValue);
    meanChannelRecallArray(K) = mean(OptimalRecallValue);
    
    meanChannelPrecisionTemplateSize(X) = mean(OptimalPrecisionValue);
    meanChannelRecallTemplateSize(X) = mean(OptimalRecallValue);
    
    OptimalThresholdTemplate = zeros(1, MaximumNumberOfTemplates);
    counterToOptimal = 1;
    for II = 1 : MaximumNumberOfTemplates
       if TemplatesTestingMatrix(II) > 0
        OptimalThresholdTemplate(II) = OptimalThreshold(counterToOptimal);
        counterToOptimal = counterToOptimal + 1;
       end
    end
    %fprintf(KernelFilterToTest);
    %fprintf(' ChannelWidth: %.0f Channel length: %0.f', numberOfChannelToEvaluate, templateSampleSizeEvaluating);
    fprintf('\nMaximum Obtainable precisionrate using individual threshold: %.4f\n', mean(OptimalPrecisionValue));
    fprintf('Maximum Obtainable Recallrate using individual threshold: %.4f\n', mean(OptimalRecallValue));
    %fprintf('Mean Template threshold estimation: %.2f\n', (totalTime/(mainCounter-1)));
    if strcmp(RunTemplateSamplesTest, 'YES') == 1
        pathToSaveTheFile = strcat(DiectoryToEvaluate, '\OptimalThreshold\', KernelFilterToTest, '\channels_', num2str(numberOfChannelToEvaluate), '\templateSize_', num2str(templateSampleSizeEvaluating)); 
    else
        pathToSaveTheFile = strcat(DiectoryToEvaluate, '\OptimalThreshold\', KernelFilterToTest, '\channels_', num2str(numberOfChannelToEvaluate)); 
    end
        
        if exist(pathToSaveTheFile) == 0
        mkdir(pathToSaveTheFile);
    end
    save(strcat(pathToSaveTheFile, '\OptimalTemplateThresholdMap.mat'),'OptimalThresholdTemplate','-v7.3');
    fprintf('\n************************SAVING THRESHOLDS ENDED**************************\n\n');
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