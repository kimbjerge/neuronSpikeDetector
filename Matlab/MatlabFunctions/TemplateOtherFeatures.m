function [ r ] = TemplateOtherFeatures( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime, spikeOffset, Mainchannel )
%TEMPLATENXCOR_GENERAL Summary of this function goes here
%   Detailed explanation goes here

%% Normalized Cross Correlation 2D General (XCOR_2D_General)
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);
lastPercentUpdate = 0;



mainChannel = ceil((sizeTemplate(2)/2));

if(Mainchannel < ceil((sizeTemplate(2)/2)))
   mainChannel = Mainchannel;
elseif (Mainchannel > (32 - ceil((sizeTemplate(2)/2))))
   mainChannel = mainChannel + (Mainchannel - (32 - ceil((sizeTemplate(2)/2))));     
end

if sizeTemplate(1) > (spikeOffset*2)+1
    offsetSpike = templateSpikeOffset;
else
    offsetSpike = ceil(sizeTemplate(1)/2);
end

for c = 1: (sizeSignal(1)-sizeTemplate(1))
inputToHandle = inputSignal(c:(c+sizeTemplate(1)-1), :);    

ImageMean = mean(mean(inputToHandle));

peakdepth = inputToHandle(offsetSpike+1,mainChannel); 
peakdepthDeviation = peakdepth - ImageMean;

try 
    peakNeighbor1 = inputToHandle(offsetSpike+1,mainChannel+1) - ImageMean;
catch
    peakNeighbor1 = ImageMean;
end

try 
    peakNeighbor2 = inputToHandle(offsetSpike+1,mainChannel-1) - ImageMean;
catch
    peakNeighbor2 = ImageMean;
end

featureValue = abs(peakdepthDeviation)+peakNeighbor1+peakNeighbor2;

windowMinValue = featureValue;

%CC = sum(sum(inputToHandle.*templateSignal));

r(c) = windowMinValue;


if strcmp( PrintProgress, 'YES') == 1
   if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
        lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
        fprintf('NXCOR_2D is %.0f%% done\n', lastPercentUpdate);
    end  
end

end

r = normc(r);



if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Normalized Cross Correlation 2D (NXCOR_2D)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateNXCOR_2D execution time: %.2f seconds.\n', ElapsedTime);
end

end

