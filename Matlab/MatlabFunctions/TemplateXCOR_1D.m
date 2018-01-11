function [ r ] = TemplateXCOR_1D( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime )
%TEMPLATEXCORRFUNC Summary of this function goes here
%   Detailed explanation goes here

%% Cross Correlation 1D (XCOR_1D)
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);
lastPercentUpdate = 0;

template_array = reshape(templateSignal,[sizeTemplate(1)*sizeTemplate(2),1]);

for c = 1: (sizeSignal(1)-sizeTemplate(1))
inputToreshape = inputSignal(c:(c+sizeTemplate(1)-1), :);    
InputSamples_Array = reshape(inputToreshape, [sizeTemplate(1)*sizeTemplate(2),1]);
r(c) = xcorr(template_array, InputSamples_Array, 0);

if strcmp( PrintProgress, 'YES') == 1
   if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
        lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
        fprintf('XCOR_1D is %.0f%% done\n', lastPercentUpdate);
    end  
end

end

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Cross Correlation 1D (XCOR_1D)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateXCOR_1D execution time: %.2f seconds.\n', ElapsedTime);
end

end

