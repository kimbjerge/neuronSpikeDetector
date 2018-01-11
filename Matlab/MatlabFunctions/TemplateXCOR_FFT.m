function [ r ] = TemplateXCOR_FFT( inputSignal, templateSignal, PlotRunning, PrintProgress, pathToFFTFunc, ShowFunctionTime )
%TEMPLATEXCORRFUNC Summary of this function goes here
%   Detailed explanation goes here

%% Cross Correlation FFT (XCOR_FFT)
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

addpath(pathToFFTFunc);

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);
lastPercentUpdate = 0;

for c = 1: (sizeSignal(1)-sizeTemplate(1))
    inputToHandle = inputSignal(c:(c+sizeTemplate(1)-1), :);     
    
    cc = xcorr_fft(templateSignal, inputToHandle);
    r(c) = cc(((floor(sizeTemplate(1)/2))+1),((floor(sizeTemplate(2)/2))+1));
  

    if strcmp( PrintProgress, 'YES') == 1
       if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
            lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
            fprintf('XCOR_FFT is %.0f%% done\n', lastPercentUpdate);
        end  
    end

end

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Cross Correlation FFT (XCOR_FFT)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateXCOR_FFT execution time: %.2f seconds.\n', ElapsedTime);
end

end