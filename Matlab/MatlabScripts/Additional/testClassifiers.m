%%
clear all;
close all;
clc;

%%

CorrelationType1 = 'NXCOR_2D_General';
CorrelationType2 = 'Laplacian';
CorrelationType3 = 'Gradient';

ClassifierType = 'LinReg1D';


% ------------ Path/Directory ---------------
PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
addpath(DiectoryToEvaluate);
EmouseGroundTruth = load(strcat(DiectoryToEvaluate, '\eMouseGroundTruth.mat'));

% Constants
MaximumNumberOfTemplates = 64;
channelWidth = 9;
templateSizeTestingThisRound = 17;
channels = num2str(channelWidth);
% ------------- Signal setup -----------------
fs = 30000; % Hz
signalOffset = 10; % seconds
signalLength_s = 10; % seconds

%%
load(strcat(DiectoryToEvaluate,'\rez.mat'));
load(strcat(DiectoryToEvaluate,'\TrainedClassifiers\',ClassifierType,'\', channels,'_channels\','model.mat'));

storedStructure = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TestData/CorrelationResultMatrix.mat'),'CorrelationResultMatrix');
resultNXCOR = storedStructure.CorrelationResultMatrix;  % Assign it to a new variable with different name.
clear('storedStructure'); % If it's really not needed any longer.

storedStructure = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType2,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TestData/CorrelationResultMatrix.mat'),'CorrelationResultMatrix');
resultLOG = storedStructure.CorrelationResultMatrix;  % Assign it to a new variable with different name.
clear('storedStructure'); % If it's really not needed any longer.

storedStructure = load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType3,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TestData/CorrelationResultMatrix.mat'),'CorrelationResultMatrix');
resultGRA = storedStructure.CorrelationResultMatrix;  % Assign it to a new variable with different name.
clear('storedStructure'); % If it's really not needed any longer.

load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TestData/TemplatesTestingMatrix.mat'));
load(strcat(DiectoryToEvaluate,'/CorrelationTests/',CorrelationType1,'/',channels, '_Channels/templateSize_', num2str(templateSizeTestingThisRound),'/TestData/SpikeOffsetMatrix.mat'));

%storedStructure = load(strcat(DiectoryToEvaluate,'\ResultNXCOR_NOFFSET.mat'), 'result'); % Load in ONLY the myVar variable.
%resultNXCOR = storedStructure.result;  % Assign it to a new variable with different name.
%clear('storedStructure'); % If it's really not needed any longer.

% storedStructure = load(strcat(DiectoryToEvaluate,'\Result_LOG_NXCOR_NOFFSET.mat'), 'result'); % Load in ONLY the myVar variable.
% resultLOG = storedStructure.result;  % Assign it to a new variable with different name.
% clear('storedStructure'); % If it's really not needed any longer.
% 
% storedStructure = load(strcat(DiectoryToEvaluate,'\Result_GRA_NXCOR_NOFFSET.mat'), 'result'); % Load in ONLY the myVar variable.
% resultGRA = storedStructure.result;  % Assign it to a new variable with different name.
% clear('storedStructure'); % If it's really not needed any longer.

counter = 1; 
for Y = 1 : MaximumNumberOfTemplates
    
     
    if numel(find(TemplatesTestingMatrix == Y)) > 0  
        
        tic;
        if strcmp(ClassifierType, 'LinReg2D') == 1 || strcmp(ClassifierType, 'SVM_2D') == 1 || strcmp(ClassifierType, 'LinModel2D') == 1 || strcmp(ClassifierType, 'QDA_2D') == 1 || strcmp(ClassifierType, 'DecisionTree_2D') == 1 
            ypred = predict(model{counter},[resultNXCOR(:,Y) resultLOG(:,Y)]);
        elseif strcmp(ClassifierType, 'LinReg1D') == 1 || strcmp(ClassifierType, 'LinModel1D') == 1 || strcmp(ClassifierType, 'SVM_1D') == 1 || strcmp(ClassifierType, 'QDA_1D') == 1 || strcmp(ClassifierType, 'DecisionTree_1D') == 1
            ypred = predict(model{counter},[resultLOG(:,Y)]);
        else
            ypred = predict(model{counter},[resultNXCOR(:,Y) resultLOG(:,Y) resultGRA(:,Y)]);
        end
        time(counter) = toc;
        %fprintf('%s prediction time: %.3f\n',ClassifierType, time);
        
        positiveSamples = find(ypred >= 0.5);

        [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), Y, rez, fs, templateSizeTestingThisRound );

        grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, SpikeOffsetMatrix(Y), Y, EmouseGroundTruth, fs, templateSizeTestingThisRound, rez );           

        totalSamples = size(resultNXCOR);
        totalSamples = totalSamples(1);
        
        [precision, recall, fallout, TP, TN, FP, FN] = GenerateConfusionMatrixFromGTWithSlack(positiveSamples, grundTruth, 3, totalSamples);

        precisionArray(counter) = precision;
        recallArray(counter) = recall;

        
               
        counter = counter + 1;      
    end 
end

    fprintf('%s mean prediction time: %.3f\n',ClassifierType, mean(time));
    fprintf('Classifier Test output for ChannelWidth: %.0f\n', channelWidth);
    fprintf('Mean Obtainable precisionrate using Classifier: %.3f\n', mean(precisionArray(find(precisionArray > 0))));
    fprintf('Mean Obtainable Recallrate using individual threshold: %.3f\n\n', mean(recallArray));
