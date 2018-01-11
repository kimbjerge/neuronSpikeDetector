clear all;
%close all;
clc;

%% Setup
AlgorithmToTest = 'NXCOR_2D_General';

% ------------ Path/Directory ---------------
PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
addpath(DiectoryToEvaluate);
DirectoryFiltering = strcat(PrePath,'Generated_Emouse_Data\Filtering');
addpath(DirectoryFiltering);
load(strcat(DiectoryToEvaluate, '\rez.mat'));
EmouseGroundTruth = load(strcat(DiectoryToEvaluate, '\eMouseGroundTruth.mat'));
pathToNPYMaster = strcat(PrePath, 'masterProject\npy-matlab-master');
pathToFFTXCORLib = strcat(PrePath, 'Matlab libs\XCoor using FFT'); % Leave out if not using XCOR_FFT algorithm
pathToNormXcorr2General = strcat(PrePath, 'Matlab libs\normxcoor2_general');
% ------------- Signal setup -----------------
MaximumChannelsToUse = 32;
NumberOfChannelsToInvestigate = 5; % Should be odd
ChannelsToInvestigate = 1:32; % If findTemplateOffsetAndChannelAutomatic YES: this is aut. overwritten!
fs = 30000; % Hz
filter = 'YES';
filterType = 'Kilosort';
signalGain = 1; % gg
signalOffset = 0; % seconds
signalLength_s = 10; % seconds
% ---------------- Template -------------------
templateGain = 1; % gg %20000 for SAD/SSD
templateCurrentlyTesting = 30; % The template we are matching against. This is overwritten runtime
templateSpikeOffset = 19; % sample offset
findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
MaximumNumberOfTemplates = 64;
NumberOfTemplateSamplesUsed = 61;
MaximumNumberOfTemplateSamples = 61;
% -------------- Matching Setup ---------------
threshold = repmat(.25000,1,MaximumNumberOfTemplates);

IsAlgorithmSimilarityBased = IsAlgorithmSimilarityBasedFunc(AlgorithmToTest);

if strcmp(AlgorithmToTest, 'LSAD') == 1 || strcmp(AlgorithmToTest, 'SSD') == 1 || ...
    strcmp(AlgorithmToTest, 'SAD') == 1 || strcmp(AlgorithmToTest, 'LSSD') == 1 

    templateGain = 20000;
end

% --------------- Debug/Figures ---------------
ViewFiguresRunning = 'NO';
ShowProgressBar = 'NO';
ShowFunctionExcTime = 'NO';
PlotCCvsKilosort = 'NO';
ShowTemplateMacthingInfoRunning = 'YES';
WriteToFile = 'NO';
ShowComparisonInTheEnd = 'NO';
UsePreFoundTemplateThreshold = 'YES';
    UseIndividuallyOptimizedThresholds = 'YES';
RunTemplateSamplesTest = 'YES';
RunGuassianPyramidTest = 'NO';

TemplatesToTest = 1:MaximumNumberOfTemplates;
TemplatesToTestElements = numel(TemplatesToTest);
SelectSpecificTemplatesToAvoidUsing = [64];
TimeBaseSlack = 0;


%% - Variables 
PercentageOfKilosortFound = zeros(MaximumNumberOfTemplates, 1);
OverallAccuracy = zeros(MaximumNumberOfTemplates, 1);
ExtraSpikesFound = zeros(MaximumNumberOfTemplates, 1);
TemplateEvaluated = zeros(MaximumNumberOfTemplates, 1);
PrecisionArray = zeros(MaximumNumberOfTemplates, 1);
RecallArray = zeros(MaximumNumberOfTemplates, 1);
SpikeOffsetMatrix = zeros(1,MaximumNumberOfTemplates);
TemplatesTestingMatrix = zeros(1,MaximumNumberOfTemplates);


%ChannelsToTest = 1:2:31;
ChannelsToTest = 32;
%ChannelsToTest = cat(2,ChannelsToTest, 32);

