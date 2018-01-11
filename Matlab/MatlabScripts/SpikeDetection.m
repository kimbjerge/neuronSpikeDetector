%% -------------------------------------------------- Variables ----------------------------------------------------
threshold = repmat(.25000,1,MaximumNumberOfTemplates); % Threshold mapping to test, is overwritted runtime
PercentageOfKilosortFound = zeros(MaximumNumberOfTemplates, 1);
OverallAccuracy = zeros(MaximumNumberOfTemplates, 1);
ExtraSpikesFound = zeros(MaximumNumberOfTemplates, 1);
TemplateEvaluated = zeros(MaximumNumberOfTemplates, 1);
PrecisionArray = zeros(MaximumNumberOfTemplates, 1);
RecallArray = zeros(MaximumNumberOfTemplates, 1);
SpikeOffsetMatrix = zeros(1,MaximumNumberOfTemplates);
TemplatesTestingMatrix = zeros(1,MaximumNumberOfTemplates);
TruthTemplateArray = cell(1,MaximumNumberOfTemplates);  
NumberOfChannelsToInvestigate = ChannelsToTest; % Should be odd


%% ------------------------------------------------ Start of algorithm -----------------------------------------------
for X = 1: numel(NumberOfTemplateSamplesUsed)
    
    templateSizeTestingThisRound = NumberOfTemplateSamplesUsed(X);
    CorrelationResultMatrix = zeros(((signalLength_s*fs)-templateSizeTestingThisRound), MaximumNumberOfTemplates);

    for Y = 1 : numel(ChannelsToTest)

        NumberOfChannelsToInvestigate = ChannelsToTest(Y);

        if strcmp(UsePreFoundTemplateThreshold, 'YES') == 1
            if strcmp( UseIndividuallyOptimizedThresholds, 'YES') == 1
                if strcmp(RunTemplateSamplesTest, 'YES') == 1
                    load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', KernelFilterToTest, '\channels_', num2str(NumberOfChannelsToInvestigate),'\templateSize_', num2str(templateSizeTestingThisRound),'\OptimalTemplateThresholdMap.mat'));
                else    
                    load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', KernelFilterToTest, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalTemplateThresholdMap.mat'));
                end
            else
                load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', KernelFilterToTest, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalCombinedTemplateThresholdMap.mat'));
            end    
        end

        firstRun = 1;

        for I = TemplatesToTest(1) : TemplatesToTest( TemplatesToTestElements )
            tic;
            templateCurrentlyTesting = I;
            
            %% Get template for the test
            template = PrepareTemplate( TemplatesFile, templateCurrentlyTesting, [1:MaximumChannelsToUse], ...
                                                                             templateGain, pathToNPYMaster, ViewFiguresRunning, ShowFunctionExcTime);

