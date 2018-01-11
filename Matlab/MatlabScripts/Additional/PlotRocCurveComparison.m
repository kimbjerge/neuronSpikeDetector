
PrePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\generated_emouse_data\Simulation_10min_30kHz_DefVals\RocCurveValues\';
 
load(strcat(PrePath,'NXCOR_2D_General_meanFallout.mat'));
load(strcat(PrePath,'NXCOR_2D_General_meanRecall.mat'));
load(strcat(PrePath,'Laplacian_meanFallout.mat'));
load(strcat(PrePath,'Laplacian_meanRecall.mat'));
load(strcat(PrePath,'Gradient_meanFallout.mat'));
load(strcat(PrePath,'Gradient_meanRecall.mat'));
load(strcat(PrePath,'NSSD_meanFallout.mat'));
load(strcat(PrePath,'NSSD_meanRecall.mat'));
load(strcat(PrePath,'LaplacianNSSD_meanFallout.mat'));
load(strcat(PrePath,'LaplacianNSSD_meanRecall.mat'));
load(strcat(PrePath,'SSD_meanFallout.mat'));
load(strcat(PrePath,'SSD_meanRecall.mat'));

NXCOR_2D_General_auc = trapz([1 NXCOR_2D_General_meanFallout],[1 NXCOR_2D_General_meanRecall]);
NXCOR_2D_General_auc = NXCOR_2D_General_auc*(-1);

Laplacian_auc = trapz([1 Laplacian_meanFallout],[1 Laplacian_meanRecall]);
Laplacian_auc = Laplacian_auc*(-1);

Gradient_auc = trapz([1 Gradient_meanFallout],[1 Gradient_meanRecall]);
Gradient_auc = Gradient_auc*(-1);

NSSD_auc = trapz([1 NSSD_meanFallout],[1 NSSD_meanRecall]);
NSSD_auc = NSSD_auc*(-1);

LaplacianNSSD_auc = trapz([1 LaplacianNSSD_meanFallout],[1 LaplacianNSSD_meanRecall]);
LaplacianNSSD_auc = LaplacianNSSD_auc*(-1);

SSD_auc = trapz([1 SSD_meanFallout],[1 SSD_meanRecall]);
SSD_auc = SSD_auc*(-1);

figure('rend','painters','pos',[500 500 1000 400]);
subplot(1,2,1);
plot([1 NXCOR_2D_General_meanFallout],[1 NXCOR_2D_General_meanRecall]);
hold on;
plot([1 Laplacian_meanFallout],[1 Laplacian_meanRecall]);
plot([1 Gradient_meanFallout],[1 Gradient_meanRecall]);
plot([1 NSSD_meanFallout],[1 NSSD_meanRecall]);
plot([1 LaplacianNSSD_meanFallout],[1 LaplacianNSSD_meanRecall]);
plot([1 SSD_meanFallout],[1 SSD_meanRecall]);
plot([0 1],[0 1],'--k');
legend('NXCOR 2D','NXCOR 2D Laplacian','NXCOR 2D Gradient','NSSD','NSSD Laplacian','SSD','Location','southeast');
title('Receiver operating characteristic (ROC)');
xlabel('False positive rate (FPR) (Fallout)');
ylabel('True positive rate (TPR) (Recall)');

subplot(1,2,2); 
plot([1 NXCOR_2D_General_meanFallout],[1 NXCOR_2D_General_meanRecall]);
hold on;
plot([1 Laplacian_meanFallout],[1 Laplacian_meanRecall]);
plot([1 Gradient_meanFallout],[1 Gradient_meanRecall]);
plot([1 NSSD_meanFallout],[1 NSSD_meanRecall]);
plot([1 LaplacianNSSD_meanFallout],[1 LaplacianNSSD_meanRecall]);
plot([1 SSD_meanFallout],[1 SSD_meanRecall]);
xlim([0 0.0005]);
ylim([0.9 1]);
legend('NXCOR 2D','NXCOR 2D Laplacian','NXCOR 2D Gradient','NSSD','NSSD Laplacian','SSD','Location','southeast');
title('ROC (zoomed)');
xlabel('False positive rate (FPR) (Fallout)');
ylabel('True positive rate (TPR) (Recall)');