function [ Model ] = TrainNaiveBayesModel( Prediction,  Response)
%TRAINBAYES Summary of this function goes here
%   Detailed explanation goes here

%% Train a Support Vector Machine Classifier
%%
% Load Fisher's iris data set. Remove the sepal lengths and widths, and all
% observed setosa irises.

% Copyright 2015 The MathWorks, Inc.


%%
% Train an SVM classifier using the processed data set.
Model = fitcnb(Prediction,Response);


% scores = SVMModel.Fitted.Probability;
% [X,Y,T,AUC] = perfcurve(Response,scores,'1'); 
% %%
% % |perfcurve| stores the threshold values in the array |T|.
% %%
% % Display the area under the curve.
% AUC



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

% figure
% gscatter(X(:,1),X(:,2),y)
% hold on
% plot(sv(:,1),sv(:,2),'ko','MarkerSize',10)
% legend('versicolor','virginica','Support Vector')
% hold off
%%
% The support vectors are observations that occur on or beyond their
% estimated class boundaries.
%%
% You can adjust the boundaries (and therefore the number of support
% vectors) by setting a box constraint during training using the
% |'BoxConstraint'| name-value pair argument.

end

