function [ r ] = TemplateLaplacianV2( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime, pathToXCorFunc, channelToInvestigate  )
%TEMPLATEGRADIENT Summary of this function goes here
%   Detailed explanation goes here

addpath(pathToXCorFunc);

if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);


inputSignal = inputSignal(:,channelToInvestigate);

tic
[cc, ~] = normxcorr2_general(templateSignal, inputSignal, numel(templateSignal));
    
%cc = single(cc);

time = toc;
fprintf('NXCOR Process Time: %.2f seconds.\n', time);

sizeCC = size(cc);

startIndex = sizeTemplate(1);
endIndex = sizeCC(1)-sizeTemplate(1);
    
r = cc((startIndex:endIndex),((floor(sizeCC(2)/2))+1));

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

