function [ output_args ] = SaveRezFile( PathToFilteredData, nameing, rez )
%SAVEREZFILE Summary of this function goes here
%   Detailed explanation goes here


fullFileName = fullfile(PathToFilteredData, nameing);

if exist(PathToFilteredData) == 0
    mkdir(PathToFilteredData);
end

RezToSave = rez.st3(:, [1 5]);

[fileID meassage] = fopen(fullFileName, 'w');
fwrite(fileID, RezToSave', 'float');
fclose('all');


end

