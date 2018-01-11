function [ model ] = TrainLinRegModelAndPlotROC( Prediction,  Response, PrintFiguresRunning)
%TRAINLOGREGMODELANDPLOTROC Summary of this function goes here
%   Detailed explanation goes here

%% Plot ROC Curve for Classification by Logistic Regression
%%
% Load the sample data.

% Copyright 2015 The MathWorks, Inc.

% load fisheriris
%%
% Use only the first two features as predictor variables. Define a binary
% classification problem by using only the measurements that correspond to the species
% versicolor and virginica.
% pred = meas(51:end,1:2);
%%
% Define the binary response variable.
% resp = (1:100)'>50;  % Versicolor = 0, virginica = 1
%%
% Fit a logistic regression model.

sizeOfPrediction = size(Prediction);
scale = 0.01;
PriorMatrix = [(numel(find(Response == 0)))/sizeOfPrediction(1), (numel(find(Response == 1)))/sizeOfPrediction(1)];
Weights = ones(sizeOfPrediction(1),1);
Weights = Weights.*scale;
WeightOnes = (1/((numel(find(Response == 1)))/299983)*scale);
Weights(Response == 1) = WeightOnes/1000; 

%model = fitglm(Prediction,Response,'Distribution','binomial','Link','logit');
model = fitglm(Prediction,Response,'linear','Distribution','binomial'); % 'Weights', Weights
%model = fitglm(Prediction,Response,'purequadratic','Distribution','binomial'); % 'Weights', Weights
%model = fitglm(Prediction,Response,'poly3','Distribution','binomial'); % 'Weights', Weights
%%
% Compute the ROC curve. Use the probability estimates from the logistic
% regression model as scores.
scores = model.Fitted.Probability;
[X,Y,T,AUC] = perfcurve(Response,scores,'1'); 
%%
% |perfcurve| stores the threshold values in the array |T|.
%%
% Display the area under the curve.
AUC;
%%
% The area under the curve is 0.7918. The maximum AUC is 1, which corresponds to a perfect
% classifier. Larger AUC values indicate better classifier performance.
%%
if strcmp(PrintFiguresRunning, 'YES') == 1
% Plot the ROC curve.
%figure;
%plot(model);
xlabel('False positive rate') 
ylabel('True positive rate')
title('ROC for Classification by Logistic Regression')
end

end

