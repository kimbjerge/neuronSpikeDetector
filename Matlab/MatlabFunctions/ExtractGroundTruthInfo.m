function [ GroundTruthRelevant ] = ExtractGroundTruthInfo( signalOffset, signalLength_s, templateSpikeOffset, templateToTest, groundTruthTable, fs, TemplatesSize, rez, isKiloSortTemplateMerged )
%EXTRACTKILOSORTINFO Summary of this function goes here
%   Detailed explanation goes here
    if TemplatesSize > (templateSpikeOffset*2)+1
        offsetSpike = templateSpikeOffset;
    else
        offsetSpike = ceil(TemplatesSize/2);
    end

    startIndexToFind = (signalOffset * fs)+1;
    endIndexToFind = (startIndexToFind-1) + (signalLength_s * fs) + offsetSpike;

    ClusterToTest = FindGroundTruthCluster( templateToTest, rez, groundTruthTable );
    
    truth_ind = find((groundTruthTable.gtClu == ClusterToTest) & (groundTruthTable.gtRes >= startIndexToFind) & (groundTruthTable.gtRes <= endIndexToFind) );

    GroundTruthRelevant.gtClu = groundTruthTable.gtClu(truth_ind);
    GroundTruthRelevant.gtRes = groundTruthTable.gtRes(truth_ind);
    GroundTruthRelevant.gtRes = GroundTruthRelevant.gtRes - (offsetSpike+1);
    %rez_st3_templateRelevant(:,1) = rez_st3_templateRelevant(:,1)-offsetSpike;
    
    [rez_st3_templateRelevant] = ExtractKilosortInfo( signalOffset, signalLength_s, templateSpikeOffset, templateToTest, rez, fs, TemplatesSize, isKiloSortTemplateMerged );
    ExtraOffset = VerifyOffset(rez_st3_templateRelevant, GroundTruthRelevant.gtRes);
    GroundTruthRelevant.gtRes = GroundTruthRelevant.gtRes + ExtraOffset;
    
    if signalOffset > 0
       offset = signalOffset * fs;
       GroundTruthRelevant.gtRes = GroundTruthRelevant.gtRes-offset;
    end
    
    if(numel(GroundTruthRelevant.gtRes) == 0)
       errorHappended = 1; 
    end
    
end

