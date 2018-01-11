function [ ResultDiff ] = PerformTMAnalysis(RelevantRezFileST3, CCResult, threshold, PlotFigures, templateAnalysing, finalResultTimes, IsAlgorithmSimilarityBased, groundtruth)
%PERFORMTMCOMPARING Summary of this function goes here
%   Detailed explanation goes here

    size_truth = size(RelevantRezFileST3);
    size_cc = size(CCResult);
    
    x = 1 : size_cc(1);
    ccPermuted = permute(CCResult, [2 1]);
    rst3Permuted = permute(RelevantRezFileST3(:,1), [2 1]);
    
    if(strcmp(IsAlgorithmSimilarityBased, 'YES') == 1)
        rst3PermutedGood = rst3Permuted(find(ccPermuted(rst3Permuted) >= threshold));
        rst3PermutedBad = rst3Permuted(find(ccPermuted(rst3Permuted) < threshold));
    else
        rst3PermutedGood = rst3Permuted(find(-ccPermuted(rst3Permuted) >= -threshold));
        rst3PermutedBad = rst3Permuted(find(-ccPermuted(rst3Permuted) < -threshold));
    end
    
    if numel(finalResultTimes) > numel(RelevantRezFileST3(:,1))
        diff = numel(finalResultTimes) -  numel(RelevantRezFileST3(:,1));
        paddedArray = padarray(RelevantRezFileST3(:,1),diff, 'post');
        markAllResultNotFoundByKilosort = setdiff(finalResultTimes, paddedArray);
        markAllResultNotFoundByKilosort1 = setdiff(paddedArray, finalResultTimes);
    elseif numel(finalResultTimes) < numel(RelevantRezFileST3(:,1))
        diff = numel(RelevantRezFileST3(:,1)) - numel(finalResultTimes);
        paddedArray = padarray(finalResultTimes,diff, 'post');
        markAllResultNotFoundByKilosort = setdiff(RelevantRezFileST3(:,1), paddedArray);
        markAllResultNotFoundByKilosort1 = setdiff(paddedArray, RelevantRezFileST3(:,1));
    else
        paddedArray = RelevantRezFileST3(:,1);
        markAllResultNotFoundByKilosort = setdiff(finalResultTimes, paddedArray);
        markAllResultNotFoundByKilosort1 = setdiff(paddedArray, finalResultTimes);
    end
    
    if numel(find(markAllResultNotFoundByKilosort1 == 0)) > 0
        indexToThroughAway = find(markAllResultNotFoundByKilosort1 == 0);
        markAllResultNotFoundByKilosort1(indexToThroughAway) = [];
    end
    
    
    diffK2G = numel(groundtruth.gtRes) -  numel(RelevantRezFileST3(:,1));
    if diffK2G > 0
        paddedArrayK2G = padarray(RelevantRezFileST3(:,1),diffK2G, 'post');
        markAllResultK2G1 = setdiff(groundtruth.gtRes, paddedArrayK2G);
        markAllResultK2G2 = setdiff(paddedArrayK2G, groundtruth.gtRes);
        
        if numel(find(markAllResultK2G2 == 0)) > 0
            indexToThroughAway = find(markAllResultK2G2 == 0);
            markAllResultK2G2(indexToThroughAway) = [];
        end
        
        markAllResultK2G3 =  union(permute(markAllResultK2G1, [2 1]), permute(markAllResultK2G2, [2 1]));
    else
        markAllResultK2G3 = [];
    end
    
    if diffK2G < 0
        paddedArrayG2K = padarray(groundtruth.gtRes,abs(diffK2G), 'post');
        markAllResultG2K1 = setdiff(RelevantRezFileST3(:,1), paddedArrayG2K);
        markAllResultG2K2 = setdiff(paddedArrayG2K, RelevantRezFileST3(:,1));
        
        if numel(find(markAllResultG2K2 == 0)) > 0
            indexToThroughAway = find(markAllResultG2K2 == 0);
            markAllResultG2K2(indexToThroughAway) = [];
        end
        
        markAllResultG2K3 =  union(permute(markAllResultG2K1, [2 1]), permute(markAllResultG2K2, [2 1]));
    else
        markAllResultG2K3 = [];
    end
    
    markAllResultNotFoundByKilosort2 =  union(permute(markAllResultNotFoundByKilosort, [2 1]), permute(markAllResultNotFoundByKilosort1, [2 1])); 
    
    
    markAllResultK2G3(markAllResultK2G3>size_cc(1)) = [];
    markAllResultG2K3(markAllResultG2K3>size_cc(1)) = [];
    
    if strcmp(PlotFigures, 'YES') == 1
       figure('rend','painters','pos',[200 200 800 500]);
       %suptitle(['Correlation values with KiloSort and grund truth marked: Template: ', num2str(templateAnalysing)]);
       subplot(1,2,1)
       plot(x, CCResult);
       
       if numel(markAllResultNotFoundByKilosort2) > 0
            hold on
            plot(markAllResultNotFoundByKilosort2, ccPermuted(markAllResultNotFoundByKilosort2), 'r*');    
       end
       hold on
       plot(rst3PermutedGood, ccPermuted(rst3PermutedGood), 'g*');
       hold on
       plot(rst3PermutedBad, ccPermuted(rst3PermutedBad), 'm*');
       hold on
       plot(markAllResultK2G3, ccPermuted(markAllResultK2G3), 'k*');
       hold on
       plot(markAllResultG2K3, ccPermuted(markAllResultG2K3), 'y*');
       hold on
       hline = refline([0 threshold]);
       hline.Color = 'k';
       hold off
       %title(['Correlation values with KiloSort and grund truth marked: Template: ', num2str(templateAnalysing)]);
       %xlim([5.55*10^4 5.65*10^4])
       xlabel('Correlation samples');
       ylabel('Correlation rate');
       
       subplot(1,2,2)
       plot(x, CCResult, '*');
       if numel(markAllResultNotFoundByKilosort2) > 0
            hold on
            plot(markAllResultNotFoundByKilosort2, ccPermuted(markAllResultNotFoundByKilosort2), 'r*');    
       end
       hold on
       plot(rst3PermutedGood, ccPermuted(rst3PermutedGood), 'g*');
       hold on
       plot(rst3PermutedBad, ccPermuted(rst3PermutedBad), 'm*');
       hold on
       plot(markAllResultK2G3, ccPermuted(markAllResultK2G3), 'k*');
       hold on
       plot(markAllResultG2K3, ccPermuted(markAllResultG2K3), 'y*');
       hold on
       hline = refline([0 threshold]);
       hold off
       hline.Color = 'k';
       %title(['Zoomed - Correlation values with KiloSort and grund truth marked: Template: ', num2str(templateAnalysing)]);
       %xlim([5.55*10^4 5.65*10^4])
       xlabel('Correlation samples');
       ylabel('Correlation rate');
    end
    
    %print -depsc TrainedThresholdPrincip

end

