function [ IsAlgorithmSimilarityBased ] = IsAlgorithmSimilarityBasedFunc( AlgorithmToTest )
%ISALGORITHMSIMILARITYBASED Summary of this function goes here
%   Detailed explanation goes here
if strcmp(AlgorithmToTest, 'XCOR_2D') == 1 || strcmp(AlgorithmToTest, 'XCOR_1D') == 1 || strcmp(AlgorithmToTest, 'SobelNXCOR') == 1 ||  ...
   strcmp(AlgorithmToTest, 'XCOR_2D_GPU') == 1 || strcmp(AlgorithmToTest, 'NXCOR_2D') == 1 || strcmp(AlgorithmToTest, 'NXCOR') == 1 ||...
   strcmp(AlgorithmToTest, 'NXCOR_2D_GPU') == 1 || strcmp(AlgorithmToTest, 'NXCOR_2D_General') == 1 || strcmp(AlgorithmToTest, 'LaplacianV2') == 1 ||...
   strcmp(AlgorithmToTest, 'Gradient') == 1 || strcmp(AlgorithmToTest, 'NXCOR_DRIFT') == 1 || strcmp(AlgorithmToTest, 'OtherFeature') == 1 
    IsAlgorithmSimilarityBased = 'YES'; % 'YES' for correlation based, 'NO' for difference based
else
    IsAlgorithmSimilarityBased = 'NO'; % 'YES' for correlation based, 'NO' for difference based
end

end

 