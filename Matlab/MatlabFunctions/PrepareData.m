function [ channelData ] = PrepareData( inputFilePath,  ChannelsInDataToUse, rezFile, ...
                                          InputOffset_s, SignalLength_s, SignalGain, fs, PlotRunning, ShowFunctionTime )
%PREPAREDATA Summary of this function goes here
%   Detailed explanation goes here

%% - Setup
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

RecordLength = SignalLength_s; %seconds
SecondsOffset = InputOffset_s;
RecordSampleRate = fs; %30kHz preferably
TotalSamples = RecordLength*RecordSampleRate;
TotalSamplesOffset = SecondsOffset*RecordSampleRate;
NumberOfChannelsReal = 34;


%% - Read data from file
fileID = fopen(inputFilePath);
%Data = fread(fileID, 'int16');
Data = fread(fileID, NumberOfChannelsReal*(SignalLength_s+InputOffset_s)*fs, 'int16');
fclose(fileID);

%% - Get data from file and setup accoring to channel map
NumberOfSamples = TotalSamples;
channelData = zeros(NumberOfSamples, NumberOfChannelsReal);

invChanMap(rezFile.ops.chanMap) = (1:34); 

counter = 1;
SampleIndex = 1;
startIndex = (TotalSamplesOffset*NumberOfChannelsReal)+1;
for I = startIndex: (startIndex-1) + NumberOfSamples*NumberOfChannelsReal  
    modules = mod(I,NumberOfChannelsReal);
    
    if modules == 0
    channelData(SampleIndex, invChanMap(34)) = Data(I); 
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

channelData = channelData(:, ChannelsInDataToUse);

%% - Mulitply signal
if strcmp(SignalGain, 'Squared');
    channelData = channelData .* abs(channelData);
else
    channelData = channelData .* SignalGain;
end

if( strcmp(PlotRunning, 'YES') == 1)
    sizeChannelData = size(ChannelsInDataToUse);
    
    figure
    if(sizeChannelData(2) > 1)
        surf(channelData);
        xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    else
       plot( channelData );
       xlabel('Amplitude'),xlabel('sampling points')
    end
    title('Unfiltered Raw Data')
end

end