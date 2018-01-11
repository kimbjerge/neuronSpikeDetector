%% - Print figures for testing different template channel sizes

dir = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\Generated_Emouse_Data\Simulation_10min_30kHz_DefVals\OptimalThreshold\';

load(strcat(dir, 'NXCOR_2D_General\MeanChannelPrecisionArray.mat'));
load(strcat(dir, 'NXCOR_2D_General\MeanChannelRecallArray.mat'));

MeanChannelPrecisionArrayNXCOR = meanChannelPrecisionArray;
MeanChannelRecallArrayNXCOR = meanChannelRecallArray;

load(strcat(dir, 'SAD\MeanChannelPrecisionArray.mat'));
load(strcat(dir, 'SAD\MeanChannelRecallArray.mat'));

MeanChannelPrecisionArraySAD = meanChannelPrecisionArray;
MeanChannelRecallArraySAD = meanChannelRecallArray;
MeanChannelRecallArraySAD(14) = MeanChannelRecallArraySAD(14)/10000;

load(strcat(dir, 'SSD\MeanChannelPrecisionArray.mat'));
load(strcat(dir, 'SSD\MeanChannelRecallArray.mat'));

MeanChannelPrecisionArraySSD = meanChannelPrecisionArraySSD;
MeanChannelRecallArraySSD = meanChannelRecallArraySSD;

xAxix = 1:2:31;

figure;
subplot(1,2,1);
plot(xAxix,MeanChannelPrecisionArrayNXCOR)
hold on;
plot(xAxix,MeanChannelPrecisionArraySSD)
hold on;
plot(xAxix,MeanChannelPrecisionArraySAD)
title('Precision rate compared to the template channel width');
xlabel('Number of channels');
ylabel('Precsion rate');
legend('NXCOR', 'SSD', 'SAD');

subplot(1,2,2); 
plot(xAxix,MeanChannelRecallArrayNXCOR)
hold on;
plot(xAxix,MeanChannelRecallArraySSD)
hold on;
plot(xAxix,MeanChannelRecallArraySAD)
title('Recall rate compared to the template channel width');
xlabel('Number of channels');
ylabel('Recall rate');
legend('NXCOR', 'SSD', 'SAD');

print -depsc CombinedPrecisionNRecall

figure;
subplot(1,2,1);
plot(xAxix,1-(MeanChannelPrecisionArrayNXCOR./xAxix))
hold on;
plot(xAxix,1-(MeanChannelPrecisionArraySSD./xAxix))
hold on;
plot(xAxix,1-(MeanChannelPrecisionArraySAD./xAxix))
title('Precision rate compared to the computational load');
xlabel('Number of channels');
ylabel('Precsion Cost');
legend('NXCOR', 'SSD', 'SAD');

subplot(1,2,2); 
plot(xAxix,1-(MeanChannelRecallArrayNXCOR./xAxix))
hold on;
plot(xAxix,1-(MeanChannelRecallArraySSD./xAxix))
hold on;
plot(xAxix,1-(MeanChannelRecallArraySAD./xAxix))
title('Recall rate compared to the computational load');
xlabel('Number of channels');
ylabel('Recall cost');
legend('NXCOR', 'SSD', 'SAD');

print -depsc CombinedPrecisionNRecallCost

%% Print figures for testing different template legth sizes
dir = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\Generated_Emouse_Data\Simulation_10min_30kHz_DefVals\OptimalThreshold\';
load(strcat(dir, 'NXCOR_2D_General\channels_9\PrecisionRecallMeanTemplateSizeNXCOR.mat'));
load(strcat(dir, 'SSD\channels_9\PrecisionRecallMeanTemplateSizeSSD.mat'));
load(strcat(dir, 'SAD\channels_9\PrecisionRecallMeanTemplateSizeSAD.mat'));

xAxix = SADStruct.templateSizes;


figure;
subplot(1,2,1);
plot(xAxix,NXCORStruct.meanChannelPrecision)
hold on;
plot(xAxix,SSDStruct.meanChannelPrecision)
hold on;
plot(xAxix,SADStruct.meanChannelPrecision)
title('Precision rate compared to the template length');
xlabel('Number of samples');
ylabel('Precsion rate');
legend('NXCOR', 'SSD', 'SAD');

subplot(1,2,2); 
plot(xAxix,NXCORStruct.meanChannelRecall)
hold on;
plot(xAxix,SSDStruct.meanChannelRecall)
hold on;
plot(xAxix,SADStruct.meanChannelRecall)
title('Recall rate compared to the template length');
xlabel('Number of samples');
ylabel('Recall rate');
legend('NXCOR', 'SSD', 'SAD');

print -depsc CombinedPrecisionNRecallLength

divider = 1:9;

figure;
subplot(1,2,1);
plot(xAxix,1-(NXCORStruct.meanChannelPrecision./divider))
hold on;
plot(xAxix,1-(SSDStruct.meanChannelPrecision./divider))
hold on;
plot(xAxix,1-(SADStruct.meanChannelPrecision./divider))
title('Precision rate compared to the computational load');
xlabel('Number of samples');
ylabel('Precsion Cost');
legend('NXCOR', 'SSD', 'SAD');

