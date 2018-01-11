function [ outputSamples ] = ChooseTemplateSamples( SpikesOffset, NumberOfWantedSamples)

if(mod(NumberOfWantedSamples,2) == 0)
    fprintf('Warning: Pick an odd number for the number of samples! As a result you have been given 61 samples.\n');
    outputSamples = (1:61);
    return;
end

if(NumberOfWantedSamples > 61)
    fprintf('Warning: You have chosen more than 61 samples! You have been given all 61 samples.\n');
    outputSamples = (1:61);
    return;
end

if SpikesOffset == 0 || SpikesOffset > 61
    fprintf('Warning: Your spike offset is not corrent - You have been given all 61 samples.\n');
    outputSamples = (1:61);
    return;
end

minSamplesNumber = SpikesOffset-(floor(NumberOfWantedSamples/2));
maxSamplesNumber = SpikesOffset+(floor(NumberOfWantedSamples/2));

if minSamplesNumber < 1
    minChannelRest = abs(floor(minSamplesNumber)-1);
    minSamplesNumber = 1;
    if maxSamplesNumber + minChannelRest <= 61
        maxSamplesNumber = maxSamplesNumber + minChannelRest;
    end
end   
    
 if maxSamplesNumber > 61
    maxChannelRest = abs(floor(maxSamplesNumber)-61);
    maxSamplesNumber = 61;
    if minSamplesNumber - maxChannelRest >= 1
        minSamplesNumber = minSamplesNumber - maxChannelRest;
    end
end

outputSamples = (minSamplesNumber:maxSamplesNumber);

end