%                     figure;
%                     surf(template(:,:));
%                     title('Unfiltered Raw Data')
%                     xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')                                                                         
                                                                         
            %% Investigate if template is matched to signal by Kilosort
            [ templatesPresent, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged(rez, MaximumNumberOfTemplates, isKiloSortTemplateMerged, signalLength_s, signalOffset, fs);

            %% Find relevant channels to investigate based on the template signal                                                             
            if templatesPresent(templateCurrentlyTesting) > 0 && numel(find(SelectSpecificTemplatesToAvoidUsing == templateCurrentlyTesting)) == 0
                fprintf('Extracting features for template: %.0f\n', I);
                
                if strcmp(findTemplateOffsetAndChannelAutomatic, 'YES')
                   [ mainChannel, templateSpikeOffset, ~ ] = GetTemplateInfo( template ); 
                end

                %% Crop template
                if NumberOfChannelsToInvestigate < MaximumChannelsToUse
                    ChannelsToInvestigate = ChooseChannels(mainChannel,NumberOfChannelsToInvestigate);
                    template = template(:,ChannelsToInvestigate);
                end

                if templateSizeTestingThisRound < MaximumNumberOfTemplateSamples
                   template = template(ChooseTemplateSamples(templateSpikeOffset, templateSizeTestingThisRound),:);   
                end


                %% Get Data for the test
                if firstRun == 1 %Slow first time
                    Oldsignal = PrepareData( RecordFile, 1:MaximumChannelsToUse, rez, signalOffset, ...
                                                                                 signalLength_s, signalGain, fs, ViewFiguresRunning, ShowFunctionExcTime);
                                                                                                                                                                                 
                    
                    %% Channel filter signal              
                    FiltSamples = ChannelFilter( Oldsignal, 1:MaximumChannelsToUse, filterType, signalLength_s, fs, ViewFiguresRunning );
                                     
                    %% Kernel filter signal
                    KFSignalFull = KernelFilter( KernelFilterToTest, FiltSamples);
                    
                    KFSignal = KFSignalFull(:, ChannelsToInvestigate);
                    firstRun = 0;
                else % Faster all the other times
                    KFSignal = KFSignalFull(:, ChannelsToInvestigate);
                end          
                
                
                %% Kernel filter template  
                KFTemplate = KernelFilter( KernelFilterToTest, template);
                
                
                %% Correpondence Matching
                if strcmp(CorresponceMatchningToTest, 'XCOR_1D') == 1
                    result = TemplateXCOR_1D( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'XCOR_2D') == 1
                    result = TemplateXCOR_2D( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime); % This is 25x faster than XCOR_1D 
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'XCOR_2D_GPU') == 1
                    result = TemplateXCOR_2D_GPU( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime); 
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'SAD') == 1
                    result = TemplateSAD( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(4*10^4,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'SSD') == 1
                    result = TemplateSSD( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(2.5*10^8,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'XCOR_FFT') == 1
                    result = TemplateXCOR_FFT( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, pathToFFTXCORLib, ShowFunctionExcTime); 
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'NXCOR_2D') == 1
                    result = TemplateNXCOR_2D( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(0.25,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'NXCOR_2D_GPU') == 1
                    result = TemplateNXCOR_2D_GPU( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                     threshold = repmat(0.25,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'NXCOR') == 1
                    result = TemplateNXCOR_2D_General( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, pathToNormXcorr2General, ShowFunctionExcTime);
                     threshold = repmat(0.5,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'LSAD') == 1
                    result = TemplateLSAD( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                     threshold = repmat(0.5,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'LSSD') == 1
                    result = TemplateLSSD( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                     threshold = repmat(0.5,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'NSSD') == 1
                    result = TemplateNSSD( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(1.5,1,MaximumNumberOfTemplates);
                elseif strcmp(CorresponceMatchningToTest, 'NSAD') == 1
                    result = TemplateNSAD( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(0.5,1,MaximumNumberOfTemplates); 
                elseif strcmp(CorresponceMatchningToTest, 'NXCOR_DRIFT') == 1    
                    if HandleDriftChannel > 0
                        result = TemplateNXCORWithDrift(KFSignalFull, KFTemplate, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime,pathToNormXcorr2General, HandleDriftChannel, ChannelsToInvestigate);
                    else  
                        result = TemplateNXCOR_2D_General( KFSignal, KFTemplate, ViewFiguresRunning, ShowProgressBar, pathToNormXcorr2General, ShowFunctionExcTime);
                    end
                    threshold = repmat(0.7,1,MaximumNumberOfTemplates);               
                elseif strcmp(CorresponceMatchningToTest, 'OtherFeature') == 1
                    result = TemplateOtherFeatures(signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime, templateSpikeOffset, mainChannel);
                    threshold = repmat(0.1,1,MaximumNumberOfTemplates);          
                end 

                
                %% Use trained threshold?
                if strcmp(UsePreFoundTemplateThreshold, 'YES') == 1
                    threshold = OptimalThresholdTemplate;
                end
  
                %% Get kilosortGroundTruth
                [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, rez, fs, templateSizeTestingThisRound, isKiloSortTemplateMerged );

                %% Get ground truth!
                if strcmp(UsingSimulatedData, 'YES')
                    grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, EmouseGroundTruth, fs, templateSizeTestingThisRound, rez, isKiloSortTemplateMerged );
                end

                %% Save correcaltion result for this setup
                if strcmp(CorresponceMatchningToTest, 'NXCOR_DRIFT') == 1 && HandleDriftChannel > 0
                    result = max(result, [], 2);
                end
                CorrelationResultMatrix(:, templateCurrentlyTesting) = result; 
                SpikeOffsetMatrix(templateCurrentlyTesting) = templateSpikeOffset;
                TemplatesTestingMatrix(templateCurrentlyTesting) = templateCurrentlyTesting;

                %% Get values Above threshold
                [finalResultPeaks, finalResultTimes] = GetValuesAboveThreshold(result, threshold(I), IsAlgorithmSimilarityBased);    
                totalSamples = size(result);
                totalSamples = totalSamples(1);

                %% Compare result with Kilosort truth
                [Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, ShowTemplateMacthingInfoRunning);

                %% GenerateConfusionMatrix 
                if strcmp(UsingSimulatedData, 'YES')
                    [precision, recall, fallout, TP, TN, FP, FN] = GenerateConfusionMatrixFromGTWithSlack(finalResultTimes, grundTruth, 3, totalSamples);
                else
                    [precision, recall, fallout, TP, TN, FP, FN] = GenerateConfusionMatrixWithSlack(finalResultTimes, rez_st3_templateRelevant, 3, totalSamples);
                end

                %% Log comparasion
                PercentageOfKilosortFound(I) = Hitrate;
                OverallAccuracy(I) = Accuracy;
                ExtraSpikesFound(I) = extraSpikes;
                TemplateEvaluated(I) = templateCurrentlyTesting; 
                PrecisionArray(I) = precision;
                RecallArray(I) = recall;
                %TruthTemplateArray{I} = result(grundTruth.gtRes);  

                %% Compare CC with kilosort
                if strcmp(UsingSimulatedData, 'YES')
                    PerformTMAnalysis(rez_st3_templateRelevant, result, threshold(I), PlotCCvsKilosort,templateCurrentlyTesting, finalResultTimes, IsAlgorithmSimilarityBased, grundTruth);
                end
                
                 %fprintf('ERROR: The setup parameters can not find any matching points - please change!\n');
                
            else
                 %fprintf('WARNING: The requested template(%.0f) is not present in the kilosort data!!! - A comparison would not make sense!\n', templateCurrentlyTesting);
            end


            ElapsedTime = toc;
            %fprintf('Processing this template(%.0f) took %.2f seconds.\n\n',templateCurrentlyTesting, ElapsedTime);
        end

        % Calculate sample size
        
        xAxisInd = find(TemplateEvaluated > 0);
        xAxis = TemplateEvaluated(xAxisInd);

        PrecisionArray = PrecisionArray(xAxisInd);
        RecallArray = RecallArray(xAxisInd);

        if strcmp(ShowComparisonInTheEnd, 'YES') == 1   

           PercentageOfKilosortFound = PercentageOfKilosortFound(xAxisInd);
           OverallAccuracy = OverallAccuracy(xAxisInd);
           ExtraSpikesFound = ExtraSpikesFound(xAxisInd);

           figure;
           bar(xAxis, PercentageOfKilosortFound);
           title('Percentage of Kilosort spikes found');
           xlabel('Templates');
           ylabel('Percentage');

           figure;
           bar(xAxis, OverallAccuracy);
           title('Percentage of Overall Accuracy');
           xlabel('Templates');
           ylabel('Percentage');

           figure;
           bar(xAxis, ExtraSpikesFound);
           title('Extra Spikes Found')
           xlabel('Templates');
           ylabel('Spikes'); 

           figure;
           plot(xAxis, PrecisionArray);
           hold on;
           plot(xAxis, RecallArray, 'g');
           hold off;
           title('Precision / Recall');
           xlabel('Templates');
           ylabel('Rate');
           legend('Precision', 'Recall');
        end

        Precision_Mean(Y) = mean(PrecisionArray);
        Precision_std(Y) = std(PrecisionArray);

        Recall_Mean(Y) = mean(RecallArray);
        Recall_std(Y) = std(RecallArray);

%         fprintf('\n*************************** TEST ENDED ***********************\n\n');
%         fprintf('The Precision mean was: %.4f with a Std. variation: %.4f\n',Precision_Mean, Precision_std);
%         fprintf('The Recall mean was: %.4f with a Std. variation: %.4f\n',Recall_Mean, Recall_std);
%         fprintf('\n**************************************************************\n\n');

        
        
        if strcmp(WriteToFile, 'YES') == 1
            channels = num2str(NumberOfChannelsToInvestigate);
            
            if strcmp(RunTemplateSamplesTest, 'YES');
                dirToCreate = strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound));
            else
                dirToCreate = strcat(DiectoryToEvaluate,'/CorrelationTests/',KernelFilterToTest,'/',channels, '_Channels');
            end
            
            if exist(dirToCreate) == 0
                mkdir(dirToCreate);
            end
            save(strcat(dirToCreate, '/CorrelationResultMatrix.mat'),'CorrelationResultMatrix','-v7.3');
            save(strcat(dirToCreate, '/SpikeOffsetMatrix.mat'),'SpikeOffsetMatrix','-v7.3');
            save(strcat(dirToCreate, '/TemplatesTestingMatrix.mat'),'TemplatesTestingMatrix','-v7.3');
            fprintf('\n************************SAVING FEATURES ENDED**************************\n\n');
        end
    end

end

