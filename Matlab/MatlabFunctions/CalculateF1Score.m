function [ F1_Array ] = CalculateF1Score( PrecsionArray, recallArray )
%CALCULATEF1SCORE Summary of this function goes here
%   Detailed explanation goes here

    F1_Array = (0.7+0.3)./((0.7./PrecsionArray)+(0.3./recallArray));

end