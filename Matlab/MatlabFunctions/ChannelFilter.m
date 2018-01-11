function [ FiltSamples ] = ChannelFilter( channelData, ChannelsInDataToUse, FilterType, RecordLength, Fs, PlotRunning )
%CHANNELFILTER Summary of this function goes here
%   Detailed explanation goes here

TotalSamples = RecordLength*Fs;

numberOfChannelsToGetDataFrom = size(ChannelsInDataToUse);
FiltSamples = zeros(TotalSamples, numberOfChannelsToGetDataFrom(2));

passbandRipple = 0.5;     % dB
stopbandAttenuation = 40; % dB

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

tic
for Y = 1: numberOfChannelsToGetDataFrom(2)
    FiltSamples(:,Y) = filter(b, a, channelData(:,Y));
    FiltSamples(:,Y) = flipud(FiltSamples(:,Y));
    FiltSamples(:,Y) = filter(b, a, FiltSamples(:,Y));
    FiltSamples(:,Y) = flipud(FiltSamples(:,Y));
end
time = toc;
%fprintf('1D filtering time: %.2f seconds.\n', time);

if( strcmp(PlotRunning, 'YES') == 1)
    sizeChannelData = size(ChannelsInDataToUse);

    figure
    if(sizeChannelData(1) > 1)
        surf(FiltSamples);
    else
        plot(FiltSamples);
    end
    title('Filtered Data')
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
end

end