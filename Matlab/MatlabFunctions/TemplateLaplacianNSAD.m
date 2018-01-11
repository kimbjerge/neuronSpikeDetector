function [ r ] = TemplateLaplacianNSAD( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime, pathToXCorFunc  )
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


L1 = imfilter(inputSignal,H,'replicate');
L2 = imfilter(templateSignal,H,'replicate');
    
%[cc, ~] = normxcorr2_general(L2, L1, numel(templateSignal));

r = TemplateNSAD( L1, L2, PlotRunning, PrintProgress, ShowFunctionTime );



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

