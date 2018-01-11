function [ finalResultPeaks, finalResultTimes] = GetValuesAboveThreshold(result, threshold, IsAlgorithmSimilarityBased )
%GETVALUESABOVETHRESHOLD Summary of this function goes here
%   Detailed explanation goes here

    
    finalResultPeaks = 0;
    finalResultTimes = 0;
    
    if(strcmp(IsAlgorithmSimilarityBased, 'NO') == 1)
        resultInv = -result;
        
        resultAboveTh = find(resultInv >= -threshold);
        resultInv(resultInv < -threshold) = -10*10^20;
        if numel(resultAboveTh) > 3
            [resultpeaks, resultInd] = findpeaks(resultInv);


            finalResultPeaks = resultInv(resultInd);
            finalResultTimes = resultInd;
        end
    else    
        resultAboveTh = find(result >= threshold);
        result(result < threshold) = 0;
        if numel(resultAboveTh) > 3
            [resultpeaks, resultInd] = findpeaks(double(result));


            finalResultPeaks = single(result(resultInd));
            finalResultTimes = single(resultInd);
        end
    end
    
end

