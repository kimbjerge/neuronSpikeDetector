function [ std ] = CalculateSampleSizeStd( TruthTemplateArray )

    for counter = 1 : numel(TruthTemplateArray)
       varArray(counter) = var(TruthTemplateArray{counter});
    end

    varArray(isnan(varArray)) = [];
    varArrayMean = mean(varArray);
    std = sqrt(varArrayMean);

end

