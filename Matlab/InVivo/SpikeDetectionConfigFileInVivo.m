close all;
clear all;
clc;
%% Setup and constants
% -------------------------------------------- Simulated data  --------------------------------------------------
UsingSimulatedData = 'NO'; % Is the data simulated, If it is is uses the real grundtruth instead of kilosort to train upon
                            % Remarks that the C++ model is only trained
                            % against kilosort grundtruth
isKiloSortTemplateMerged = 'NO'; % Has KiloSort merged the templates?
PrePath = 'C:\neuronSpikeDetector\Matlab\'; % Path to the root of this project
% ------------------------------------------ Path/Directory -----------------------------------------------------
% DataPath = 'C:\Users\Morten Buhl\Desktop';
% DiectoryToEvaluate = strcat(DataPath,'\Simulation_10min_30kHz_2Noise_DefVals'); % Path to the data, rez file and more

DiectoryToEvaluate = 'C:\Users\cvlab\Desktop\2017-04-21_16-58-45'; % Path to the data, rez file and more
RecordFile = strcat(DiectoryToEvaluate, '\piroska_example_short.dat');
TemplatesFile = strcat(DiectoryToEvaluate,'\templates.npy');
addpath(DiectoryToEvaluate);
load(strcat(DiectoryToEvaluate, '\rez.mat')); % Loads the rez file from KiloSort
if strcmp(UsingSimulatedData, 'YES')
    EmouseGroundTruth = load(strcat(DiectoryToEvaluate, '\eMouseGroundTruth.mat')); % Loads the grund truth, in case of simulated data
end
% -------------------------------------------- Libraries -----------------------------------------------------------
addpath(strcat(PrePath,'MatlabFunctions'));
addpath(strcat(PrePath,'MatlabScripts'));
pathToNPYMaster = strcat(PrePath, 'MatlabLibs\npy-matlab-master'); % Path to NPY matlab reader project
pathToFFTXCORLib = strcat(PrePath, 'MatlabLibs\XCoor using FFT'); % Leave out if not using XCOR_FFT algorithm
pathToFibonacciLib = strcat(PrePath, 'MatlabLibs\Fibonacci'); % Path to Fibonacci library
pathToNormXcorr2General = strcat(PrePath, 'MatlabLibs\normxcoor2_general'); % Library to special NXCOR implementation
% --------------------------------------------- Signal setup ----------------------------------------------------
MaximumChannelsToUse = 32;
ChannelsToInvestigate = 1:32; % If findTemplateOffsetAndChannelAutomatic YES: this is aut. overwritten!
fs = 30000; % Sampling frequncy in data - Hz
filterType = 'Kilosort'; % Filter Type
signalGain = 1; % Signal gain
signalOffset = 0; % Offset in signal to investigate seconds
signalLength_s = 10; % Number of seconds to evaluate
TestingOffset_s = signalLength_s; % Offset in  prediction signal to investigate seconds
% --------------------------------------------- Kernel filtering -------------------------------------------------
KernelFilterToTest = 'None'; % Select between posible kernel filter types: 'Laplacian', 'GradientX','GradientY', 'None'
% --------------------------------------------- Correspondence Matching ------------------------------------------
CorresponceMatchningToTest = 'NXCOR'; % Select between posible matching types: 'NXCOR', 'NXCOR_DRIFT', 'NSSD', ...
                                                 % 'XCOR', 'SSD', 'LSAD',  
% ------------------------------------------------- Template -----------------------------------------------------
templateGain = 1; % Template initial amplitude gain
templateCurrentlyTesting = 30; % The template we are matching against. This is overwritten runtime
templateSpikeOffset = 19; % Template spike off - Changed runtime if the template is reduced!
findTemplateOffsetAndChannelAutomatic = 'YES'; % If NO: set NumberOfChannelsToInvestigate to 32 
MaximumNumberOfTemplates = 64; % Maximum number of templates
NumberOfTemplateSamplesUsed = 17; % Number of time samples used in a cropped version of the template 
ChannelsToTest = 9; % Number of data channels used in a cropped version of the template
MaximumNumberOfTemplateSamples = 61; % Maximum length of the time samples in the templates 
% ------------------------------------------------- Matching Setup -----------------------------------------------
%AlgorithmToTest = 'Laplacian'; % MUST BE REMOVED!!
HandleDriftChannel = 1; % Number of channel to handle drift with.
IsAlgorithmSimilarityBased = IsAlgorithmSimilarityBasedFunc(CorresponceMatchningToTest); % Is the correspondence matching similarity or de-similarity based?

if strcmp(CorresponceMatchningToTest, 'LSAD') == 1 || strcmp(CorresponceMatchningToTest, 'SSD') == 1 || ...
    strcmp(CorresponceMatchningToTest, 'SAD') == 1 || strcmp(CorresponceMatchningToTest, 'LSSD') == 1 
    templateGain = 2000; % Amplity the templates if using these methods as correspondence matching
end

% -------------------------------------------------- Classification ---------------------------------------
PrecisionWeight = 0.7;
RecallWeight = 1 - PrecisionWeight;

% -------------------------------------------------- Debug/Figures ------------------------------------------------
ViewFiguresRunning = 'NO'; % Print figures running (gathered data, template, filtering ...)
ShowProgressBar = 'NO'; % Show progress bar for each element
ShowFunctionExcTime = 'NO'; % Print the function execution time
PlotCCvsKilosort = 'NO'; % Plot the spikes lokation within the correlation features
ShowTemplateMacthingInfoRunning = 'NO'; % Show templates macthing for each template
WriteToFile = 'YES'; % % Save the correspondence featues ? 
ShowComparisonInTheEnd = 'NO'; % Print comparsion in the end of this test
UsePreFoundTemplateThreshold = 'NO'; % Use optimized threshold in general?
    UseIndividuallyOptimizedThresholds = 'YES'; % Use individual optmized threshold for each template?
RunTemplateSamplesTest = 'YES'; % Run shotened samples test       
ShowThresholdAnalysisFigure = 'YES';
TemplatesToTest = 1:MaximumNumberOfTemplates; % Array of the templates to test
TemplatesToTestElements = numel(TemplatesToTest); % The number of templates to actually test
SelectSpecificTemplatesToAvoidUsing = [64]; % Pre-select templates which are not to be used
TimeBaseSlack = 3; % Allowed time base slack compared to the grund truth - 3 at 30kHz i approx. 100 us 