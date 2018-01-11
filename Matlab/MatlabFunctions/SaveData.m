function [ output_args ] = SaveData( inputSignal, PathToFilteredData, nameing)
%SAVEFILTEREDDATA Summary of this function goes here
%   Detailed explanation goes here

fullFileName = fullfile(PathToFilteredData, nameing);

if exist(PathToFilteredData) == 0
    mkdir(PathToFilteredData);
end

[fileID meassage] = fopen(fullFileName, 'w');
fwrite(fileID, inputSignal', 'float');
fclose('all');
  
end

