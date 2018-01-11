function [ rez_st3_templateRelevant ] = ExtractKilosortInfoUnaffected( signalOffset, signalLength_s, templateToTest, rez, fs, mergedTemplate )
%EXTRACTKILOSORTINFO Summary of this function goes here
%   Detailed explanation goes here
    startIndexToFind = (signalOffset * fs)+1;
    endIndexToFind = (startIndexToFind-1) + (signalLength_s * fs);

    if strcmp(mergedTemplate, 'YES')
        truth_ind = find((rez.st3(:,5) == templateToTest) & (rez.st3(:,1) >= startIndexToFind) & (rez.st3(:,1) <= endIndexToFind) );
    else
        truth_ind = find((rez.st3(:,2) == templateToTest) & (rez.st3(:,1) >= startIndexToFind) & (rez.st3(:,1) <= endIndexToFind) );   
    end
    rez_st3_templateRelevant = rez.st3(truth_ind,:);    
end

