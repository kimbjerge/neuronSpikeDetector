function [ Accuracy, Hitrate, extraSpikes ] = CompareWithGroundTruth( finalResultTimes, rez_st3_templateRelevant, templateBeeingTested, PrintInfo )
%COMPAREWITHGROUNDTRUTH Summary of this function goes here
%   Detailed explanation goes here
    Accuracy = 0;
    ErrorMisses = 0;
    Hitrate = 0;
    if(numel(finalResultTimes) > numel(rez_st3_templateRelevant(:,1)))
        for I = 1 : numel(finalResultTimes)
            if( find(rez_st3_templateRelevant(:,1) == finalResultTimes(I)) > 0 )
               Accuracy = Accuracy + 1;
            else
               ErrorMisses = ErrorMisses + 1;
            end
        end
        
        if strcmp(PrintInfo, 'YES') == 1
            fprintf('Template %.0f: The algorithm found MORE matches than the ground truth!\n', templateBeeingTested);
        end
        Hitrate = (Accuracy/numel(rez_st3_templateRelevant(:,1)))*100;
        if strcmp(PrintInfo, 'YES') == 1
            fprintf('Template %.0f: The algorithm found: %.2f%% of the spikes which Kilosort found or generated!\n',templateBeeingTested, Hitrate);
        
            fprintf('Template %.0f: The algorithm also found: %.0f spikes which Kilosort did not register or generated!\n',templateBeeingTested, ErrorMisses);
        end
        extraSpikes = ErrorMisses;
        Accuracy = (Accuracy/numel(finalResultTimes))*100;

        if strcmp(PrintInfo, 'YES') == 1
            fprintf('Template %.0f: That makes the compared accuracy become: %.2f%%\n',templateBeeingTested, Accuracy);
        end
    else
        for I = 1 : numel(rez_st3_templateRelevant(:,1))
            if( find(finalResultTimes(:) == rez_st3_templateRelevant(I,1)) > 0 )
               Accuracy = Accuracy + 1; 
            else
                ErrorMisses = ErrorMisses + 1;
            end
        end
        if strcmp(PrintInfo, 'YES') == 1
            if numel(finalResultTimes) < numel(rez_st3_templateRelevant(:,1))
                fprintf('Template %.0f: The algorithm found LESS matches than the ground truth!\n',templateBeeingTested); 
            end
        end
        extraSpikes = ErrorMisses;
        Accuracy = (Accuracy/numel(rez_st3_templateRelevant(:,1)))*100;
        Hitrate = Accuracy;
        if strcmp(PrintInfo, 'YES') == 1
            fprintf('Template %.0f: The algorithm found: %.2f %% of the spikes compared to Kilosort\n',templateBeeingTested, Accuracy);
        end
    end

end

