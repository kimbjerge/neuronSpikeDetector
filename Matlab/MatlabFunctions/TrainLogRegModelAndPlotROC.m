function [ model ] = TrainLogRegModelAndPlotROC( Prediction,  Response)
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

%model = fitglm(Prediction,Response,'Distribution','binomial','Link','logit');
model = fitglm(Prediction,Response,'Distribution','binomial','Link','logit');
%%
% Compute the ROC curve. Use the probability estimates from the logistic
% regression model as scores.
scores = model.Fitted.Probability;
[X,Y,T,AUC] = perfcurve(Response,scores,'1'); 
%%
% |perfcurve| stores the threshold values in the array |T|.
%%
% Display the area under the curve.
AUC
%%
% The area under the curve is 0.7918. The maximum AUC is 1, which corresponds to a perfect
% classifier. Larger AUC values indicate better classifier performance.
%%
% Plot the ROC curve.
plot(X,Y)
xlabel('False positive rate') 
ylabel('True positive rate')
title('ROC for Classification by Logistic Regression')


end

