function [ SVMModel, error ] = TrainSVMModel( Prediction,  Response, PrintFiguresRunning, Run3D)
%TRAINSVMMODEL Summary of this function goes here
%   Detailed explanation goes here


%% Train a Support Vector Machine Classifier
%%
% Load Fisher's iris data set. Remove the sepal lengths and widths, and all
% observed setosa irises.

% Copyright 2015 The MathWorks, Inc.


%%
% Train an SVM classifier using the processed data set
rng(101);
%SVMModel = fitcsvm(Prediction,Response, 'KernelScale','auto', 'KernelFunction', 'linear','Standardize',true, 'Cost', [0,2;1,0]);
%SVMModel = fitcsvm(Prediction,Response, 'KernelScale','auto', 'KernelFunction', 'rbf','Standardize',true);
SVMModel = fitcsvm(Prediction,Response, 'KernelScale','auto', 'KernelFunction', 'linear','Standardize',true);

% scores = SVMModel.Fitted.Probability;
% [X,Y,T,AUC] = perfcurve(Response,scores,'1'); 
% %%
% % |perfcurve| stores the threshold values in the array |T|.
% %%
% % Display the area under the curve.
% AUC

sv = SVMModel.SupportVectors;

SVMModel.ConvergenceInfo.Converged;
error = resubLoss(SVMModel);

if strcmp(PrintFiguresRunning, 'YES')
    if Run3D == 1
        
        figure;
        plot(Prediction(:,1), '.');
        hold on;
        plot(Prediction(find( Response == 1),1), '*');
        hold on;
        plot(sv(:,1),'ko');
        hold on;
%         contour(x1Grid,x2Grid,reshape(scores(:,2),size(x1Grid)),[0 0],'k');
        xlabel('NXCOR');
        ylabel('Laplacian');
%         zlabel('Gradient');
        legend('NoSpikes', 'Spikes','Support Vector')
        hold off;
        
    elseif Run3D == 3
        figure;
        plot3(Prediction(:,1), Prediction(:,2), Prediction(:,3), '.');
        hold on;
        plot3(Prediction(find( Response == 1),1), Prediction(find( Response == 1),2), Prediction(find( Response == 1),3), '*');
        hold on;
        plot3(sv(:,1), sv(:,2),sv(:,3),'ko');
        hold on;
        xlabel('NXCOR');
        ylabel('Laplacian');
        zlabel('Gradient');
        legend('NoSpikes', 'Spikes','Support Vector')
        hold off;
    elseif Run3D == 2
        d = 0.02;
        [x1Grid,x2Grid] = meshgrid(min(Prediction(:,1)):d:max(Prediction(:,1)),...
        min(Prediction(:,2)):d:max(Prediction(:,2)));
        xGrid = [x1Grid(:),x2Grid(:)];
        [~,scores] = predict(SVMModel,xGrid);
        
        figure;
        plot(Prediction(:,1), Prediction(:,2), '.');
        hold on;
        plot(Prediction(find( Response == 1),1), Prediction(find( Response == 1),2), '*');
        hold on;
        plot(sv(:,1), sv(:,2),'ko');
        hold on;
        contour(x1Grid,x2Grid,reshape(scores(:,2),size(x1Grid)),[0 0],'k');
        xlabel('NXCOR');
        ylabel('Laplacian');
        zlabel('Gradient');
        legend('NoSpikes', 'Spikes','Support Vector')
        hold off;
        
    end
end

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