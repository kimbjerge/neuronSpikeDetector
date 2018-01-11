close all;
clear all;
%%
RecordLength = 0.1; %seconds
RecordSampleRate = 30000; %30kHz
NumberOfChannels = 32;
TotalSamplesInRecord = 77501440;
TotalSamples = RecordLength*RecordSampleRate;

%% - Get channel data
% addpath('C:\Users\Morten Buhl\Desktop\Morten_Anton\masterProject\channels');
% 
% filepathForCSChannel = 'channels\100_';
% 
% InputSamples = zeros(TotalSamples, NumberOfChannels);
% 
% for I = 1: NumberOfChannels
%     filepathForCSChannel1 = sprintf('CH%d.continuous', I);
%     finalString = strcat(filepathForCSChannel, filepathForCSChannel1)
%     [wv2,t2] = load_open_ephys_data(finalString);
%     
%     InputSamples((1:TotalSamples),I) = wv2(1:TotalSamples);
% end
% 
% %% - Write to many files file
% 
% fileIDString1 = 'channelsBinary/channel_';
% 
% for I = 1: NumberOfChannels
%     
%     fileIDString2 = sprintf('CH%d.bin', I);
%     finalString = strcat(fileIDString1, fileIDString2)
%     
%     fileID = fopen(finalString, 'w');
%     fwrite(fileID, InputSamples(:,I), 'double');
%     fclose(fileID);
% end
% 
% 
% %% - Write to one file
% 
% fileIDString1 = 'channelsBinary/channel_all_int32.bin';
% FactorData = 1000;
% 
% samplesToWriteToFile = zeros(TotalSamples*32,1);
% 
% for I = 1: TotalSamples
%     for Y = 1 : NumberOfChannels
%         index = ((I-1)*NumberOfChannels)+Y;
%         samplesToWriteToFile(index) =  InputSamples(I,Y); 
%     end
% end    
%    
% samplesToWriteToFile = int32(samplesToWriteToFile*FactorData);
% 
% fileID = fopen(fileIDString1, 'w');
% fwrite(fileID, samplesToWriteToFile, 'int32');
% fclose('all');


%% - Write templates to file
PrePath = 'C:\Users\Morten Buhl\Dropbox\Master Engineer\Master Thesis\';
DiectoryToEvaluate = strcat(PrePath,'Generated_Emouse_Data\Simulation_10min_30kHz_DefVals');

template1 = readNPY(strcat(DiectoryToEvaluate,'\templates.npy'));
NumberOfTemplates = 64;
TemplateLength = 82;
NumberOfSamplesInTemplate = NumberOfChannels*TemplateLength;
Factor = 1;

fileIDString1 = 'template_';
folder = strcat(DiectoryToEvaluate, '\TemplatesBinary');
for I = 1: NumberOfTemplates
    
    fileIDString2 = sprintf('%d.bin', I);
    finalString = strcat(fileIDString1, fileIDString2);
        
    x = template1(I,:,:);
    B = squeeze(x);
    C = zeros((TemplateLength*NumberOfChannels), 1);
    
    for Y = 1 : TemplateLength
        for X = 1 : NumberOfChannels
            index = ((Y-1)*NumberOfChannels)+X;
            C(index) = B(Y,X);
        end
    end
    
    %B = reshape(B, [NumberOfSamplesInTemplate, 1]);
    C = (C*Factor);
    
    fullFileName = fullfile(folder, finalString);
    
    if exist(folder) == 0
        mkdir(folder);
    end
    
    [fileID meassage] = fopen(fullFileName, 'w');
    fwrite(fileID, C, 'float');
    fclose('all');
end 


% figure
% surf(B)
% xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')

%% - Test reading file

fileID = fopen(finalString);
A = fread(fileID, 'int32');
fclose(fileID);
