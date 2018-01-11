function [ r ] = TemplateLSSD( inputSignal, templateSignal, PlotRunning, PrintProgress, ShowFunctionTime )
%TEMPLATELSAD Summary of this function goes here
%   Detailed explanation goes here

%% Locally Scaled Sum of Squared Differences (LSSD)
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
    
    diff = InputSamples_Array - ((mean(InputSamples_Array)/mean(template_array))*template_array);
    LSSD = sum(diff(:).^2);

	if strcmp( PrintProgress, 'YES') == 1
        if (int16((c/(r_size-sizeTemplate(1)))*100)) > lastPercentUpdate + 1
			lastPercentUpdate = (int16((c/(r_size-sizeTemplate(1)))*100));
			fprintf('LSSD is %.0f%% done\n', lastPercentUpdate);
		end  
	end
	
    r(c) = LSSD;
end

if( strcmp(PlotRunning, 'YES') == 1)
    figure;
    plot(r)
    title('Locally Scaled Sum of Squared Differences (LSSD)');
end

if( strcmp(ShowFunctionTime, 'YES') == 1)
    ElapsedTime = toc;
    fprintf('TemplateLSSD execution time: %.2f seconds.\n', ElapsedTime);
end

end