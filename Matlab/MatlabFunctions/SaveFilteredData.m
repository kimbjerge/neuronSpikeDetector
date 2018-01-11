function [ output_args ] = SaveFilteredData( inputSignal, PathToFilteredData)
%SAVEFILTEREDDATA Summary of this function goes here
%   Detailed explanation goes here

%sizeSignal = size(inputSignal);
%sizeTemplate = size(templateSignal);

H = fspecial('laplacian'); % Original

L1 = imfilter(inputSignal,H,'replicate');
%L2 = imfilter(templateSignal,H,'replicate');


%fileIDString1 = 'template_';
%fileIDString2 = sprintf('%d.bin', I);
%finalString = strcat(fileIDString1, fileIDString2);

%fullFileName = fullfile(folder, finalString);
fullFileName = fullfile(PathToFilteredData, 'filteredData.bin');

if exist(PathToFilteredData) == 0
    mkdir(PathToFilteredData);
end

[fileID meassage] = fopen(fullFileName, 'w');
fwrite(fileID, L1', 'float');
fclose('all');
  
end

