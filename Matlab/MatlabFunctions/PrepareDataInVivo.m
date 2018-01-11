function [ FiltSamples ] = PrepareDataInVivo( inputFilePath,  ChannelsInDataToUse, rezFile, ...
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


%% - Read data from file
fileID = fopen(inputFilePath);
Data = fread(fileID, [numel(ChannelsInDataToUse), TotalSamples+TotalSamplesOffset], 'int16');
fclose(fileID);

%% - Get data from file and setup accoring to channel map
% NumberOfSamples = TotalSamples;
% NumberOfChannelsReal = numel(rezFile.ops.chanMap);
% channelData = zeros(NumberOfSamples, NumberOfChannelsReal);


Data = Data(rezFile.ops.chanMap(rezFile.connected),:);

% invChanMap(rezFile.ops.chanMap) = (1:NumberOfChannelsReal); 
% 
% counter = 1;
% SampleIndex = 1;
% startIndex = (TotalSamplesOffset*NumberOfChannelsReal)+1;
% for I = startIndex: (startIndex-1) + NumberOfSamples*NumberOfChannelsReal  
%     modules = mod(I,NumberOfChannelsReal);
%     
%     if modules == 0
%         channelData(SampleIndex, invChanMap(NumberOfChannelsReal)) = Data(I); 
%     else
%         channelData(SampleIndex, invChanMap(modules)) = Data(I);
%     end
%     
%     
%     if counter >= NumberOfChannelsReal
%         counter = 0;
%         SampleIndex = SampleIndex + 1;
%     end 
%     counter = counter + 1;
% end


%channelData = channelData(:, 3:34);



if TotalSamplesOffset > 0
    channelData = Data(:, ((TotalSamplesOffset+1) : TotalSamples+TotalSamplesOffset));
else
    channelData = Data;
end

channelData = channelData';


%% - Mulitply signal
if strcmp(SignalGain, 'Squared');
    channelData = channelData .* abs(channelData);
else
    if SignalGain ~= 1
        channelData = channelData .* SignalGain;
    end
end

if( strcmp(PlotRunning, 'YES') == 1)
    sizeChannelData = size(ChannelsInDataToUse);
    
    figure
    if(sizeChannelData(1) > 1)
        surf(channelData);
    else
       plot( channelData );
    end
    title('Unfiltered Raw Data')
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
end

FiltSamples = channelData;

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('PrepareData execution time: %.2f seconds.\n', ElapsedTime);
end

end

