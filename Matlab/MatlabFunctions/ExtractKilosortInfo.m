function [ rez_st3_templateRelevant ] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateToTest, rez, fs, TemplatesSize, mergedTemplate )
%EXTRACTKILOSORTINFO Summary of this function goes here
%   Detailed explanation goes here
    if TemplatesSize > (templateSpikeOffset*2)+1
        offsetSpike = templateSpikeOffset;
    else
        offsetSpike = ceil(TemplatesSize/2);
    end

    startIndexToFind = (signalOffset * fs)+1;
    endIndexToFind = (startIndexToFind-1) + (signalLength_s * fs) + offsetSpike;

    if strcmp(mergedTemplate, 'YES')
        truth_ind = find((rez.st3(:,5) == templateToTest) & (rez.st3(:,1) >= startIndexToFind) & (rez.st3(:,1) <= endIndexToFind) );
    else
        truth_ind = find((rez.st3(:,2) == templateToTest) & (rez.st3(:,1) >= startIndexToFind) & (rez.st3(:,1) <= endIndexToFind) );   
    end
    rez_st3_templateRelevant = rez.st3(truth_ind,:);
    rez_st3_templateRelevant(:,1) = rez_st3_templateRelevant(:,1)-offsetSpike;
    
    if signalOffset > 0
       offset = signalOffset * fs;
       rez_st3_templateRelevant(:,1) = rez_st3_templateRelevant(:,1)-offset;
    end
    
end

