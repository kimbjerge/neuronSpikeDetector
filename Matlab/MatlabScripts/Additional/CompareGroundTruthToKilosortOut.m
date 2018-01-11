clear all;
close all;
clc;

%% Setup
AlgorithmToTest = 'NXCOR_2D_General';

% ------------ Path/Directory ---------------
PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';

%DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
DiectoryToEvaluate = 'C:\Users\Morten Buhl\Desktop\Simulation_10min_30kHz_5Noise_DefVals';
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
templateGain = 10; % gg %20000 for SAD/SSD
templateCurrentlyTesting = 30; % The template we are matching against. This is overwritten runtime
templateSpikeOffset = 19; % sample offset
findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
MaximumNumberOfTemplates = 64;
NumberOfTemplateSamplesUsed = 17;
MaximumNumberOfTemplateSamples = 61;
% ------------- Sample size -----------------
ConfLevel = '99%';
ErrorMargin = 0.01;
% -------------- Matching Setup ---------------
threshold = repmat(.25000,1,MaximumNumberOfTemplates);

IsAlgorithmSimilarityBased = IsAlgorithmSimilarityBasedFunc(AlgorithmToTest);

if strcmp(AlgorithmToTest, 'LSAD') == 1 || strcmp(AlgorithmToTest, 'SSD') == 1 || ...
    strcmp(AlgorithmToTest, 'SAD') == 1 || strcmp(AlgorithmToTest, 'LSSD') == 1 

    templateGain = 2000;
end

% --------------- Debug/Figures ---------------
ViewFiguresRunning = 'NO';
ShowProgressBar = 'NO';
ShowFunctionExcTime = 'NO';
PlotCCvsKilosort = 'NO';
ShowTemplateMacthingInfoRunning = 'YES';
WriteToFile = 'YES';
ShowComparisonInTheEnd = 'YES';
UsePreFoundTemplateThreshold = 'NO';
    UseIndividuallyOptimizedThresholds = 'YES';
RunTemplateSamplesTest = 'YES';

TemplatesToTest = 1:MaximumNumberOfTemplates;
TemplatesToTestElements = numel(TemplatesToTest);
SelectSpecificTemplatesToAvoidUsing = [64];
TimeBaseSlack = 0;


%% - Variables 
PercentageOfKilosortFound = zeros(MaximumNumberOfTemplates, 1);
OverallAccuracy = zeros(MaximumNumberOfTemplates, 1);
ExtraSpikesFound = zeros(MaximumNumberOfTemplates, 1);
TemplateEvaluated = zeros(MaximumNumberOfTemplates, 1);

SpikeOffsetMatrix = zeros(1,MaximumNumberOfTemplates);
TemplatesTestingMatrix = zeros(1,MaximumNumberOfTemplates);
TruthTemplateArray = cell(1,MaximumNumberOfTemplates);  


templateSizeTestingThisRound = 17;
counter = 1;
for I = TemplatesToTest(1) : TemplatesToTest( TemplatesToTestElements )
            templateCurrentlyTesting = I;
            %% Investigate if template is matched to signal by Kilosort
            [ templatesPresent, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged(rez, MaximumNumberOfTemplates);

            %% Find relevant channels to investigate based on the template signal                                                             
            if templatesPresent(templateCurrentlyTesting) > 0 && numel(find(SelectSpecificTemplatesToAvoidUsing == templateCurrentlyTesting)) == 0          
                fprintf('Analysing template: %.0f\n', I);
                template = PrepareTemplate( strcat(DiectoryToEvaluate,'\templates.npy'), templateCurrentlyTesting, [1:32], ...
                                                                             templateGain, pathToNPYMaster, ViewFiguresRunning, ShowFunctionExcTime);
                
                if strcmp(findTemplateOffsetAndChannelAutomatic, 'YES')
                   [ mainChannel, templateSpikeOffset, ~ ] = GetTemplateInfo( template ); 
                end
                
                %% Get kilosortGroundTruth
                [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, rez, fs, templateSizeTestingThisRound );

                %% Get ground truth!
                grundTruth = ExtractGroundTruthInfo( signalOffset, signalLength_s, templateSpikeOffset, templateCurrentlyTesting, EmouseGroundTruth, fs, templateSizeTestingThisRound, rez );
   

                %% GenerateConfusionMatrix 
                [precision, recall, fallout] = GenerateConfusionMatrixFromGTWithSlack(rez_st3_templateRelevant(:,1), grundTruth, 3, ((signalLength_s*fs)-NumberOfTemplateSamplesUsed));
                
                PrecisionArray(counter) = precision;
                RecallArray(counter) = recall;
                counter = counter + 1;
            else
                fprintf('Skipped template: %.0f\n', I);
            end
            
end

fprintf('\n Results: \n');
fprintf('Mean Precsion: %.4f\n', mean(PrecisionArray));
fprintf('Mean Recall: %.4f\n', mean(RecallArray));
fprintf('Std Precsion: %.4f\n', std(PrecisionArray));
fprintf('Std Recall: %.4f\n', std(RecallArray));

                
            

       

        
    

