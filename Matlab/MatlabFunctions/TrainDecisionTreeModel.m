function [ Model ] = TrainDecisionTreeModel( Prediction,  Response, PrintFiguresRunning)
%TRAINBAYES Summary of this function goes here
%   Detailed explanation goes here

%% Train a Support Vector Machine Classifier
%%
% Load Fisher's iris data set. Remove the sepal lengths and widths, and all
% observed setosa irises.

% Copyright 2015 The MathWorks, Inc.


%%
% Train an SVM classifier using the processed data set.
% sizeOfPrediction = size(Prediction);
% scale = 0.01;
% PriorMatrix = [(numel(find(Response == 0)))/sizeOfPrediction(1), (numel(find(Response == 1)))/sizeOfPrediction(1)];
% Weights = ones(sizeOfPrediction(1),1);
% Weights = Weights.*scale;
% WeightOnes = (1/((numel(find(Response == 1)))/299983)*scale);
% Weights(Response == 1) = WeightOnes/10; 

Model = fitctree(Prediction,Response,'MaxNumSplits',20);

%Model = fitcdiscr(Prediction,Response, 'Cost', [0 100000000; 1 0], 'Weights', Weights, 'ScoreTransform','logit');


% scores = SVMModel.Fitted.Probability;
% [X,Y,T,AUC] = perfcurve(Response,scores,'1'); 
% %%
% % |perfcurve| stores the threshold values in the array |T|.
% %%
% % Display the area under the curve.
% AUC

%Model.ClassNames([1 2])
%K = Model.Coeffs(1,2).Const;  
%L = Model.Coeffs(1,2).Linear;
% figure;
% plot3(Prediction(:,1), Prediction(:,2), Prediction(:,3), '.');
% hold on;
% plot3(Prediction(find( Response == 1),1), Prediction(find( Response == 1),2), Prediction(find( Response == 1),3), '*');
% hold on;
% plot3(sv(:,1), sv(:,2),sv(:,3),'ko');
% hold on;
% xlabel('NXCOR');
% ylabel('Laplacian');
% zlabel('Gradient');
% legend('NoSpikes', 'Spikes','Support Vector')
% hold off;

if strcmp(PrintFiguresRunning, 'YES') == 1
% Plot the ROC curve.
figure;
plot(Prediction(:,1),Prediction(:,2), '.');
hold on;
plot(Prediction(Response == 1, 1), Prediction(Response == 1, 2), 'rx');
hold on;
f = @(x1,x2) K + L(1)*x1 + L(2)*x2;
h3 = ezplot(f,[-1 1 -1 1]);
h3.Color = 'k';
h3.LineWidth = 2;
xlabel('False positive rate') 
ylabel('True positive rate')
title('ROC for Classification by Logistic Regression')
end

%%
% The support vectors are observations that occur on or beyond their
% estimated class boundaries.
%%
% You can adjust the boundaries (and therefore the number of support
% vectors) by setting a box constraint during training using the
% |'BoxConstraint'| name-value pair argument.

end