for X = 1: numel(NumberOfTemplateSamplesUsed)
    
    templateSizeTestingThisRound = NumberOfTemplateSamplesUsed(X);
    if strcmp(RunGuassianPyramidTest, 'YES')
        CorrelationResultMatrix = zeros(floor(((signalLength_s*fs)-templateSizeTestingThisRound)/2), MaximumNumberOfTemplates);
    else
        CorrelationResultMatrix = zeros(((signalLength_s*fs)-templateSizeTestingThisRound), MaximumNumberOfTemplates);
    end
    

    for Y = 1 : numel(ChannelsToTest)

        NumberOfChannelsToInvestigate = ChannelsToTest(Y);

        if strcmp(UsePreFoundTemplateThreshold, 'YES') == 1
            if strcmp( UseIndividuallyOptimizedThresholds, 'YES') == 1
                if strcmp(RunTemplateSamplesTest, 'YES') == 1
                    load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest, '\channels_', num2str(NumberOfChannelsToInvestigate),'\templateSize_', num2str(templateSizeTestingThisRound),'\OptimalTemplateThresholdMap.mat'));
                else    
                    load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalTemplateThresholdMap.mat'));
                end
            else
                load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalCombinedTemplateThresholdMap.mat'));
            end    
        end

        firstRun = 1;

        for I = TemplatesToTest(1) : TemplatesToTest( TemplatesToTestElements )
            fprintf('Analysing template: %.0f\n', I);
            tic
            templateCurrentlyTesting = I;
            %% Get template for the test
            template = PrepareTemplate( strcat(DiectoryToEvaluate,'\templates.npy'), templateCurrentlyTesting, [1:32], ...
                                                                             templateGain, pathToNPYMaster, ViewFiguresRunning, ShowFunctionExcTime);

            %% Investigate if template is matched to signal by Kilosort
            [ templatesPresent, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged(rez, MaximumNumberOfTemplates);

            %% Find relevant channels to investigate based on the template signal                                                             
            if templatesPresent(templateCurrentlyTesting) > 0 && numel(find(SelectSpecificTemplatesToAvoidUsing == templateCurrentlyTesting)) == 0

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
                if firstRun == 1 %Slow first time
                    Oldsignal = PrepareData( strcat(DiectoryToEvaluate,'\sim_binary.dat'), 1:32, rez, signalOffset, ...
                                                                                 signalLength_s, signalGain, filter, filterType, fs, ViewFiguresRunning, ShowFunctionExcTime);

                    signal = Oldsignal(:, ChannelsToInvestigate);
                    firstRun = 0;
                else % Faster all the other times
                    signal = Oldsignal(:, ChannelsToInvestigate);    
                end

                
                %% Perform Gaussian scaling
                if strcmp(RunGuassianPyramidTest, 'YES')
                    %templateOld = template;
                    %signalOld = signal;
                    template = impyramid(template, 'reduce');
                    signal = impyramid(signal, 'reduce');
                end
                
                    %% Run test
                if strcmp(AlgorithmToTest, 'XCOR_1D') == 1
                    result = TemplateXCOR_1D( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'XCOR_2D') == 1
                    result = TemplateXCOR_2D( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime); % This is 25x faster than XCOR_1D 
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'XCOR_2D_GPU') == 1
                    result = TemplateXCOR_2D_GPU( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime); 
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'SAD') == 1
                    result = TemplateSAD( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(4*10^4,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'SSD') == 1
                    result = TemplateSSD( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(2.5*10^8,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'XCOR_FFT') == 1
                    result = TemplateXCOR_FFT( signal, template, ViewFiguresRunning, ShowProgressBar, pathToFFTXCORLib, ShowFunctionExcTime); 
                    threshold = repmat(2000,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'NXCOR_2D') == 1
                    result = TemplateNXCOR_2D( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(0.25,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'NXCOR_2D_GPU') == 1
                    result = TemplateNXCOR_2D_GPU( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                     threshold = repmat(0.25,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'NXCOR_2D_General') == 1
                    result = TemplateNXCOR_2D_General( signal, template, ViewFiguresRunning, ShowProgressBar, pathToNormXcorr2General, ShowFunctionExcTime);
                     threshold = repmat(0.7,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'LSAD') == 1
                    result = TemplateLSAD( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                     threshold = repmat(0.5,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'LSSD') == 1
                    result = TemplateLSSD( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                     threshold = repmat(0.5,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'NSSD') == 1
                    result = TemplateNSSD( signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime);
                    threshold = repmat(1.5,1,MaximumNumberOfTemplates);
                elseif strcmp(AlgorithmToTest, 'Gradient') == 1
                    result = TemplateGradient(signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime,pathToNormXcorr2General);
                    threshold = repmat(0.5,1,MaximumNumberOfTemplates);    
                elseif strcmp(AlgorithmToTest, 'Laplacian') == 1
                    result = TemplateLaplacian(signal, template, ViewFiguresRunning, ShowProgressBar, ShowFunctionExcTime,pathToNormXcorr2General);
                    threshold = repmat(0.7,1,MaximumNumberOfTemplates);
                end

                if strcmp(UsePreFoundTemplateThreshold, 'YES') == 1
                    threshold = OptimalThresholdTemplate;
                end

                
                %% Get kilosortGroundTruth
                [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, rez, fs, templateSizeTestingThisRound );

                %% Get ground truth!
                grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, EmouseGroundTruth, fs, templateSizeTestingThisRound, rez );

                %% convert Truth Table based on gaussian
                if strcmp(RunGuassianPyramidTest, 'YES')
                    rez_st3_templateRelevant(:,1) = floor(rez_st3_templateRelevant(:,1)./2)+1;
                    grundTruth.gtRes = floor(grundTruth.gtRes./2)+1;
                end

                %% Save correcaltion result for this setup
               
                CorrelationResultMatrix(:, templateCurrentlyTesting) = result; 
                SpikeOffsetMatrix(templateCurrentlyTesting) = templateSpikeOffset;
                TemplatesTestingMatrix(templateCurrentlyTesting) = templateCurrentlyTesting;
                
                    

                %% Get values Above threshold
               [finalResultPeaks, finalResultTimes] = GetValuesAboveThreshold(result, threshold(I), IsAlgorithmSimilarityBased);    

                %% Compare result with Kilosort truth
                [Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes, rez_st3_templateRelevant, templateCurrentlyTesting, ShowTemplateMacthingInfoRunning);

                %% GenerateConfusionMatrix 
                [precision, recall] = GenerateConfusionMatrixWithSlack(finalResultTimes, rez_st3_templateRelevant, TimeBaseSlack);

                %% Log comparasion
                PercentageOfKilosortFound(I) = Hitrate;
                OverallAccuracy(I) = Accuracy;
                ExtraSpikesFound(I) = extraSpikes;
                TemplateEvaluated(I) = templateCurrentlyTesting; 
                PrecisionArray(I) = precision;
                RecallArray(I) = recall;

                %% Compare CC with kilosort
                PerformTMAnalysis(rez_st3_templateRelevant, result, threshold(I), PlotCCvsKilosort,templateCurrentlyTesting, finalResultTimes, IsAlgorithmSimilarityBased, grundTruth);

                
            else
                 fprintf('WARNING: The requested template(%.0f) is not present in the kilosort data!!! - A comparison would not make sense!\n', templateCurrentlyTesting);
            end


            ElapsedTime = toc;
            fprintf('Processing this template(%.0f) took %.2f seconds.\n\n',templateCurrentlyTesting, ElapsedTime);
        end

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

        fprintf('\n*************************** TEST ENDED ***********************\n\n');
        fprintf('The Precision mean was: %.4f with a Std. variation: %.4f\n',Precision_Mean, Precision_std);
        fprintf('The Recall mean was: %.4f with a Std. variation: %.4f\n',Recall_Mean, Recall_std);
        fprintf('\n**************************************************************\n\n');

        
        
        if strcmp(WriteToFile, 'YES') == 1
            channels = num2str(NumberOfChannelsToInvestigate);
            
            if strcmp(RunTemplateSamplesTest, 'YES');
                dirToCreate = strcat(DiectoryToEvaluate,'/CorrelationTests/',AlgorithmToTest,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound));
            else
                dirToCreate = strcat(DiectoryToEvaluate,'/CorrelationTests/',AlgorithmToTest,'/',channels, '_Channels');
            end
            
            if exist(dirToCreate) == 0
                mkdir(dirToCreate);
            end
            save(strcat(dirToCreate, '/CorrelationResultMatrix.mat'),'CorrelationResultMatrix','-v7.3');
            save(strcat(dirToCreate, '/SpikeOffsetMatrix.mat'),'SpikeOffsetMatrix','-v7.3');
            save(strcat(dirToCreate, '/TemplatesTestingMatrix.mat'),'TemplatesTestingMatrix','-v7.3');
            fprintf('\n************************SAVING ENDED**************************\n\n');
        end
    end

end

