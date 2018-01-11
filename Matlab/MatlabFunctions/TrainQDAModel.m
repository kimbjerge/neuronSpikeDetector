function [ Model ] = TrainQDAModel( Prediction,  Response, PrintFiguresRunning, Adasynpath)
%TRAINBAYES Summary of this function goes here
%   Detailed explanation goes here

%% Train a Support Vector Machine Classifier
%%
% Load Fisher's iris data set. Remove the sepal lengths and widths, and all
% observed setosa irises.

% Copyright 2015 The MathWorks, Inc.

UseADASYN = 'NO';

if strcmp(UseADASYN, 'YES') == 1
   addpath(Adasynpath);
   [ adasyn_featuresSyn, adasyn_labelsSyn ] = ADASYNFunc( Prediction,  Response);
   
   Prediction = [Prediction; adasyn_featuresSyn];
   adasyn_labelsSyn(:) = 1;
   Response = [Response; adasyn_labelsSyn];
    
end

%%
% Train an SVM classifier using the processed data set.
sizeOfPrediction = size(Prediction);
scale = 0.01;
PriorMatrix = [(numel(find(Response == 0)))/sizeOfPrediction(1), (numel(find(Response == 1)))/sizeOfPrediction(1)];
Weights = ones(sizeOfPrediction(1),1);
Weights = Weights.*scale;
WeightOnes = (1/((numel(find(Response == 1)))/299983)*scale);
Weights(Response == 1) = WeightOnes; 

Matrix = [Prediction Response];

%Model = fitcdiscr(Prediction,Response, 'DiscrimType','quadratic');
%Model = fitcdiscr(Prediction,Response, 'DiscrimType','quadratic', 'OptimizeHyperparameters','auto');
%Model = fitcdiscr(Prediction,Response, 'DiscrimType','quadratic', 'Prior', PriorMatrix, 'Gamma', 1);
Model = fitcdiscr(Prediction,Response, 'Cost', [0 1000; 1 0], 'DiscrimType','quadratic', 'Prior', PriorMatrix, 'Gamma', 1);
%Model = fitcdiscr(Prediction,Response, 'Cost', [0 100000000; 1 0], 'DiscrimType','quadratic', 'Weigths', Weights, 'Prior',PriorMatrix);
%Model = fitcdiscr(Prediction,Response, 'DiscrimType','quadratic', 'Weights', Weights, 'Prior',PriorMatrix, 'Gamma', 1);


% scores = SVMModel.Fitted.Probability;
% [X,Y,T,AUC] = perfcurve(Response,scores,'1'); 
% %%
% % |perfcurve| stores the threshold values in the array |T|.
% %%
% % Display the area under the curve.
% AUC

Model.ClassNames([1 2])
K = Model.Coeffs(1,2).Const;  
L = Model.Coeffs(1,2).Linear;
Q = Model.Coeffs(1,2).Quadratic;
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
f = @(x1,x2) K + L(1)*x1 + L(2)*x2 + Q(1,1)*x1.^2 + ...
    (Q(1,2)+Q(2,1))*x1.*x2 + Q(2,2)*x2.^2;
h2 = ezplot(f,[-1 1 0 1]);
h2.Color = 'r';
h2.LineWidth = 2;
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

function [ adasyn_featuresSyn, adasyn_labelsSyn ] = ADASYNFunc( Prediction,  Response)
% DATA GENERATION: generate two classes in a 2D feature space:

%make results reproducible by resetting the random number generator:
rng('default');

SizePrediction = size(Prediction);

%numbers of examples in the two classes
numEx0 = numel(find(Response == 1));       %minority class
numEx1 = SizePrediction(1) - numEx0;     %majority class

if numEx0 > numEx1
    error('demo_ADASYN: numEx0 must be smaller than numEx1, otherwise the text in the plots will confuse minority with majority.');
end




%class labels:
labels0 = false([numEx0 1]);
labels1 = true ([numEx1 1]);

features0 = Prediction(Response==1,:);
features1 = Prediction(Response==0,:);


% ADASYN: set up ADASYN parameters and call the function:

adasyn_features                 = [features0; features1];
adasyn_labels                   = [labels0  ; labels1  ];
adasyn_beta                     = [];   %let ADASYN choose default
adasyn_kDensity                 = [];   %let ADASYN choose default
adasyn_kSMOTE                   = [];   %let ADASYN choose default
adasyn_featuresAreNormalized    = false;    %false lets ADASYN handle normalization
    
[adasyn_featuresSyn, adasyn_labelsSyn] = ADASYN(adasyn_features, adasyn_labels, adasyn_beta, adasyn_kDensity, adasyn_kSMOTE, adasyn_featuresAreNormalized);

end

