function [ GroundTruthRelevant ] = ExtractGroundTruthInfoUnaffected( signalOffset, signalLength_s, templateToTest, groundTruthTable, fs, rez )
%EXTRACTKILOSORTINFO Summary of this function goes here
%   Detailed explanation goes here

    startIndexToFind = (signalOffset * fs)+1;
    endIndexToFind = (startIndexToFind-1) + (signalLength_s * fs);

    ClusterToTest = FindGroundTruthCluster( templateToTest, rez, groundTruthTable );
    
    truth_ind = find((groundTruthTable.gtClu == ClusterToTest) & (groundTruthTable.gtRes >= startIndexToFind) & (groundTruthTable.gtRes <= endIndexToFind) );

    GroundTruthRelevant.gtClu = groundTruthTable.gtClu(truth_ind);
    GroundTruthRelevant.gtRes = groundTruthTable.gtRes(truth_ind);
    
end

