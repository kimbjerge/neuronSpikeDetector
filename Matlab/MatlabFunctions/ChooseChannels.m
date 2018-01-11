function [ outputChannels ] = ChooseChannels( centerChannel, numberOfChannels)

if(mod(numberOfChannels,2) == 0)
    fprintf('Warning: Pick an odd number for the number of channels! As a result you have been given all channels.\n');
    outputChannels = (1:32);
    return;
end

if(numberOfChannels > 31)
    fprintf('Warning: You have chosen more than 32 channels! As a result you have been given all channels.\n');
    outputChannels = (1:32);
    return;
end

if(centerChannel > 32)
    fprintf('Warning: You have chosen a center channel outside those that exists. As a result you have been given all channels.\n');
    outputChannels = (1:32);
    return;
end

minChannelNumber = centerChannel-(floor(numberOfChannels/2));
maxChannelNumber = centerChannel+(floor(numberOfChannels/2));

if minChannelNumber < 1
    minChannelRest = abs(floor(minChannelNumber)-1);
    minChannelNumber = 1;
    if maxChannelNumber + minChannelRest <= 32
        maxChannelNumber = maxChannelNumber + minChannelRest;
    end
end   
    
 if maxChannelNumber > 32
    maxChannelRest = abs(floor(maxChannelNumber)-32);
    maxChannelNumber = 32;
    if minChannelNumber - maxChannelRest >= 1
        minChannelNumber = minChannelNumber - maxChannelRest;
    end
end

outputChannels = (minChannelNumber:maxChannelNumber);

end