subplot(1,2,2); 
plot(xAxix,1-(NXCORStruct.meanChannelRecall./divider))
hold on;
plot(xAxix,1-(SSDStruct.meanChannelRecall./divider))
hold on;
plot(xAxix,1-(SADStruct.meanChannelRecall./divider))
title('Recall rate compared to the computational load');
xlabel('Number of samples');
ylabel('Recall cost');
legend('NXCOR', 'SSD', 'SAD');

print -depsc CombinedPrecisionNRecallLengthCost

%%  For latex plot template 5 with fewer channels overlaid
    PrePath = 'C:\Users\cvlab\Dropbox\Master Engineer\Master Thesis\';
    DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
    pathToNPYMaster = strcat(PrePath, 'masterProject\npy-matlab-master');
    
    template = PrepareTemplate( strcat(DiectoryToEvaluate,'\templates.npy'), 5, [1:32], 1, pathToNPYMaster, 'NO', 'NO');

    figure('rend','painters','pos',[500 500 900 400]);
    subplot(1,2,1);
    surf(template);
    title(['Template: ' num2str(5) ', All channels'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
      axis tight;
    subplot(1,2,2);
    surf(template(:,12:22));
    title(['Template: ' num2str(5) ', 11 channels'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    axis tight;
    
    print -depsc Template5NTemplate511Channels
    
%% - Plot figure for gaussian scaling

    PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
    DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Diverse');
    pathToNPYMaster = strcat(PrePath, 'masterProject\npy-matlab-master');
    
    load(strcat(DiectoryToEvaluate, '\Signal16x150000AfterGaussianFiltering.mat'));
    load(strcat(DiectoryToEvaluate, '\Signal32x300000BeforeGaussianFiltering.mat'));
    load(strcat(DiectoryToEvaluate, '\Template16x31AfterGaussianFiltering.mat'));
    load(strcat(DiectoryToEvaluate, '\Template32x61BeforeGaussianFiltering.mat'));

    figure
    subplot(2,2,1);
    surf(templateOld);
    title(['Template: ' num2str(1) ' - Original'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    subplot(2,2,2);
    surf(template);
    title(['Template: ' num2str(1) ' - Filtered and scaled'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    subplot(2,2,3);
    surf(signalOld(300:400,:));
    title(['Snippet of original signal with template match'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    subplot(2,2,4);
    surf(signal(150:200,:));
    title(['Snippet of filtered and scaled signal with template match'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    
    print -depsc GaussianScaling
    
    load(strcat(DiectoryToEvaluate, '\GaussianNXCORResult.mat'));
    load(strcat(DiectoryToEvaluate, '\NXCORResult.mat'));
    load(strcat(DiectoryToEvaluate, '\grundTruth.mat'));
    
    
    figure
    subplot(1,2,1);
    plot(result);
    hold on;
    plot(grundTruth.gtRes, result(grundTruth.gtRes), 'r*');
    title(['NXCOR Original - Template 1'])
    xlabel('Correlation'),ylabel('NXCOR Score')
    subplot(1,2,2);
    plot(Gaussianresult);
    hold on;
    grundTruth.gtRes = floor(grundTruth.gtRes./2)+1; 
    plot(grundTruth.gtRes, Gaussianresult(grundTruth.gtRes), 'r*');
    title(['NXCOR Scaled and filtering - Template 1'])
    xlabel('Correlation'),ylabel('NXCOR Score')
    
    print -depsc GaussianScalingNXCOR

    %% Compute Four-level Multiresolution Pyramid of Image
    I = imread('cameraman.tif');
    
    I1 = impyramid(I, 'reduce');
    
    figure;
    subplot(1,2,1)
    imshow(I);
    title('Original');
    Hax = subplot(1,2,2);
    imshow(I1);
    [x,y] = size(I1);
    set(Hax,'units','pixel');
    pos = get(Hax,'position');
    pos(3:4) = [y,x];
    set(Hax,'position',pos)
    title('Next step in Gaussian pyramid');
    
    print -depsc gaussingScalingExample
    
    %% Make introduction figures
    PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
    DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');
    pathToNPYMaster = strcat(PrePath, 'masterProject\npy-matlab-master');
    load(strcat(DiectoryToEvaluate, '\rez.mat'));
    
    Oldsignal = PrepareData( strcat(DiectoryToEvaluate,'\sim_binary.dat'), 1:32, rez, 0, ...
                                                                                 10, 1, 'NO', 'Kilosort', 30000, 'NO', 'NO');

    figure
    surf(Oldsignal(1:100, :));
    title(['Snippet of original signal without neuron firing'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    zlim([-3000 2000]);
    
    print -depsc UnfilteredData100SamplesNoSpike
    
    figure
    surf(Oldsignal(300:400,:));
    title(['Snippet of original signal with neuron firing'])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    zlim([-3000 2000]);
    
    print -depsc UnfilteredData100SamplesSpike
    
    
    %% - Plot noise investiagation outputs
    PrecisionNXCOR = [0.9598 0.9342 0.8334 0.8347 0.7887];
    PrecisionNSSD = [0.9941 0.9379 0.8515 0.8088 0.7786];
    PrecisionNSAD = [0.9883 0.9226 0.8530 0.7516 0.6948];
    RecallNXCOR = [0.9356 0.7600 0.8415 0.7559 0.6852];
    RecallNSSD = [0.9055 0.7482 0.7970 0.7770 0.7324];
    RecallNSAD = [0.8437 0.6208 0.5768 0.5112 0.3893];
    %XAxis = [30 15 10 7.5 6];
    XAxisdB = [19.35 13.92 10.36 8.04 6.19];
    
    figure('rend','painters','pos',[500 500 900 400]);
    subplot(1,2,1);
    plot(XAxisdB,PrecisionNXCOR, 'r'); 
    hold on;
    plot(XAxisdB,PrecisionNSSD, 'g'); 
    hold on;
    plot(XAxisdB,PrecisionNSAD, 'b'); 
    hold off;
    legend('NXCOR', 'NSSD', 'NSAD');
    xlabel('SNR [dB]');
    ylabel('Precision');
    title('Precision compared to the SNR of the data');
    
    subplot(1,2,2);
    plot(XAxisdB,RecallNXCOR, 'r'); 
    hold on;
    plot(XAxisdB,RecallNSSD, 'g'); 
    hold on;
    plot(XAxisdB,RecallNSAD, 'b'); 
    hold off;
    legend('NXCOR', 'NSSD', 'NSAD');
    xlabel('SNR [dB]');
    ylabel('Recall');
    title('Recall compared to the SNR of the data');
    
    %print -depsc SNRInfluenceOnAlgo
    
    %% Plot precision and recall comparasion
    close all;
    
    dir = 'D:\Dropbox\Master Engineer\Master Thesis\MatlabProject\Simulation_10min_30kHz_DefVals\TrainedClassifiers\';

    addpath('D:\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabFunctions');
    
    LineWidth = 1.5;
    
    load(strcat(dir, 'SVM_1D_Lin_PreRecArrays.mat'));
    load(strcat(dir, 'SVM_2D_Lin_PreRecArrays.mat'));
    load(strcat(dir, 'SVM_3D_Lin_PreRecArrays.mat'));
    load(strcat(dir, 'SVM_1D_RBF_PreRecArrays.mat'));
    load(strcat(dir, 'SVM_2D_RBF_PreRecArrays.mat'));
    load(strcat(dir, 'SVM_3D_RBF_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_1D_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_2D_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_3D_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_1D_ADASYN_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_2D_ADASYN_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_3D_ADASYN_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_1D_Penalized_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_2D_Penalized_PreRecArrays.mat'));
    load(strcat(dir, 'QDA_3D_Penalized_PreRecArrays.mat'));
    load(strcat(dir, 'LinReg_1D_PreRecArrays.mat'));
    load(strcat(dir, 'LinReg_2D_PreRecArrays.mat'));
    load(strcat(dir, 'LinReg_3D_PreRecArrays.mat'));
    load(strcat(dir, 'QuaReg_1D_PreRecArrays.mat'));
    load(strcat(dir, 'QuaReg_2D_PreRecArrays.mat'));
    load(strcat(dir, 'QuaReg_3D_PreRecArrays.mat'));
    load(strcat(dir, 'CubReg_1D_PreRecArrays.mat'));
    load(strcat(dir, 'CubReg_2D_PreRecArrays.mat'));
    load(strcat(dir, 'CubReg_3D_PreRecArrays.mat'));
    load(strcat(dir, 'DecTree_1D_PreRecArrays.mat'));
    load(strcat(dir, 'DecTree_2D_PreRecArrays.mat'));
    load(strcat(dir, 'DecTree_3D_PreRecArrays.mat'));
    load(strcat(dir, 'TTV1_1D_PreRecArrays.mat'));
    load(strcat(dir, 'TTV2_1D_PreRecArrays.mat'));
    
    
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_1D_PrecisionArray);
    hold on;
    line2 = plot(1:26, QuaReg_1D_PrecisionArray);
    hold on;
    line3 = plot(1:26, CubReg_1D_PrecisionArray);
    hold on;
    line4 = plot(1:26, QDA_1D_PrecisionArray);
    hold on;
    line5 = plot(1:26, QDA_1D_ADASYN_PrecisionArray);
    hold on;
    line6 = plot(1:26, QDA_1D_PENALIZED_PrecisionArray);
    hold on;
    line7 = plot(1:26, SVM_1D_Lin_PrecisionArray);
    hold on;
    line8 = plot(1:26, SVM_1D_RBF_PrecisionArray);
    hold on;
    line9 = plot(1:26, TTV1_1D_PrecisionArray);
    hold on;
    line10 = plot(1:26, TTV2_1D_PrecisionArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    set(line8(1),'linewidth', LineWidth); 
    set(line9(1),'linewidth', LineWidth); 
    set(line10(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Precision rate');
    legend('LinReg1D','QuaReg1D','CubReg1D','QDA1D','QDAAdasyn1D','QDAPenalized1D','LinSVM1D','RBFSVM1D','TTV11D','TTV21D');
    title('Precision rates for each template - 1D algorithms');
    %print -depsc Precision1DAlgosTemplatesAll
    
    
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_1D_PrecisionArray);
    hold on;
    line2 = plot(1:26, QuaReg_1D_PrecisionArray);
    hold on;
    line3 = plot(1:26, CubReg_1D_PrecisionArray);
    hold on;
    line4 = plot(1:26, SVM_1D_Lin_PrecisionArray);
    hold on;
    line5 = plot(1:26, SVM_1D_RBF_PrecisionArray);
    hold on;
    line6 = plot(1:26, TTV1_1D_PrecisionArray);
    hold on;
    line7 = plot(1:26, TTV2_1D_PrecisionArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylim([0.87 1.005])
    ylabel('Precision rate');
    legend('LinReg1D','QuaReg1D','CubReg1D','LinSVM1D','RBFSVM1D','TTV11D','TTV21D');
    title('Precision rates for each template - 1D algorithms - QDA algorithms removed');
    %print -depsc Precision1DAlgosTemplatesGood
    

    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_1D_RecallArray);
    hold on;
    line2 = plot(1:26, QuaReg_1D_RecallArray);
    hold on;
    line3 = plot(1:26, CubReg_1D_RecallArray);
    hold on;
    line4 = plot(1:26, QDA_1D_RecalArray);
    hold on;
    line5 = plot(1:26, QDA_1D_ADASYN_RecalArray);
    hold on;
    line6 = plot(1:26, QDA_1D_PENALIZED_RecalArray);
    hold on;
    line7 = plot(1:26, SVM_1D_Lin_RecalArray);
    hold on;
    line8 = plot(1:26, SVM_1D_RBF_RecalArray);
    hold on;
    line9 = plot(1:26, TTV1_1D_RecallArray);
    hold on;
    line10 = plot(1:26, TTV2_1D_RecallArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    set(line8(1),'linewidth', LineWidth); 
    set(line9(1),'linewidth', LineWidth); 
    set(line10(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Recall rate');
    legend('LinReg1D','QuaReg1D','CubReg1D','QDA1D','QDAAdasyn1D','QDAPenalized1D','LinSVM1D','RBFSVM1D','TTV11D','TTV21D');
    title('Recall rates for each template - 1D algorithms');
    %print -depsc Recall1DAlgosTemplatesAll
    
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_1D_RecallArray);
    hold on;
    line2 = plot(1:26, QuaReg_1D_RecallArray);
    hold on;
    line3 = plot(1:26, CubReg_1D_RecallArray);
    hold on;
    line4 = plot(1:26, SVM_1D_Lin_RecalArray);
    hold on;
    line5 = plot(1:26, SVM_1D_RBF_RecalArray);
    hold on;
    line6 = plot(1:26, TTV1_1D_RecallArray);
    hold on;
    line7 = plot(1:26, TTV2_1D_RecallArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylim([0.6 1.005])
    ylabel('Recall rate');
    legend('LinReg1D','QuaReg1D','CubReg1D','LinSVM1D','RBFSVM1D','TTV11D','TTV21D');
    title('Recall rates for each template - 1D algorithms - QDA algorithms removed');
    %print -depsc Recall1DAlgosTemplatesGood
    
    
    LinReg_1D_F1 = CalculateF1Score(LinReg_1D_PrecisionArray, LinReg_1D_RecallArray);
    QuaReg_1D_F1 = CalculateF1Score(QuaReg_1D_PrecisionArray, QuaReg_1D_RecallArray);
    CubReg_1D_F1 = CalculateF1Score(CubReg_1D_PrecisionArray, CubReg_1D_RecallArray);
    SVMRBF_1D_F1 = CalculateF1Score(SVM_1D_RBF_PrecisionArray, SVM_1D_RBF_RecalArray);
    SVMLIN_1D_F1 = CalculateF1Score(SVM_1D_Lin_PrecisionArray, SVM_1D_Lin_RecalArray);
    TTV1_1D_F1 = CalculateF1Score(TTV1_1D_PrecisionArray, TTV1_1D_RecallArray);
    TTV2_1D_F1 = CalculateF1Score(TTV2_1D_PrecisionArray, TTV2_1D_RecallArray);
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_1D_F1);
    hold on;
    line2 = plot(1:26, QuaReg_1D_F1);
    hold on;
    line3 = plot(1:26, CubReg_1D_F1);
    hold on;
    line4 = plot(1:26, SVMLIN_1D_F1);
    hold on;
    line5 = plot(1:26, SVMRBF_1D_F1);
    hold on;
    line6 = plot(1:26, TTV1_1D_F1);
    hold on;
    line7 = plot(1:26, TTV2_1D_F1);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylim([0.6 1.005])
    ylabel('Weighted F1 score');
    legend('LinReg1D','QuaReg1D','CubReg1D','LinSVM1D','RBFSVM1D','TTV11D','TTV21D');
    title('Weighted F1 score for each template - 1D algorithms - QDA algorithms removed');
    %print -depsc F11DAlgosTemplatesGood
    
    
    
    
    % -------------------- 2D --------------------------------
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_2D_PrecisionArray);
    hold on;
    line2 = plot(1:26, QuaReg_2D_PrecisionArray);
    hold on;
    CubReg_2D_PrecisionArray(find(CubReg_2D_PrecisionArray == 0)) = NaN;
    line3 = plot(1:26, CubReg_2D_PrecisionArray);
    hold on;
    line4 = plot(1:26, QDA_2D_PrecisionArray);
    hold on;
    line5 = plot(1:26, QDA_2D_ADASYN_PrecisionArray);
    hold on;
    line6 = plot(1:26, QDA_2D_PENALIZED_PrecisionArray);
    hold on;
    line7 = plot(1:26, SVM_2D_Lin_PrecisionArray);
    hold on;
    line8 = plot(1:26, SVM_2D_RBF_PrecisionArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    set(line8(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Precision rate');
    legend('LinReg2D','QuaReg2D','CubReg2D','QDA2D','QDAAdasyn2D','QDAPenalized2D','LinSVM2D','RBFSVM2D'); 
    title('Precision rates for each template - 2D algorithms');
    %print -depsc Precision2DAlgosTemplatesAll
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_2D_RecallArray);
    hold on;
    line2 = plot(1:26, QuaReg_2D_RecallArray);
    hold on;
    CubReg_2D_RecallArray(find(CubReg_2D_RecallArray == 0)) = NaN;
    line3 = plot(1:26, CubReg_2D_RecallArray);
    hold on;
    line4 = plot(1:26, QDA_2D_RecalArray);
    hold on;
    line5 = plot(1:26, QDA_2D_ADASYN_RecalArray);
    hold on;
    line6 = plot(1:26, QDA_2D_PENALIZED_RecalArray);
    hold on;
    line7 = plot(1:26, SVM_2D_Lin_RecalArray);
    hold on;
    line8 = plot(1:26, SVM_2D_RBF_RecalArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    set(line8(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Recall rate');
    legend('LinReg2D','QuaReg2D','CubReg2D','QDA2D','QDAAdasyn2D','QDAPenalized2D','LinSVM2D','RBFSVM2D');
    title('Recall rates for each template - 2D algorithms');
    %print -depsc Recall2DAlgosTemplatesAll
    
    
    LinReg_2D_F1 = CalculateF1Score(LinReg_2D_PrecisionArray, LinReg_1D_RecallArray);
    QuaReg_2D_F1 = CalculateF1Score(QuaReg_2D_PrecisionArray, QuaReg_1D_RecallArray);
    CubReg_2D_F1 = CalculateF1Score(CubReg_2D_PrecisionArray, CubReg_1D_RecallArray);
    QDA_2D_F1 = CalculateF1Score(QDA_2D_PrecisionArray,QDA_2D_RecalArray );
    QDA_2D_ADASYN_F1 = CalculateF1Score(QDA_2D_ADASYN_PrecisionArray,QDA_2D_ADASYN_RecalArray );
    QDA_2D_Penalized_F1 = CalculateF1Score(QDA_2D_PENALIZED_PrecisionArray,QDA_2D_PENALIZED_RecalArray );
    SVMRBF_2D_F1 = CalculateF1Score(SVM_2D_RBF_PrecisionArray, SVM_2D_RBF_RecalArray);
    SVMLIN_2D_F1 = CalculateF1Score(SVM_2D_Lin_PrecisionArray, SVM_2D_Lin_RecalArray);
    
    figure('rend','painters','pos',[200 200 1200 600]);
    LinReg_2D_F1(find(LinReg_2D_F1 == 0)) = NaN;
    line1 = plot(1:26, LinReg_2D_F1);
    hold on;
    QuaReg_2D_F1(find(QuaReg_2D_F1 == 0)) = NaN;
    line2 = plot(1:26, QuaReg_2D_F1);
    hold on;
    CubReg_2D_F1(find(CubReg_2D_F1 == 0)) = NaN;
    line3 = plot(1:26, CubReg_2D_F1);
    hold on;
%     plot(1:26, QDA_2D_F1);
%     hold on;
%     plot(1:26, QDA_2D_ADASYN_F1);
%     hold on;
%     QDA_2D_Penalized_F1(find(QDA_2D_Penalized_F1 == 0)) = NaN;
%     plot(1:26, QDA_2D_Penalized_F1);
%     hold on;
    line4 = plot(1:26, SVMRBF_2D_F1);
    hold on;
     SVMLIN_2D_F1(find(SVMLIN_2D_F1 == 0)) = NaN;
    line5 = plot(1:26, SVMLIN_2D_F1);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Weighted F1 score');
    %legend('LinReg2D','QuaReg2D','CubReg2D','QDA2D','QDAAdasyn2D','QDAPenalized2D','LinSVM2D','RBFSVM2D');
    legend('LinReg2D','QuaReg2D','CubReg2D','LinSVM2D','RBFSVM2D');
    title('Weighted F1 score for each template - 2D algorithms');
    %print -depsc F12DAlgosTemplatesGood
    
    
    % ----------------------------- 3D --------------------------------
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_3D_PrecisionArray);
    hold on;
    line2 = plot(1:26, QuaReg_3D_PrecisionArray);
    hold on;
    CubReg_3D_PrecisionArray(find(CubReg_3D_PrecisionArray == 0)) = NaN;
    line3 = plot(1:26, CubReg_3D_PrecisionArray);
    hold on;
    line4 = plot(1:26, QDA_3D_PrecisionArray);
    hold on;
    line5 = plot(1:26, QDA_3D_ADASYN_PrecisionArray);
    hold on;
    line6 = plot(1:26, QDA_3D_PENALIZED_PrecisionArray);
    hold on;
    line7 = plot(1:26, SVM_3D_Lin_PrecisionArray);
    hold on;
    line8 = plot(1:26, SVM_3D_RBF_PrecisionArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    set(line8(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Precision rate');
    legend('LinReg3D','QuaReg3D','CubReg3D','QDA3D','QDAAdasyn3D','QDAPenalized3D','LinSVM3D','RBFSVM3D'); 
    title('Precision rates for each template - 3D algorithms');
    %print -depsc Precision3DAlgosTemplatesAll
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_3D_RecallArray);
    hold on;
    line2 = plot(1:26, QuaReg_3D_RecallArray);
    hold on;
    CubReg_3D_RecallArray(find(CubReg_3D_RecallArray == 0)) = NaN;
    line3 = plot(1:26, CubReg_3D_RecallArray);
    hold on;
    line4 = plot(1:26, QDA_3D_RecalArray);
    hold on;
    line5 = plot(1:26, QDA_3D_ADASYN_RecalArray);
    hold on;
    line6 = plot(1:26, QDA_3D_PENALIZED_RecalArray);
    hold on;
    SVM_3D_Lin_RecalArray(find(SVM_3D_Lin_RecalArray == 0)) = NaN;
    line7 = plot(1:26, SVM_3D_Lin_RecalArray);
    hold on;
    SVM_3D_RBF_RecalArray(find(SVM_3D_RBF_RecalArray == 0)) = NaN;
    line8 = plot(1:26, SVM_3D_RBF_RecalArray);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    set(line6(1),'linewidth', LineWidth); 
    set(line7(1),'linewidth', LineWidth); 
    set(line8(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Recall rate');
    legend('LinReg3D','QuaReg3D','CubReg3D','QDA3D','QDAAdasyn3D','QDAPenalized3D','LinSVM3D','RBFSVM3D');
    title('Recall rates for each template - 3D algorithms');
    %print -depsc Recall3DAlgosTemplatesAll
    
        
    LinReg_3D_F1 = CalculateF1Score(LinReg_3D_PrecisionArray, LinReg_3D_RecallArray);
    QuaReg_3D_F1 = CalculateF1Score(QuaReg_3D_PrecisionArray, QuaReg_3D_RecallArray);
    CubReg_3D_F1 = CalculateF1Score(CubReg_3D_PrecisionArray, CubReg_3D_RecallArray);
    QDA_3D_F1 = CalculateF1Score(QDA_3D_PrecisionArray,QDA_3D_RecalArray );
    QDA_3D_ADASYN_F1 = CalculateF1Score(QDA_3D_ADASYN_PrecisionArray,QDA_3D_ADASYN_RecalArray );
    QDA_3D_Penalized_F1 = CalculateF1Score(QDA_3D_PENALIZED_PrecisionArray,QDA_3D_PENALIZED_RecalArray );
    SVMRBF_3D_F1 = CalculateF1Score(SVM_3D_RBF_PrecisionArray, SVM_3D_RBF_RecalArray);
    SVMLIN_3D_F1 = CalculateF1Score(SVM_3D_Lin_PrecisionArray, SVM_3D_Lin_RecalArray);
    
    figure('rend','painters','pos',[200 200 1200 600]);
    line1 = plot(1:26, LinReg_3D_F1);
    hold on;
    line2 = plot(1:26, QuaReg_3D_F1);
    hold on;
    CubReg_3D_F1(find(CubReg_3D_F1 == 0)) = NaN;
    line3 = plot(1:26, CubReg_3D_F1);
    hold on;
%     plot(1:26, QDA_3D_F1);
%     hold on;
%     plot(1:26, QDA_3D_ADASYN_F1);
%     hold on;
%     plot(1:26, QDA_3D_ADASYN_F1);
%     hold on;
    SVMLIN_3D_F1(find(SVMLIN_3D_F1 == 0)) = NaN;
    line4 = plot(1:26, SVMLIN_3D_F1);
    hold on;
    SVMRBF_3D_F1(find(SVMRBF_3D_F1 == 0)) = NaN;
    line5 = plot(1:26, SVMRBF_3D_F1);
    hold off;
    set(line1(1),'linewidth', LineWidth); 
    set(line2(1),'linewidth', LineWidth); 
    set(line3(1),'linewidth', LineWidth); 
    set(line4(1),'linewidth', LineWidth); 
    set(line5(1),'linewidth', LineWidth); 
    xlabel('Templates');
    ylabel('Weighted F1 score');
    %legend('LinReg3D','QuaReg3D','CubReg3D','QDA3D','QDAAdasyn3D','QDAPenalized3D','LinSVM3D','RBFSVM3D');
    legend('LinReg3D','QuaReg3D','CubReg3D','LinSVM3D','RBFSVM3D');
    title('Weighted F1 score for each template - 3D algorithms');
    %print -depsc F13DAlgosTemplatesGood
    
    
    
    %%
    KiloSortSpikeDetection = [0.983, 0.983, 0.947, 0.961, 0.934];
    OurSpikeDetection = [0.985, 0.981, 0.954, 0.906, 0.868];
    SNR = [19.35 13.92 10.36 8.04 6.19];
    
    figure('rend','painters','pos',[200 200 800 300]);
    plot(SNR, KiloSortSpikeDetection);
    hold on;
    plot(SNR, OurSpikeDetection);
    hold off;
    legend('KiloSort','Proposed');
    title('Noise performance between KiloSort and proposed spike detection algorithm');
    xlabel('SNR [dB]');
    ylabel('F1_W');
    ylim([0.8 1.02]);
    %print -depsc KiloSortSpikeDetectVSOur
    
    %%
    NumberOfOperationsBytes = [4, 40, 400, 4000, 40000, 400000, 4000000, 40000000, 400000000, 2000000000];
    TimeExeToDevice = [0.05, 0.05, 0.05, 0.05, 0.078, 0.157, 1.193, 13.60, 135.09, 709.63];
    TimeExeFromDevice = [0.061, 0.061, 0.061, 0.063, 0.064, 0.103, 0.45, 3.53, 33.86, 197.61];
    
    figure('rend','painters','pos',[200 200 800 375]);
    loglog(NumberOfOperationsBytes, TimeExeToDevice);
    hold on;
    loglog(NumberOfOperationsBytes, TimeExeFromDevice);
    legend('MemCpy to device', 'MemCpy from device');
    title('Memory transfer time between host (CPU) and device (GPU)');
    xlabel('Memory size [bytes]');
    ylabel('Execution Time [ms]');
    %ylim([0.8 1.02]);
    %print -depsc MemoryTransferTime
    
    %% Channel Filter Thread Count Test
    
   Threads = [1 2 4 8 16 32];
   ExecutionTime = [49.68 36.29 29.01 27.63 31.80 33.62];
   
    X = 1:6;
   
   figure('rend','painters','pos',[200 200 650 260]);
   bar(ExecutionTime,'FaceColor', [0 .5 0],'BarWidth',0.5)
   set(gca,'xticklabel',{'1','2','4','8','16','32'});
   labels = arrayfun(@(value) num2str(value,'%2.2f'),ExecutionTime,'UniformOutput',false);
   text(X,ExecutionTime,labels,'HorizontalAlignment','center','VerticalAlignment','bottom') 
   % clears X axis data
   %set(gca,'XTick',[]);
   title('Channel filtering as a function of # of threads for 10 minutes of data');
   xlabel('Thread Count');
   ylabel('Execution Time [s]');
   ylim([0 60]);
   %print -depsc ChannelFilterThreadTest
   
   %% Channel Filter Scaling
   
   TimeBase = [ 0.004 0.1 1 10 100 600 ]; % Seconds
   
   Channels32 =   [ 0.00016 0.0038 0.043 0.399 3.75 22.8 ];
   Channels64 =   [ 0.00016 0.0039 0.044 0.412 3.87 22.9 ];
   Channels128 =  [ 0.00016 0.0043 0.045 0.418 3.9 22.9 ];
   Channels256 =  [ 0.00016 0.0048 0.049 0.433 4.23 24.91 ];
   Channels512 =  [ 0.00017 0.0057 0.057 0.506 4.87 29 ];
   Channels1024 = [ 0.00023 0.0062 0.061 0.542 5.42 32.52 ];
   
   figure('rend','painters','pos',[200 200 850 350]);  
   loglog(Channels32,TimeBase);
   hold on;
   grid on;
   loglog(Channels64,TimeBase);
   loglog(Channels128,TimeBase);
   loglog(Channels256,TimeBase);
   loglog(Channels512,TimeBase);
   loglog(Channels1024,TimeBase);
   legend('32 Channels', '64 Channels', '128 Channels', '256 Channels', '512 Channels', '1024 Channels');
   title('Channel Filter Scaling');
   xlabel('Execution Time [s]');
   ylabel('Dataset Length [s]');
   %print -depsc ChannelFilterScaling
   
    %% Kernel Filter Scaling
   
   TimeBase = [ 0.004 0.1 1 10 100 600 ]; % Seconds
   
   Channels32 =   [ 0.000016 0.00009 0.00074 0.0073 0.070 0.44 ];
   Channels64 =   [ 0.000014 0.00013 0.0012 0.011 0.11 0.66 ];
   Channels128 =  [ 0.000016 0.00016 0.0015 0.015 0.135 1.06 ];
   Channels256 =  [ 0.000022 0.00029 0.0028 0.028 0.262 1.66 ];
   Channels512 =  [ 0.000030 0.00050 0.0048 0.048 0.425 2.91 ];
   Channels1024 = [ 0.000048 0.00085 0.0085 0.083 0.708 4.98 ];
   
   figure('rend','painters','pos',[200 200 850 350]);   
   loglog(Channels32,TimeBase);
   hold on;
   grid on;
   loglog(Channels64,TimeBase);
   loglog(Channels128,TimeBase);
   loglog(Channels256,TimeBase);
   loglog(Channels512,TimeBase);
   loglog(Channels1024,TimeBase);
   legend('32 Channels', '64 Channels', '128 Channels', '256 Channels', '512 Channels', '1024 Channels');
   title('Kernel Filter Scaling');
   xlabel('Execution Time [s]');
   ylabel('Dataset Length [s]');
   %print -depsc KernelFilterScaling
   
   %% Correspondence Matching Scaling
   
   TimeBase = [ 0.004 0.1 1 10 100 600 ]; % Seconds
   
   Templates64 =   [ 0.0006 0.011 0.133 1.44 14.5 86.3 ];
   Templates128 =  [ 0.0016 0.022 0.308 2.89 29.22 188.37 ];
   Templates256 =  [ 0.0024 0.042 0.749 6.1 60.15 358.27 ];
   Templates512 =  [ 0.0044 0.086 1.08 11.21 107.73 703.21 ];
   Templates1024 = [ 0.0085 0.175 2.07 21.42 222.02 1454.32 ];
   Templates2048 = [ 0.016 0.3 3.84 39.32 395.36 2903.66 ];
   
   figure('rend','painters','pos',[200 200 850 350]);   
   loglog(Templates64,TimeBase);
   hold on;
   grid on;
   loglog(Templates128,TimeBase);
   loglog(Templates256,TimeBase);
   loglog(Templates512,TimeBase);
   loglog(Templates1024,TimeBase);
   loglog(Templates2048,TimeBase);
   legend('64 Templates', '128 Templates', '256 Templates', '512 Templates', '1024 Templates', '2048 Templates');
   title('Correspondence Matching Scaling');
   xlabel('Execution Time [s]');
   ylabel('Dataset Length [s]');
   %print -depsc CorrespondenceMatchingScaling
   
   %% Classification Scaling
   
   TimeBase = [ 0.004 0.1 1 10 100 600 ]; % Seconds
   
   Templates64 =   [ 0.000014 0.00003 0.00018 0.0018 0.018 0.18 ];
   Templates128 =  [ 0.000015 0.00004 0.00035 0.0037 0.036 0.35 ];
   Templates256 =  [ 0.000017 0.000072 0.00068 0.0068 0.068 0.69 ];
   Templates512 =  [ 0.000022 0.00013 0.00135 0.0125 0.129 1.33 ];
   Templates1024 = [ 0.000029 0.00025 0.0027 0.0226 0.221 2.35 ];
   Templates2048 = [ 0.000053 0.00047 0.00536 0.0454 0.464 4.89 ];
   
   figure('rend','painters','pos',[200 200 850 350]);   
   loglog(Templates64,TimeBase);
   hold on;
   grid on;
   loglog(Templates128,TimeBase);
   loglog(Templates256,TimeBase);
   loglog(Templates512,TimeBase);
   loglog(Templates1024,TimeBase);
   loglog(Templates2048,TimeBase);
   legend('64 Templates', '128 Templates', '256 Templates', '512 Templates', '1024 Templates', '2048 Templates');
   title('Classification (Prediction) Scaling');
   xlabel('Execution Time [s]');
   ylabel('Dataset Length [s]');
   %print -depsc ClassificationScaling
   
   
   %% SNR For in-vivo
    
   
   dir = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabScripts\Additional\';
   load(strcat(dir, 'SNRDataInVivoTest1000sek.mat'));
   
%    figure('rend','painters','pos',[200 200 850 350]);
%    plot(snrStruct.xaxis, 20*log10(snrStruct.snr));
%    hold on;
%    y = 20*log10(mean(snrStruct.snr));
%    line([0,64],[y,y], 'Color','red');
%    ylabel('SNR [dB]');
%    title('SNR for spikes related to specific templates');
%    xlabel('Template number');
%    legend('SNR values', 'Mean');
%    xlim([0 65]);
   
   figure('rend','painters','pos',[200 200 850 400]);
   bar(snrStruct.xaxis, 20*log10(snrStruct.snr))
   hold on;
   y = 20*log10(mean(snrStruct.snr));
   line([0,65],[y,y], 'Color','red');
   hold off;
   ylabel('SNR [dB]');
   title('SNR for spikes related to specific templates');
   xlabel('Template number');
   legend('SNR values', 'Mean');
   xlim([0 65]);
   ylim([-35 15]);
   %print -depsc SNRForTemplatesInVivo
   
   %% Performance for In-vivo
   dir = 'D:\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabScripts\Additional\';
   addpath('D:\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabFunctions');
   load(strcat(dir, 'predictionInVivo.mat'));
   
   F1wScores = CalculateF1Score(PredictionScoreInVivoStruct.PrecisionArray, PredictionScoreInVivoStruct.RecallArray);
   
   F1wScoresTotal = zeros(64,1);
   index = 1:64;
   for i = 1 : 64
      if(numel(find(PredictionScoreInVivoStruct.xAxisInd == i)) > 0)
        F1wScoresTotal(i) = F1wScores(find(PredictionScoreInVivoStruct.xAxisInd == i));
      end
   end
   %F1wScoresTotal(PredictionScoreInVivoStruct.xAxisInd) = F1wScores(PredictionScoreInVivoStruct.xAxisInd);
   
   figure('rend','painters','pos',[200 200 850 400]);
   bar(index, F1wScoresTotal)
   ylabel('F1_W');
   title('F1_W score for spikes related to specific templates');
   xlabel('Template number');
   xlim([0 65]);
   %legend('SNR values', 'Mean');
   %xlim([0 65]);
   %ylim([-35 15]);
   %print -depsc F1WScoreInvivo
   
   %% Number of spikes used to make SNR
      dir = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\MatlabProject\MatlabScripts\Additional\';
   load(strcat(dir, 'spikesUsedToMakeSNR1000sek.mat'));
%    figure('rend','painters','pos',[200 200 850 350]);
%    plot(snrStruct.xaxis, 20*log10(snrStruct.snr));
%    hold on;
%    y = 20*log10(mean(snrStruct.snr));
%    line([0,64],[y,y], 'Color','red');
%    ylabel('SNR [dB]');
%    title('SNR for spikes related to specific templates');
%    xlabel('Template number');
%    legend('SNR values', 'Mean');
%    xlim([0 65]);
   
   figure('rend','painters','pos',[200 200 850 400]);
   bar(1:64, numberOfSpikeTimesAllTemplates)
   %set(gca,'YScale','log');
   %hold on;
   %y = 20*log10(mean(snrStruct.snr));
   %line([0,65],[y,y], 'Color','red');
   %hold off;
   ylabel('Number of spikes');
   title('Number of spikes related to specific templates');
   xlabel('Template number');
   %legend('SNR values', 'Mean');
   xlim([0 65]);
   ylim([0 10000]);
   %print -depsc spikesForSNR1000sek
   