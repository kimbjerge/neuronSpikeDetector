clear all;
close all;
clc;

%% Run system setup file
SpikeDetectionConfigFile;

%% Evaluate SNR within the data
extractSNRFromSignal;

%% Generate Feature for Training
SpikeDetection;

%% Run Training
FindOptimalIndividualThreshold;

%% Run Predicition Testing
SpikeDetectionPrediction;