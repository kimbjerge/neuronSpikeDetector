function [ templates_present, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignalMerged( rez, maximumTemplates, mergedData, ...
                                                                signalLength_s, signalOffset, fs)
%EXTRACTTEMPLATEPRESENTINSIGNAL Summary of this function goes here
%   Detailed explanation goes here
    templates_present = logical(zeros(maximumTemplates,1));

    numberOfTemplatesPresent = 0;
    
    for I = 1 : maximumTemplates
        
        if strcmp(mergedData, 'YES')
            truth_ind = find( (rez.st3(:,5) == I) & ...
                              (rez.st3(:,1) >= (signalOffset*fs)) & ...
                              (rez.st3(:,1) <= (signalOffset+signalLength_s)*fs) );
        else
            truth_ind = find( (rez.st3(:,2) == I) & ...
                              (rez.st3(:,1) >= (signalOffset*fs)) & ...
                              (rez.st3(:,1) <= (signalOffset+signalLength_s)*fs) );
        end
        
        if numel(truth_ind) > 0
           templates_present(I) = 1; 
           numberOfTemplatesPresent = numberOfTemplatesPresent + 1;
        end
    end

end


