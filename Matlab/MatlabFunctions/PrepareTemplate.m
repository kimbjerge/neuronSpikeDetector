function [ template ] = PrepareTemplate( TemplateFilePath, TemplateToTest, ChannelsInTemplateToUse, ...
                                           TemplateGain, NPYPath, PlotRunning, ShowFunctionTime )
%PREPARETEMPLATE Summary of this function goes here
%   Detailed explanation goes here
%% - Setup
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end
%RecordLength = SignalLength_s; %seconds
%SecondsOffset = InputOffset_s;
%RecordSampleRate = fs; %30kHz
%NumberOfChannels = 32;
NumberOfSamplesInTemplate = 82;
TemplateSampleStart = 22;
%NumberOfSamplesInTemaplateUsed = NumberOfSamplesInTemplate - TemplateSampleStart + 1;
%TotalSamples = RecordLength*RecordSampleRate;
%TotalSamplesOffset = SecondsOffset*RecordSampleRate;
ChannelsToRunTemplateMatchingAgainst = ChannelsInTemplateToUse;


%% - Get Template data
addpath(NPYPath);    
template1 = readNPY(TemplateFilePath);

x = template1(TemplateToTest,:,:);
template = squeeze(x);
template = double(template);
template = template((TemplateSampleStart:NumberOfSamplesInTemplate),ChannelsToRunTemplateMatchingAgainst);


%% - Mulitply Template
if strcmp(TemplateGain, 'Squared');
    template = template.^2;
else
    template = template .* TemplateGain;
end


if( strcmp(PlotRunning, 'YES') == 1)
    figure
    surf(template)
    title(['Template: ' num2str(TemplateToTest)])
    xlabel('Channel [#]'),ylabel('sampling points'), zlabel('Amplitude')
    
    
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('PrepareTemplate execution time: %.2f seconds.\n', ElapsedTime);
end

end

