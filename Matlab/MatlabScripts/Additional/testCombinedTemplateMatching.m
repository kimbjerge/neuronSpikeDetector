clear all;
%close all;
clc;
%%
CorrelationType1 = 'NXCOR_2D_General';
CorrelationType2 = 'Laplacian';
CorrelationType3 = 'Gradient';

AlgorithmToTest1 = CorrelationType1;
AlgorithmToTest2 = CorrelationType2;
AlgorithmToTest3 = CorrelationType3;

PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
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
IsAlgorithmSimilarityBased1 = IsAlgorithmSimilarityBasedFunc(AlgorithmToTest1);
IsAlgorithmSimilarityBased2 = IsAlgorithmSimilarityBasedFunc(AlgorithmToTest2);
IsAlgorithmSimilarityBased3 = IsAlgorithmSimilarityBasedFunc(AlgorithmToTest3);

UseIndividuallyOptimizedThresholds = 'YES';

ChannelsToTest = 9;
templateSizeTestingThisRound = 17;
%ChannelsToTest = cat(2,ChannelsToTest, 32);

for Y = 1 : numel(ChannelsToTest)
    
    NumberOfChannelsToInvestigate = ChannelsToTest(Y);
    channels = num2str(NumberOfChannelsToInvestigate);
    
    if strcmp( UseIndividuallyOptimizedThresholds, 'YES') == 1
        %OTStruct1{1} = load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest1, '\channels_', num2str(NumberOfChannelsToInvestigate),'\templateSize_', num2str(templateSizeTestingThisRound), '\OptimalTemplateThresholdMap.mat'));
        OTStruct2{1} = load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest2, '\channels_', num2str(NumberOfChannelsToInvestigate),'\templateSize_', num2str(templateSizeTestingThisRound), '\OptimalTemplateThresholdMap.mat'));
        OTStruct3{1} = load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest3, '\channels_', num2str(NumberOfChannelsToInvestigate),'\templateSize_', num2str(templateSizeTestingThisRound), '\OptimalTemplateThresholdMap.mat'));
    else
        OTStruct1{1} = load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest1, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalCombinedTemplateThresholdMap.mat'));
        OTStruct2{1} = load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest2, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalCombinedTemplateThresholdMap.mat'));
        OTStruct3{1} = load(strcat(DiectoryToEvaluate, '\OptimalThreshold\', AlgorithmToTest3, '\channels_', num2str(NumberOfChannelsToInvestigate),'\OptimalCombinedTemplateThresholdMap.mat'));
    end    
    
    OTStruct1{2} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/CorrelationResultMatrix.mat'));
    OTStruct1{3} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/SpikeOffsetMatrix.mat'));
    OTStruct1{4} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TemplatesTestingMatrix.mat'));
    
    OTStruct2{2} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType2,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/CorrelationResultMatrix.mat'));
    
    OTStruct3{2} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType3,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/CorrelationResultMatrix.mat'));
    
     


    for Y = 1: MaximumNumberOfTemplates
        if numel(find(OTStruct1{1, 4}.TemplatesTestingMatrix(:) == Y)) > 0

            templateCurrentlyTesting = Y;
                  
            [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, OTStruct1{1,3}.SpikeOffsetMatrix(Y), templateCurrentlyTesting, rez, fs, templateSizeTestingThisRound );

            grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, OTStruct1{1,3}.SpikeOffsetMatrix(Y), templateCurrentlyTesting, EmouseGroundTruth, fs, templateSizeTestingThisRound, rez );
            
            % Get values from first correlation type
            %[finalResultPeaks1, finalResultTimes1] = GetValuesAboveThreshold(OTStruct1{1,2}.CorrelationResultMatrix(:,Y), OTStruct1{1, 1}.OptimalThresholdTemplate(Y), IsAlgorithmSimilarityBased1);
            % Get values from second correlation type
            %[finalResultPeaks2, finalResultTimes2] = GetValuesAboveThreshold(OTStruct2{1,2}.CorrelationResultMatrix(:,Y), OTStruct2{1, 1}.OptimalThresholdTemplate(Y), IsAlgorithmSimilarityBased2);
            % CombineResultSomehow

            indexOfNonSpikes = 1:numel(OTStruct1{1,2}.CorrelationResultMatrix(:,Y));
            indexOfNonSpikes(grundTruth.gtRes) = [];
            
            
            figure('pos',[500 500 900 400]);
            scatter(OTStruct2{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y), zeros(1,numel(OTStruct2{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y))), '.');
            hold on;
            scatter(OTStruct2{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y), ones(1,numel(OTStruct2{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y))), 'rx');
            hold off;
            title(['1D Feature space for template: ' num2str(templateCurrentlyTesting)]);
            xlabel('NXCOR (Laplacian)');
            ylabel('Spike - No-Spike');
            legend('No Spike', 'Spike');
            set(gcf, 'color', 'w');
            ylim([-0.2 1.2]);
            %print -depsc 1DFeatureSpaceNXCORLaplacian
            
            
            figure('pos',[500 500 900 400]);
            plot(OTStruct1{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y),OTStruct2{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y), '.');
            hold on;
            plot(OTStruct1{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y), OTStruct2{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y), 'rx');
            hold off;
            title(['2D Feature space for template: ' num2str(templateCurrentlyTesting)]);
            xlabel('NXCOR');
            ylabel('NXCOR (Laplacian)');
            legend('No Spike', 'Spike');
            set(gcf, 'color', 'w');
            %print -depsc 2DFeatureSpaceNXCORLaplacian
%         


            figure('pos',[500 500 900 500]);
            scatter3(OTStruct1{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y), OTStruct2{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y),OTStruct3{1,2}.CorrelationResultMatrix(indexOfNonSpikes,Y),'.');
            hold on;
            scatter3(OTStruct1{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y), OTStruct2{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y),OTStruct3{1,2}.CorrelationResultMatrix(grundTruth.gtRes,Y),'*');
            hold off;
            title(['3D Feature space for template: ' num2str(templateCurrentlyTesting)]);
            xlabel('NXCOR');
            ylabel('NXCOR (Laplacian)');
            zlabel('NXCOR (Gradient)');
            legend('No Spike', 'Spike');
            set(gcf, 'color', 'w');
            view(110,9);
            %print -depsc 3DFeatureSpaceNXCORLaplacian
            
            [Accuracy, Hitrate, extraSpikes] = CompareWithGroundTruth(finalResultTimes1, rez_st3_templateRelevant, templateCurrentlyTesting, 'NO');
 
            [precision, recall] = GenerateConfusionMatrix(finalResultTimes1, rez_st3_templateRelevant);
% 
%             HitrateArray(counter) = Hitrate;
%             AccuracyArray(counter) = Accuracy;
%             extraSpikesArray(counter) = extraSpikes;
%             precisionArray(counter) = precision;
%             recallArray(counter) = recall;
%             counter = counter + 1;
        end
    end
        
end

%print -depsc -opengl 2DFeatureSpaceNXCORLaplacian
