function [ r ] = TemplateXCOR_2D( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime )
%TEMPLATEXCORRFUNC Summary of this function goes here
%   Detailed explanation goes here

%% Cross Correlation 2D (XCOR_2D)
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

%cc = xcorr2(templateSignal, inputToHandle); %slow

CC = sum(sum(inputToHandle.*templateSignal));

r(c) = CC;

if strcmp( PrintProgress, 'YES') == 1
   if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
        lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
        fprintf('XCOR_2D is %.0f%% done\n', lastPercentUpdate);
    end  
end

end

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Cross Correlation 2D (XCOR_2D)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateXCOR_2D execution time: %.2f seconds.\n', ElapsedTime);
end

end



