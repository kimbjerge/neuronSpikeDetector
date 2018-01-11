function [ r ] = TemplateLaplacian( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime, pathToXCorFunc  )
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
lastPercentUpdate = 0;


H = fspecial('laplacian'); % Original
%H = [2/6, 2/6, 2/6; 4/6, -12*(2/6), 4/6;2/6, 2/6, 2/6;]; 

%H = fspecial('gaussian');
%[Gx,Gy] = gradient(H); 
tic

L1 = imfilter(inputSignal,H,'replicate');
L2 = imfilter(templateSignal,H,'replicate');

time = toc;
fprintf('2D Filtering Time: %.2f seconds.\n', time);
tic
[cc, ~] = normxcorr2_general(L2, L1, numel(templateSignal));
    
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

