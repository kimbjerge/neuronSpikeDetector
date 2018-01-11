clear all;
close all;
%%
CorrelationType1 = 'NXCOR_2D_General';
CorrelationType2 = 'Laplacian';
CorrelationType3 = 'Gradient';

ClassifierType = 'DecisionTree_3D';

PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
addpath(DiectoryToEvaluate);

Adasynpath = strcat(PrePath ,'Matlab libs\ADASYN');

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
IsAlgorithmSimilarityBased1 = IsAlgorithmSimilarityBasedFunc(CorrelationType1);
IsAlgorithmSimilarityBased2 = IsAlgorithmSimilarityBasedFunc(CorrelationType2);
IsAlgorithmSimilarityBased3 = IsAlgorithmSimilarityBasedFunc(CorrelationType3);

UseIndividuallyOptimizedThresholds = 'YES';
PrintFiguresRunning = 'NO';
WriteToFile = 'YES';
OnlyFecthDataForVisual = 'NO';

ChannelsToTest = 9;
templateSizeTestingThisRound = 17;
%ChannelsToTest = cat(2,ChannelsToTest, 32);

for Y = 1 : numel(ChannelsToTest)
    
    NumberOfChannelsToInvestigate = ChannelsToTest(Y);
    channels = num2str(NumberOfChannelsToInvestigate);
    
    
    OTStruct1{2} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/CorrelationResultMatrix.mat'));
    OTStruct1{3} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/SpikeOffsetMatrix.mat'));
    OTStruct1{4} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TemplatesTestingMatrix.mat'));
    
    OTStruct2{2} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType2,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/CorrelationResultMatrix.mat'));
    
    OTStruct3{2} = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType3,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/CorrelationResultMatrix.mat'));
    
     
    counter = 1;    
    Matrix = [];
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
            
            if strcmp(ClassifierType, 'LinReg2D') == 1 || strcmp(ClassifierType, 'SVM_2D') == 1 || strcmp(ClassifierType, 'LinModel2D') == 1 || strcmp(ClassifierType, 'LDA_2D') == 1  || strcmp(ClassifierType, 'QDA_2D') == 1 || strcmp(ClassifierType, 'DecisionTree_2D') == 1
                Prediction = [OTStruct1{1,2}.CorrelationResultMatrix(:,Y), OTStruct2{1,2}.CorrelationResultMatrix(:,Y) ];
            elseif strcmp(ClassifierType, 'LinReg1D') == 1 || strcmp(ClassifierType, 'LinModel1D') == 1 || strcmp(ClassifierType, 'SVM_1D') == 1 || strcmp(ClassifierType, 'QDA_1D') == 1 || strcmp(ClassifierType, 'DecisionTree_1D') == 1
                Prediction = [OTStruct2{1,2}.CorrelationResultMatrix(:,Y)];
            else
                Prediction = [OTStruct1{1,2}.CorrelationResultMatrix(:,Y), OTStruct2{1,2}.CorrelationResultMatrix(:,Y), OTStruct3{1,2}.CorrelationResultMatrix(:,Y) ];
            end
            
            
            sizeCorrelationMatrix = size(OTStruct1{1,2}.CorrelationResultMatrix(:,Y)); 
            %Prediction = [OTStruct1{1,2}.CorrelationResultMatrix(:,Y), OTStruct2{1,2}.CorrelationResultMatrix(:,Y)];
            Response = zeros(sizeCorrelationMatrix(1),1);
            %Response = Response.*-1;
            Response(grundTruth.gtRes) = 1;  % NoSpike = 0, Spike = 1;
            
            %model = TrainLogRegModelAndPlotROC( Prediction,  Response);
           
            Matrix = [Prediction Response];
            
            if strcmp(OnlyFecthDataForVisual, 'NO') == 1 
                rng(101);
                tic
            
                if  strcmp(ClassifierType, 'SVM_2D') == 1
                    [model{counter}, error] = TrainSVMModel( Prediction,  Response, PrintFiguresRunning, 2);
                    fprintf('\nTemplate: %.0f SVM Error: %f\n', Y, error);
                elseif  strcmp(ClassifierType, 'SVM_3D') == 1
                    [model{counter}, error] = TrainSVMModel( Prediction,  Response, PrintFiguresRunning, 3);
                elseif  strcmp(ClassifierType, 'SVM_1D') == 1
                    [model{counter}, error] = TrainSVMModel( Prediction,  Response, PrintFiguresRunning, 1);
                    fprintf('\nTemplate: %.0f SVM Error: %f\n', Y, error);
                elseif strcmp(ClassifierType, 'LogReg') == 1
                    model{counter} = TrainLogRegModelAndPlotROC( Prediction,  Response, PrintFiguresRunning);
                elseif strcmp(ClassifierType, 'Bayes') == 1
                    model{counter} = TrainNaiveBayesModel( Prediction,  Response, PrintFiguresRunning);
                elseif strcmp(ClassifierType, 'LinReg') == 1
                    model{counter} = TrainLinRegModelAndPlotROC( Prediction,  Response, PrintFiguresRunning);
                elseif strcmp(ClassifierType, 'LinReg2D') == 1 || strcmp(ClassifierType, 'LinReg1D') == 1
                    model{counter} = TrainLinRegModelAndPlotROC( Prediction,  Response, PrintFiguresRunning);
                elseif strcmp(ClassifierType, 'LinModel1D') == 1 || strcmp(ClassifierType, 'LinModel2D') == 1
                    model{counter} = TrainLinearRegressionModel( Prediction,  Response, PrintFiguresRunning, 5);             
                elseif strcmp(ClassifierType, 'LDA_2D') == 1
                    model{counter} = TrainLDAModel( Prediction,  Response, PrintFiguresRunning);
                elseif strcmp(ClassifierType, 'QDA_2D') == 1 || strcmp(ClassifierType, 'QDA_1D') == 1 || strcmp(ClassifierType, 'QDA_3D') == 1
                    model{counter} = TrainQDAModel( Prediction,  Response, PrintFiguresRunning, Adasynpath);
                elseif strcmp(ClassifierType, 'DecisionTree_1D') == 1 || strcmp(ClassifierType, 'DecisionTree_2D') == 1 || strcmp(ClassifierType, 'DecisionTree_3D') == 1
                    model{counter} = TrainDecisionTreeModel( Prediction,  Response, PrintFiguresRunning);
                end
                
                timeSpend(counter) = toc;
            
                

    %             C   = cell(sizeCorrelationMatrix(1), 1);
    %             C(:) = {'No Spike'};
    %             C(grundTruth.gtRes) = {'Spike'}; 








    %             XT = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7];
    %             y_est = (W'*XT')'; % Predict

                ypred = predict(model{counter},Prediction);

                positiveSamples = find(ypred >= 0.5);

                if numel(positiveSamples) == 0
                    SomethingWentWrong = 1;
                end

                [ precision, recall ] = GenerateConfusionMatrix(positiveSamples, grundTruth.gtRes);

                precisionArray(counter) = precision
                recallArray(counter) = recall

                counter = counter + 1;
    %             HitrateArray(counter) = Hitrate;
    %             AccuracyArray(counter) = Accuracy;
    %             extraSpikesArray(counter) = extraSpikes;
    %             precisionArray(counter) = precision;
    %             recallArray(counter) = recall;
    %             counter = counter + 1;
            end
        end
    end
    
    fprintf('\nClassifier Train output for ChannelWidth: %.0f\n', NumberOfChannelsToInvestigate);
    fprintf('Mean Obtainable precisionrate using Classifier: %.4f\n', mean(precisionArray(find(precisionArray > 0))));
    fprintf('Mean Obtainable Recallrate using individual threshold: %.4f\n', mean(recallArray));
    fprintf('Mean Template model build time: %.4f  std: %.4f\n', mean(timeSpend), std(timeSpend));
    
     if strcmp(WriteToFile, 'YES') == 1
        fprintf('\n************************STARTED SAVING**************************\n\n');
        channels = num2str(NumberOfChannelsToInvestigate);
        dirToCreate = strcat(DiectoryToEvaluate,'/TrainedClassifiers/', ClassifierType, '/',channels, '_Channels');
        if exist(dirToCreate) == 0
            mkdir(dirToCreate);
        end
        save(strcat(dirToCreate, '/model.mat'),'model','-v7.3');
        fprintf('\n************************SAVING ENDED**************************\n\n');
    end
        
end
