function CalculateStatisticalSampleSize( TruthTemplateArray, PlotRunning )
%CalculateStatisticalSampleSize Summary of this function goes here
%   Detailed explanation goes here
    std = CalculateSampleSizeStd(TruthTemplateArray);
    
    errorMarginToTest = 0.005:0.0001:0.02;

    for counter = 1 : numel(errorMarginToTest)
        SampleSizeToTest90(counter) = CalculateSampleSize('90%',errorMarginToTest(counter),std);
        SampleSizeToTest95(counter) = CalculateSampleSize('95%',errorMarginToTest(counter),std);
        SampleSizeToTest99(counter) = CalculateSampleSize('99%',errorMarginToTest(counter),std);
    end

    if( strcmp(PlotRunning, 'YES') == 1)
        figure;
        plot(errorMarginToTest,SampleSizeToTest99);
        hold on;
        plot(errorMarginToTest,SampleSizeToTest95);
        plot(errorMarginToTest,SampleSizeToTest90);
        title([ 'Sample size as a function of error margin and confidence level' ]);
        legend('99% Confidence Level','95% Confidence Level','90% Confidence Level');
        xlabel('Error margin');
        ylabel('Sample size (Ground truth)');  
        set(gca, 'YTickLabel', get(gca, 'YTick'));
    end
end

