
PrePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\generated_emouse_data\Simulation_10min_30kHz_DefVals\PRCurveValues\';
 
load(strcat(PrePath,'NXCOR_2D_General_meanPrecision.mat'));
load(strcat(PrePath,'NXCOR_2D_General_meanRecall.mat'));

NXCOR_2D_General_meanPrecision = meanPrecision;
NXCOR_2D_General_meanRecall = meanRecall;

load(strcat(PrePath,'Laplacian_meanPrecision.mat'));
load(strcat(PrePath,'Laplacian_meanRecall.mat'));

Laplacian_meanPrecision = meanPrecision;
Laplacian_meanRecall = meanRecall;

load(strcat(PrePath,'Gradient_meanPrecision.mat'));
load(strcat(PrePath,'Gradient_meanRecall.mat'));

Gradient_meanPrecision = meanPrecision;
Gradient_meanRecall = meanRecall;

load(strcat(PrePath,'NSSD_meanPrecision.mat'));
load(strcat(PrePath,'NSSD_meanRecall.mat'));

NSSD_meanPrecision = meanPrecision;
NSSD_meanRecall = meanRecall;

load(strcat(PrePath,'LaplacianNSSD_meanPrecision.mat'));
load(strcat(PrePath,'LaplacianNSSD_meanRecall.mat'));

LaplacianNSSD_meanPrecision = meanPrecision;
LaplacianNSSD_meanRecall = meanRecall;

figure('rend','painters','pos',[500 500 750 400]);
plot([NXCOR_2D_General_meanRecall],[NXCOR_2D_General_meanPrecision]);
hold on;
plot([Laplacian_meanRecall],[Laplacian_meanPrecision]);
plot([Gradient_meanRecall],[Gradient_meanPrecision]);
plot([NSSD_meanRecall],[NSSD_meanPrecision]);
plot([LaplacianNSSD_meanRecall],[LaplacianNSSD_meanPrecision]);
legend('NXCOR 2D','NXCOR 2D Laplacian','NXCOR 2D Gradient','NSSD','NSSD Laplacian','Location','southeast');
title('Precision-Recall Curve');
xlabel('True positive rate (TPR) (Recall)');
ylabel('Positive predictive value (PPV) (Precision)');