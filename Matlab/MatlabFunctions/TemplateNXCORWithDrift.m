function [ r_result ] = TemplateNXCORWithDrift( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime, pathToXCorFunc, HandleDriftChannel, ChannelsToInvestigate  )
%TEMPLATEGRADIENT Summary of this function goes here
%   Detailed explanation goes here

addpath(pathToXCorFunc);

if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));


driftIteration = HandleDriftChannel*2 + 1;

r = zeros(r_size,driftIteration);
ChannelsToInvestigateOld = ChannelsToInvestigate;
for drift = 0: driftIteration - 1
    dataOffset = drift - HandleDriftChannel;
    ChannelsToInvestigateData = ChannelsToInvestigateOld + dataOffset;
    ChannelsToInvestigateTemp = 1:sizeTemplate(2);%ChannelsToInvestigateOld; % + dataOffset;
    %tempMin = min(ChannelsToInvestigate);
    tempMac = max(ChannelsToInvestigateTemp);
    

    while (numel(find(ChannelsToInvestigateData < 1)) > 0)
        indexToRemove = find(ChannelsToInvestigateData < 1);
        ChannelsToInvestigateData(indexToRemove(1)) = [];
        ChannelsToInvestigateTemp(1) = [];
    end
    
    while numel(find(ChannelsToInvestigateData > sizeSignal(2))) > 0
        indexToRemove = find(ChannelsToInvestigateData > sizeSignal(2));
        ChannelsToInvestigateData(indexToRemove(1)) = [];
        ChannelsToInvestigateTemp(numel(ChannelsToInvestigateTemp)) = [];
    end
    
%     ChannelsToInvestigateTemp(find(ChannelsToInvestigateTemp < 1)) = [];
%     ChannelsToInvestigateTemp(find(ChannelsToInvestigateTemp > tempMac)) = [];
% 
%     while(ChannelsToInvestigateTemp(numel(ChannelsToInvestigateTemp)) > sizeTemplate(2))
%         ChannelsToInvestigateTemp = ChannelsToInvestigateTemp - 1;
%     end
%     
    L1New = inputSignal(:,ChannelsToInvestigateData);
    L2New = templateSignal(:,ChannelsToInvestigateTemp);

    [cc, ~] = normxcorr2_general(L2New, L1New, numel(L2New));
    sizeCC = size(cc);
    startIndex = sizeTemplate(1);
    endIndex = sizeCC(1)-sizeTemplate(1);
    r(:,drift+1) = cc((startIndex:endIndex),((floor(sizeCC(2)/2))+1));

end

%cc = single(cc);

time = toc;
fprintf('NXCOR Process Time: %.2f seconds.\n', time);
    
r_result = r;
%r_result = max(r, [], 2);

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Normalized Cross Correlation 2D General (NXCOR_2D_General)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateNXCOR_2D_General execution time: %.2f seconds.\n', ElapsedTime);
end





end

