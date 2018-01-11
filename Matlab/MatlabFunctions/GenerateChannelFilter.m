function [ b, a ] = GenerateChannelFilter( filterType, order, fpass, fs, passbandRipple, stopbandAttenuation, PlotRunning )
%PREPROCESSFILTER Summary of this function goes here
%   Detailed explanation goes here
    if strcmp(filterType, 'Kilosort') == 1
        % Butterworth https://se.mathworks.com/help/signal/ref/butter.html
        [b, a] = butter(order,fpass / (fs / 2), 'bandpass');
        
    elseif strcmp(filterType, 'Butter') == 1
        % Butterworth https://se.mathworks.com/help/signal/ref/butter.html
        [b, a] = butter(order,fpass / (fs / 2), 'bandpass');
        
    elseif strcmp(filterType, 'Cheby1') == 1
        % Chebyshev type I https://se.mathworks.com/help/signal/ref/cheby1.html
        [b, a] = cheby1(order, passbandRipple, fpass / (fs / 2), 'bandpass');
        
    elseif strcmp(filterType, 'Cheby2') == 1
        % Chebyshev type II https://se.mathworks.com/help/signal/ref/cheby2.html
        [b, a] = cheby2(order, stopbandAttenuation, fpass / (fs / 2), 'bandpass');
        
    elseif strcmp(filterType, 'Ellip') == 1
        % Elliptic filter https://se.mathworks.com/help/signal/ref/ellip.html
        [b, a] = ellip(order, passbandRipple, stopbandAttenuation, fpass / (fs / 2), 'bandpass');
        
    elseif strcmp(filterType, 'Fir') == 1
        % FIR Window based https://se.mathworks.com/help/signal/ref/fir1.html
        b = fir1(order, fpass.* 2 / fs, 'bandpass');
        a = 1;
    else
        fprintf('ERROR: You didnt choose an eligible filter, and thus no preprocessing filtering are performed.\n');
        return;
        
    end 
    
    if strcmp(PlotRunning, 'YES') == 1
        figure;
        freqz(b,a);
        title(filterType);
    end
end

