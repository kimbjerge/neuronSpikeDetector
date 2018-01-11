function [ r ] = TemplateNXCOR_2D_General( inputSignal, templateSignal, PlotRunning, PrintProgress, pathToXCorFunc, ShowFunctionTime )
%TEMPLATENXCOR_GENERAL Summary of this function goes here
%   Detailed explanation goes here

%% Normalized Cross Correlation 2D General (XCOR_2D_General)
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

addpath(pathToXCorFunc);

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);
lastPercentUpdate = 0;
     
    
[cc, ~] = normxcorr2_general(templateSignal, inputSignal, numel(templateSignal));
    
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

