function [ precision, recall ] = GenerateConfusionMatrix( finalResultTimes, rez_st3_templateRelevant )
%GENERATECONFUSIONMATRIX Summary of this function goes here
%   Detailed explanation goes here

    TP = 0;
    TN = 0;
    FP = 0;
    FN = 0;
    
    for I = 1 : numel(finalResultTimes)
        if( find(rez_st3_templateRelevant(:,1) == finalResultTimes(I)) > 0 )
           TP = TP + 1;
        else
           FP = FP + 1;
        end
    end
    
    for I = 1 : numel(rez_st3_templateRelevant(:,1))
        if( find(finalResultTimes(:) == rez_st3_templateRelevant(I,1)) > 0 )
           %TP = TP + 1;
        else
           FN = FN + 1;
        end
    end   
  
    precision = TP/(TP+FP);
    recall= TP/(TP+FN);
    
end

