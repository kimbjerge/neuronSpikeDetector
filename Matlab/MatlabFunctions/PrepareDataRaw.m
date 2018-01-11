function [ channelData ] = PrepareDataRaw( inputFilePath,  ChannelsInDataToUse, rezFile, ...
                                          InputOffset_s, SignalLength_s,  fs )
%PREPAREDATA Summary of this function goes here
%   Detailed explanation goes here

%% - Setup

RecordLength = SignalLength_s; %seconds
SecondsOffset = InputOffset_s;
RecordSampleRate = fs; %30kHz preferably
TotalSamples = RecordLength*RecordSampleRate;
TotalSamplesOffset = SecondsOffset*RecordSampleRate;


%% - Read data from file
fileID = fopen(inputFilePath);
Data = fread(fileID, [TotalSamples+TotalSamplesOffset, numel(ChannelsInDataToUse)], 'int16');
fclose(fileID);

%% - Get data from file and setup accoring to channel map
NumberOfSamples = TotalSamples;
NumberOfChannelsReal = numel(rezFile.ops.chanMap);
channelData = zeros(NumberOfSamples, NumberOfChannelsReal);


invChanMap(rezFile.ops.chanMap) = (1:NumberOfChannelsReal); 

counter = 1;
SampleIndex = 1;
startIndex = (TotalSamplesOffset*NumberOfChannelsReal)+1;
for I = startIndex: (startIndex-1) + NumberOfSamples*NumberOfChannelsReal  
    modules = mod(I,NumberOfChannelsReal);
    
    if modules == 0
        channelData(SampleIndex, invChanMap(NumberOfChannelsReal)) = Data(I); 
    else
        channelData(SampleIndex, invChanMap(modules)) = Data(I);
    end
    
    
    if counter >= NumberOfChannelsReal
        counter = 0;
        SampleIndex = SampleIndex + 1;
    end 
    counter = counter + 1;
end


%channelData = channelData(:, 3:34);

if TotalSamplesOffset > 0
    channelData = Data((TotalSamplesOffset : TotalSamples+TotalSamplesOffset), :);
else
    channelData = Data;
end






