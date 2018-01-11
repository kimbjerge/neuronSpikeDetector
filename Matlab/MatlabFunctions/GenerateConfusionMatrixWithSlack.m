function [ precision, recall,fallout, TP, TN, FP, FN ] = GenerateConfusionMatrixWithSlack( finalResultTimes, rez_st3_templateRelevant, slack, numberOfSamples )
%GENERATECONFUSIONMATRIX Summary of this function goes here
%   Detailed explanation goes here

    TP = 0;
    TN = 0;
    FP = 0;
    FN = 0;
    
    for I = 1 : numel(finalResultTimes)
        if( find(rez_st3_templateRelevant(:,1) == finalResultTimes(I)) > 0 )
           TP = TP + 1;
        elseif slack > 0
           for Y = 1 : slack
              if( find((rez_st3_templateRelevant(:,1)-Y) == finalResultTimes(I)) > 0 )
                 TP = TP + 1;
                 break;
              elseif find((rez_st3_templateRelevant(:,1)+Y) == finalResultTimes(I)) > 0
                 TP = TP + 1;
                 break;
              else
                 %FP = FP + 1; 
              end
              
              if Y == slack
                  FP = FP + 1;
                  break;
              end
           end 
        else
           FP = FP + 1;
        end
    end
    
    for I = 1 : numel(rez_st3_templateRelevant(:,1))
        if( find(finalResultTimes(:) == rez_st3_templateRelevant(I,1)) > 0 )
           %TP = TP + 1;
        elseif slack > 0
           for Y = 1 : slack
              if( find((finalResultTimes(:)-Y) == rez_st3_templateRelevant(I,1)) > 0 )
                 %TP = TP + 1;
                 break;
              elseif find((finalResultTimes(:)+Y) == rez_st3_templateRelevant(I,1)) > 0
                 %TP = TP + 1;
                 break;
              else
                 %FN = FN + 1; 
              end
              
              if Y == slack
                  FN = FN + 1;
                  break;
              end
           end 
        else
           FN = FN + 1;
        end
    end   
  
    TN = numberOfSamples - (TP + FP + FN);
    
    precision = TP/(TP+FP);
    recall = TP/(TP+FN);
    fallout = FP/(FP+TN);
end

