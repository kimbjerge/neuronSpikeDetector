function [ r ] = TemplateNXCOR_2D_GPU( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime )
%TEMPLATEXCORRFUNC Summary of this function goes here
%   Detailed explanation goes here

%% Normalized Cross Correlation 2D GPU (XCOR_2D_GPU)
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);
lastPercentUpdate = 0;

for c = 1: (sizeSignal(1)-sizeTemplate(1))
inputToHandle = inputSignal(c:(c+sizeTemplate(1)-1), :);    

cc = normxcorr2(gpuArray(templateSignal), gpuArray(inputToHandle)); %slow

%CC = sum(sum(inputToHandle.*templateSignal));
cc = gather(cc);

sizeCC = size(cc);

r(c) = cc(((floor(sizeCC(1)/2))+1),((floor(sizeCC(2)/2))+1));

if strcmp( PrintProgress, 'YES') == 1
   if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
        lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
        fprintf('NXCOR_2D_GPU is %.0f%% done\n', lastPercentUpdate);
    end  
end

end

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Normalized Cross Correlation 2D GPU (NXCOR_2D_GPU)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateNXCOR_2D_GPU execution time: %.2f seconds.\n', ElapsedTime);
end

end



