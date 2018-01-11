function [ templates_present, numberOfTemplatesPresent ] = ExtractTemplatePresentInSignal( rez, maximumTemplates )
%EXTRACTTEMPLATEPRESENTINSIGNAL Summary of this function goes here
%   Detailed explanation goes here
    templates_present = logical(zeros(maximumTemplates,1));

    numberOfTemplatesPresent = 0;
    
    for I = 1 : maximumTemplates
        truth_ind = find((rez.st3(:,2) == I));
        if numel(truth_ind) > 0
           templates_present(I) = 1; 
           numberOfTemplatesPresent = numberOfTemplatesPresent + 1;
        end
    end

end

