function [ r ] = TemplateSSD( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime )
%TEMPLATESSD Summary of this function goes here
%   Detailed explanation goes here

%% Sum of Squared Differences (SSD)
if( strcmp(ShowFunctionTime, 'YES') == 1)
    tic
end

sizeSignal = size(inputSignal);
sizeTemplate = size(templateSignal);
lastPercentUpdate = 0;

r_size = (sizeSignal(1)-sizeTemplate(1));
r = zeros(r_size,1);

template_array = reshape(templateSignal,[sizeTemplate(1)*sizeTemplate(2),1]);

for c = 1: (sizeSignal(1)-sizeTemplate(1))
	inputToreshape = inputSignal(c:(c+sizeTemplate(1)-1), :);    
	InputSamples_Array = reshape(inputToreshape, [sizeTemplate(1)*sizeTemplate(2),1]);

    diff = template_array - InputSamples_Array;
    SSD = sum(diff(:).^2);

	if strcmp( PrintProgress, 'YES') == 1
        if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
            lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
            fprintf('SSD is %.0f%% done\n', lastPercentUpdate);
        end  
	end
	
    r(c) = SSD;
end

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Sum of Squared Differences (SSD)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateSSD execution time: %.2f seconds.\n', ElapsedTime);
end

end