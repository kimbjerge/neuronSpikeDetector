
function [ mainChannel, peakOffset, peakdepth ] = GetTemplateInfo( template )
%GETTEMPLATEINFO Summary of this function goes here
%   Detailed explanation goes here

[RowarrayMax, RowarrayMaxInd] = min(template);

[~, ColarrayMaxInd] = min(RowarrayMax);

peakOffset = RowarrayMaxInd(ColarrayMaxInd);
mainChannel = ColarrayMaxInd;

peakdepth = template(peakOffset,mainChannel); 

peakOffset = peakOffset - 1;

end

