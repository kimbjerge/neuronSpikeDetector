clear all;
close all;
clc;

%% Run system setup file
SpikeDetectionConfigFileInVivo;

%% Evaluate SNR within the data
extractSNRFromInVivoSignal;

%% Generate Feature for Training
SpikeDetectionVivoDataTrain;

%% Run Training
FindOptimalIndividualThresholdInVivo;

%% Run Predicition Testing
SpikeDetectionVivoDataPredict;