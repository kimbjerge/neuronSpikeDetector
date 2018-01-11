function [ SampleSize ] = CalculateSampleSize( confidenceLevel, errorMargin, stdDev )
%CALCULATESAMPLESIZE Summary of this function goes here
%   Detailed explanation goes here
% Returns the number of ground truth samples needed to acquire the
% specified confidence level with the specified error margin

if strcmp(confidenceLevel, '90%') == 1
   zScore = 1.645;
elseif strcmp(confidenceLevel, '95%') == 1
   zScore = 1.96;
elseif strcmp(confidenceLevel, '99%') == 1
   zScore = 2.576;
else
   zScore = 1.96;
   fprintf('Warning: You didnt specify 90, 95 or 99 confidence interval and as a result you are given 95.\n');
end

SampleSize = zScore^2 * stdDev * (1 - stdDev) / errorMargin^2;

SampleSize = ceil(SampleSize);

end

