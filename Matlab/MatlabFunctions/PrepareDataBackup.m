function [ FiltSamples ] = PrepareData( inputFilePath,  ChannelsInDataToUse, rezFile, ...
                                          InputOffset_s, SignalLength_s, SignalGain, FilterSignal, FilterType, fs, PlotRunning, ShowFunctionTime )
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
Data = fread(fileID, 'int16');
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


channelData = channelData(:, 3:34);

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
    if(sizeChannelData(1) > 1)
        surf(channelData);
    else
       plot( channelData );
    end
    title('Unfiltered Raw Data')
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
end

%% - Filter
numberOfChannelsToGetDataFrom = size(ChannelsInDataToUse);
FiltSamples = zeros(TotalSamples, numberOfChannelsToGetDataFrom(2));

passbandRipple = 0.5; % dB
stopbandAttenuation = 40; % dB

if strcmp(FilterSignal, 'YES') == 1
    Fs = RecordSampleRate;
    fpass = [300 9000];
    
    if( strcmp(FilterType, 'Kilosort') == 1)
        order = 3;
    elseif( strcmp(FilterType, 'Butter') == 1)
        order = 9;
    elseif( strcmp(FilterType, 'Cheby1') == 1)
        order = 9;
    elseif( strcmp(FilterType, 'Cheby2') == 1)
        order = 9;
    elseif( strcmp(FilterType, 'Ellip') == 1)
        order = 9;
    elseif( strcmp(FilterType, 'Fir') == 1)
        order = 160;
    end

    [b,a] = GenerateChannelFilter( FilterType, order, fpass, Fs, passbandRipple, stopbandAttenuation, PlotRunning );

    %a1 = [ -3.09480182556695, 3.35590466129395, -1.86857682025173, 1.34381136102870, -0.943260898767952, 0.145954174911043, 0.0355321080101539, 0.0254783428151354 ];
	%b1 = [ 0.150087125072278, -0.600348500289113, 0.900522750433669, -0.600348500289113, 0.150087125072278 ];

    
    tic
    for Y = 1: numberOfChannelsToGetDataFrom(2)
     %FiltSamples(:,Y) = filtfilt(b,a,channelData((1:TotalSamples), Y)); 
     %FiltSamples1(1:65553,Y) = FilterDIY(b, a, channelData((1:65553), Y));
     %FiltSamples3(1:65553,Y) = FilterDIY(b, a, FiltSamples2(1:65553,Y));
     
     FiltSamples1(1:TotalSamples,Y) = filter(b, a, channelData((1:TotalSamples), Y));
     FiltSamples2(1:TotalSamples,Y) = flipud(FiltSamples1(1:TotalSamples,Y));
     FiltSamples3(1:TotalSamples,Y) = filter(b, a, FiltSamples2(1:TotalSamples,Y));
     FiltSamples(1:TotalSamples,Y)  = flipud(FiltSamples3(1:TotalSamples,Y));
     
    end
    time = toc;
    fprintf('1D filtering time: %.2f seconds.\n', time);
    
    if( strcmp(PlotRunning, 'YES') == 1)
        sizeChannelData = size(ChannelsInDataToUse);
    
        figure
        if(sizeChannelData(1) > 1)
            surf(FiltSamples);
        else
           plot( FiltSamples );
        end
        title('Filtered Data')
        xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    end
else
    FiltSamples = channelData;  
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('PrepareData execution time: %.2f seconds.\n', ElapsedTime);
end

end
