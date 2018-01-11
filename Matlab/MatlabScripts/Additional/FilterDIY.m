function [ out ] = FilterDIY( b, a, in )
%FILTERDIY Summary of this function goes here
%   Detailed explanation goes here

% Implements MATLABS filter() function.

    for i=1:length(in)
        tmp = 0;
        j=0;
        out(i) = 0;
        for j=1:length(b)
            if(i - j < 0) 
                continue;
            end
            tmp = tmp + (b(j) * in(( 1 + (i-j ))) );
        end

        for j=2:length(a)
            if(i - j < 0) 
                continue;
            end
            tmp = tmp - (a(j)*out(1+(i-j)));
        end

        out(i) = tmp;
    end
end

