close all;
clear all;

fs = 30000; % Hz

% Filter settings
kilosortOrder = 3;
butterOrder = 9;
cheby1Order = 9;
cheby2Order = 9;
ellipOrder = 9;
firfilterorder = 160;

F1 = 300; % Hz
F2 = 8000; % Hz
fpass = [F1 F2];

passbandRipple = 0.5; % dB
stopbandAttenuation = 40; % dB

% Test data
t = 1:10000;
N = 1000;

Fc = 500;
s = sin(2*pi*Fc/fs*t); % Creating output signal 

nt = 0.5; %sec endtime
st = 0:1/fs:nt; %starttime / setup time array
sf = 10; %Hz startfreqz
nf = 20000; %Hz endfreqz

schirp = chirp(st,sf,nt,nf); % generate chirp

% Other
Impulse = zeros(1,N);
Impulse(1) = 1;

%% Kilosort reference filter
[b_kilosort,a_kilosort] = butter(kilosortOrder,fpass*2/fs, 'bandpass');

[h_kilosort, w_kilosort] = freqz(b_kilosort,a_kilosort);

%% Digital IIR filters
[b_butter,a_butter] = butter(butterOrder,fpass / (fs / 2), 'bandpass');
[b_cheby1, a_cheby1] = cheby1(cheby1Order, passbandRipple, fpass / (fs / 2), 'bandpass');
[b_cheby2, a_cheby2] = cheby2(cheby2Order, stopbandAttenuation, fpass / (fs / 2), 'bandpass');
[b_ellip, a_ellip] = ellip(ellipOrder, passbandRipple, stopbandAttenuation, fpass / (fs / 2), 'bandpass');

[h_butter, w_butter] = freqz(b_butter,a_butter);
[h_cheby1, w_cheby1] = freqz(b_cheby1,a_cheby1);
[h_cheby2, w_cheby2] = freqz(b_cheby2,a_cheby2);
[h_ellip, w_ellip] = freqz(b_ellip,a_ellip);

%% Digital FIR filters

b_firfilter = fir1(firfilterorder, fpass.* 2 / fs, 'bandpass');

[h_firfilter, w_firfilter] = freqz(b_firfilter,1);

%% Application of filters
% Impulse responses
y_kilosort_imp = filtfilt(b_kilosort,a_kilosort,Impulse);
y_butter_imp = filtfilt(b_butter,a_butter,Impulse);
y_cheby1_imp = filtfilt(b_cheby1,a_cheby1,Impulse);
y_cheby2_imp = filtfilt(b_cheby2,a_cheby2,Impulse);
y_ellip_imp = filtfilt(b_ellip,a_ellip,Impulse);
y_firfilter_imp = filtfilt(b_firfilter,1,Impulse);

% Chirp responses
y_kilosort_chirp = filtfilt(b_kilosort,a_kilosort,schirp);
y_butter_chirp = filtfilt(b_butter,a_butter,schirp);
y_cheby1_chirp = filtfilt(b_cheby1,a_cheby1,schirp);
y_cheby2_chirp = filtfilt(b_cheby2,a_cheby2,schirp);
y_ellip_chirp = filtfilt(b_ellip,a_ellip,schirp);
y_firfilter_chirp = filter(b_firfilter, 1, schirp); 


%% Test, Butterworth

orderCounter = 1;

figure('pos',[500 500 900 400]);
for counter = 1:6
    [b_test,a_test] = butter(orderCounter,fpass*2/fs, 'bandpass');
    [h_test, w_test] = freqz(b_test,a_test);

    plot(w_test*fs/(2*pi),20*log10(abs(h_test)));
    hold on;
    legendText{counter} = strcat(num2str(orderCounter), '. order');

    orderCounter = orderCounter + 2;
end

xlim([0 F2*2]);
ylim([-120 20]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Butterworth filters' ]);
[lgd,hObj] = legend(legendText);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');


%% Test, Chebyshev Type I
orderCounter = 1;

figure('pos',[500 500 900 400]);
for counter = 1:5
    [b_test,a_test] = cheby1(orderCounter, passbandRipple, fpass / (fs / 2), 'bandpass');
    [h_test, w_test] = freqz(b_test,a_test);
    
    plot(w_test*fs/(2*pi),20*log10(abs(h_test)));
    hold on;
    legendText{counter} = strcat(num2str(orderCounter), '. order');

    orderCounter = orderCounter + 2;
end

xlim([0 F2*2]);
ylim([-1 0.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Chebyshev Type I filters' ]);
legend(legendText);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');


%% Test, Chebyshev Type II
orderCounter = 1;

figure('pos',[500 500 900 400]);
for counter = 1:6
    [b_test,a_test] = cheby2(orderCounter, stopbandAttenuation, fpass / (fs / 2), 'bandpass');
    [h_test, w_test] = freqz(b_test,a_test);
    
    plot(w_test*fs/(2*pi),20*log10(abs(h_test)));
    hold on;
    legendText{counter} = strcat(num2str(orderCounter), '. order');

    orderCounter = orderCounter + 2;
end

xlim([0 F2*2]);
ylim([-120 20]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Chebyshev Type II filters' ]);
[lgd,hObj] = legend(legendText);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

%% Test, Elliptic
orderCounter = 1;

figure('pos',[500 500 900 400]);
for counter = 1:6
    [b_test,a_test] = ellip(orderCounter, passbandRipple, stopbandAttenuation, fpass / (fs / 2), 'bandpass');
    [h_test, w_test] = freqz(b_test,a_test);
    
    plot(w_test*fs/(2*pi),20*log10(abs(h_test)));
    hold on;
    legendText{counter} = strcat(num2str(orderCounter), '. order');

    orderCounter = orderCounter + 2;
end

xlim([0 F2*2]);
ylim([-120 20]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Elliptic filters' ]);
[lgd,hObj] = legend(legendText);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

%% Test, Fir Filter
orderCounter = 1;

figure('pos',[500 500 900 400]);
for counter = 1:7
    b_test = fir1(orderCounter, fpass.* 2 / fs, 'bandpass');
    [h_test, w_test] = freqz(b_test,1);
    
    plot(w_test*fs/(2*pi),20*log10(abs(h_test)));
    hold on;
    legendText{counter} = strcat(num2str(orderCounter), '. order');

    if orderCounter == 1
        orderCounter = orderCounter + 9;
    else
        orderCounter = orderCounter + 30;
    end
end

xlim([0 F2*2]);
ylim([-120 20]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'FIR (Window) filters' ]);
[lgd,hObj] = legend(legendText);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

%% Plots, magnitude

figure('pos',[500 500 900 400]);
plot(w_kilosort*fs/(2*pi),20*log10(abs(h_kilosort)));
hold on;
plot(w_butter*fs/(2*pi),20*log10(abs(h_butter)));
plot(w_cheby1*fs/(2*pi),20*log10(abs(h_cheby1)));
plot(w_cheby2*fs/(2*pi),20*log10(abs(h_cheby2)));
plot(w_ellip*fs/(2*pi),20*log10(abs(h_ellip)));
plot(w_firfilter*fs/(2*pi),20*log10(abs(h_firfilter)));
xlim([0 F2*2]);
ylim([-120 20]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Magnitude comparison of digital filters' ]);
[lgd,hObj] = legend([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ],[ 'Butterworth (', num2str(butterOrder), '. order)' ],[ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ],[ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ],[ 'Elliptic (', num2str(ellipOrder), '. order)' ],[ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

%% Plots, frequency

figure('pos',[500 500 900 400]);
plot(w_kilosort*fs/(2*pi), 360/(2*pi)*unwrap(angle(h_kilosort)));
hold on;
plot(w_butter*fs/(2*pi), 360/(2*pi)*unwrap(angle(h_butter)));
plot(w_cheby1*fs/(2*pi), 360/(2*pi)*unwrap(angle(h_cheby1)));
plot(w_cheby2*fs/(2*pi), 360/(2*pi)*unwrap(angle(h_cheby2)));
plot(w_ellip*fs/(2*pi), 360/(2*pi)*unwrap(angle(h_ellip)));
plot(w_firfilter*fs/(2*pi), 360/(2*pi)*unwrap(angle(h_firfilter)));
xlim([0 F2*2]);
ylim([-720 360]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Phase comparison of digital filters' ]);
[lgd,hObj] = legend([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ],[ 'Butterworth (', num2str(butterOrder), '. order)' ],[ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ],[ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ],[ 'Elliptic (', num2str(ellipOrder), '. order)' ],[ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');

%% Plots, Chirp

figure('pos',[500 500 900 400]);
plot(schirp);
hold on;
xlim([0 F2*2]);
ylim([-1.5 1.5]);
grid on;
title('Chirp');
xlabel('Frequency (Hz)');
ylabel('Amplitude');

%% Plots, Impulse response

figure('pos',[500 500 900 400]);
plot(y_kilosort_imp, '.');
hold on;
plot(y_butter_imp, '.');
plot(y_cheby1_imp, '.');
plot(y_cheby2_imp, '.');
plot(y_ellip_imp, '.');
plot(y_firfilter_imp, '.');
xlim([0 300]);
grid on;
title('Impulse response');
[lgd,hObj] = legend([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ],[ 'Butterworth (', num2str(butterOrder), '. order)' ],[ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ],[ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ],[ 'Elliptic (', num2str(ellipOrder), '. order)' ],[ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
xlabel('Samples');
ylabel('Amplitude');

%% Plots, Step response
windowLength = 500;

[stepResp_kilosort,t] = stepz(b_kilosort,a_kilosort,windowLength);
[stepResp_butter,t] = stepz(b_butter,a_butter,windowLength);
[stepResp_cheby1,t] = stepz(b_cheby1,a_cheby1,windowLength);
[stepResp_cheby2,t] = stepz(b_cheby2,a_cheby2,windowLength);
[stepResp_ellip,t] = stepz(b_ellip,a_ellip,windowLength);
[stepResp_firfilter,t] = stepz(b_firfilter,1,windowLength);

figure('pos',[500 500 900 400]);
plot(t,stepResp_kilosort);
hold on;
plot(t,stepResp_butter);
plot(t,stepResp_cheby1);
plot(t,stepResp_cheby2);
plot(t,stepResp_ellip);
plot(t,stepResp_firfilter);
grid on;
title('Step response');
xlabel('N (Samples)');
ylabel('Amplitude');


figure('pos',[500 500 1000 500]);
suptitle('Step response') % Requires Bioinformatics Toolbox
hold on;

subplot(3,2,1);
plot(t,stepResp_kilosort);
hold on;
title([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,2);
plot(t,stepResp_butter);
hold on;
title([ 'Butterworth (', num2str(butterOrder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,3)
plot(t,stepResp_cheby1);
hold on;
title([ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,4)
plot(t,stepResp_cheby2);
hold on;
title([ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,5)
plot(t,stepResp_ellip);
hold on;
title([ 'Elliptic (', num2str(ellipOrder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,6)
plot(t,stepResp_firfilter);
hold on;
title([ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');


%% Plots, Impulse response
windowLength = 100;

[impResp_kilosort,t] = impz(b_kilosort,a_kilosort,windowLength);
[impResp_butter,t] = impz(b_butter,a_butter,windowLength);
[impResp_cheby1,t] = impz(b_cheby1,a_cheby1,windowLength);
[impResp_cheby2,t] = impz(b_cheby2,a_cheby2,windowLength);
[impResp_ellip,t] = impz(b_ellip,a_ellip,windowLength);
[impResp_firfilter,t] = impz(b_firfilter,1,windowLength);

%figure;
%plot(t,impResp_kilosort,'o','MarkerSize',5);

figure('pos',[500 500 900 400]);
plot(t,impResp_kilosort);
hold on;
plot(t,impResp_butter);
plot(t,impResp_cheby1);
plot(t,impResp_cheby2);
plot(t,impResp_ellip);
plot(t,impResp_firfilter);
grid on;
title('Impulse response');
xlabel('N (Samples)');
ylabel('Amplitude');


figure('pos',[500 500 1000 500]);
suptitle('Impulse response')
hold on;

subplot(3,2,1);
plot(t,impResp_kilosort);
hold on;
title([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,2);
plot(t,impResp_butter);
hold on;
title([ 'Butterworth (', num2str(butterOrder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,3)
plot(t,impResp_cheby1);
hold on;
title([ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,4)
plot(t,impResp_cheby2);
hold on;
title([ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,5)
plot(t,impResp_ellip);
hold on;
title([ 'Elliptic (', num2str(ellipOrder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');

subplot(3,2,6)
plot(t,impResp_firfilter);
hold on;
title([ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
%xlim([0 F2*2]);
%ylim([-1.5 1.5]);
grid on;
xlabel('N (Samples)');
ylabel('Amplitude');


%% Plots, Chirp response

figure('pos',[500 500 1000 500]);
suptitle('Chirp response')
hold on;

subplot(3,2,1);
plot(y_kilosort_chirp, 'r');
hold on;
title([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ]);
xlim([0 F2*2]);
ylim([-1.5 1.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude');

subplot(3,2,2);
plot(y_butter_chirp);
hold on;
title([ 'Butterworth (', num2str(butterOrder), '. order)' ]);
xlim([0 F2*2]);
ylim([-1.5 1.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude');

subplot(3,2,3)
plot(y_cheby1_chirp);
hold on;
title([ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ]);
xlim([0 F2*2]);
ylim([-1.5 1.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude');

subplot(3,2,4)
plot(y_cheby2_chirp);
hold on;
title([ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ]);
xlim([0 F2*2]);
ylim([-1.5 1.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude');

subplot(3,2,5)
plot(y_ellip_chirp);
hold on;
title([ 'Elliptic (', num2str(ellipOrder), '. order)' ]);
xlim([0 F2*2]);
ylim([-1.5 1.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude');

subplot(3,2,6)
plot(y_firfilter_chirp);
hold on;
title([ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
xlim([0 F2*2]);
ylim([-1.5 1.5]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude');


%% Plots, Magnitude response when applied to chirp

Hy_kilosort = abs(fft(y_kilosort_chirp));
M_kilosort = ceil(length(Hy_kilosort)/2);
xn_kilosort = (1:M_kilosort).*(fs/(length(Hy_kilosort)));

Hy_butter = abs(fft(y_butter_chirp));
M_butter = ceil(length(Hy_butter)/2);
xn_butter = (1:M_butter).*(fs/(length(Hy_butter)));

Hy_cheby1 = abs(fft(y_cheby1_chirp));
M_cheby1 = ceil(length(Hy_cheby1)/2);
xn_cheby1 = (1:M_cheby1).*(fs/(length(Hy_cheby1)));

Hy_cheby2 = abs(fft(y_cheby2_chirp));
M_cheby2 = ceil(length(Hy_cheby2)/2);
xn_cheby2 = (1:M_cheby2).*(fs/(length(Hy_cheby2)));

Hy_ellip = abs(fft(y_ellip_chirp));
M_ellip = ceil(length(Hy_ellip)/2);
xn_ellip = (1:M_ellip).*(fs/(length(Hy_ellip)));

Hy_firfilter = abs(fft(y_firfilter_chirp));
M_firfilter = ceil(length(Hy_firfilter)/2);
xn_firfilter = (1:M_firfilter).*(fs/(length(Hy_firfilter)));

figure('pos',[500 500 900 400]);
plot(xn_kilosort, 20*log10(Hy_kilosort(1:M_kilosort)));
hold on;
plot(xn_butter, 20*log10(Hy_butter(1:M_butter)));
plot(xn_cheby1, 20*log10(Hy_cheby1(1:M_cheby1)));
plot(xn_cheby2, 20*log10(Hy_cheby2(1:M_cheby2)));
plot(xn_ellip, 20*log10(Hy_ellip(1:M_ellip)));
plot(xn_firfilter, 20*log10(Hy_firfilter(1:M_firfilter)));
title('Kilosort butter magnitude response');
xlim([0 F2*2]);
ylim([-80 45]);
plot([F1 F1],ylim,'--k');
plot([F2 F2],ylim,'--k');
grid on;
title([ 'Magnitude response of digital filters applied on chirp' ]);
[lgd,hObj] = legend([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ],[ 'Butterworth (', num2str(butterOrder), '. order)' ],[ 'Chebyshev Type I (', num2str(cheby1Order), '. order)' ],[ 'Chebyshev Type II (', num2str(cheby2Order), '. order)' ],[ 'Elliptic (', num2str(ellipOrder), '. order)' ],[ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');

%% Plots, Phase Delay
[phi_kilosort,w_phase_kilosort] = phasedelay(b_kilosort);
[phi_butter,w_phase_butter] = phasedelay(b_butter);
[phi_cheby1,w_phase_cheby1] = phasedelay(b_cheby1);
[phi_cheby2,w_phase_cheby2] = phasedelay(b_cheby2);
[phi_ellip,w_phase_ellip] = phasedelay(b_ellip);
[phi_firfilter,w_phase_firfilter] = phasedelay(b_firfilter);

phi_kilosort = round(phi_kilosort);
phi_butter = round(phi_butter);
phi_firfilter = round(phi_firfilter);

figure('pos',[500 500 900 400]);
plot(w_phase_kilosort*fs/(2*pi),phi_kilosort);
hold on;
plot(w_phase_butter*fs/(2*pi),phi_butter);
plot(w_phase_firfilter*fs/(2*pi),phi_firfilter);
xlim([300 8000]);
ylim([-50 100]);
grid on;
title([ 'Phase Delay in samples' ]);
legend([ 'Kilosort (Butterworth) (', num2str(kilosortOrder), '. order)' ],[ 'Butterworth (', num2str(butterOrder), '. order)' , char(10), 'Chebyshev Type I (', num2str(cheby1Order), '. order)', char(10),  'Chebyshev Type II (', num2str(cheby2Order), '. order)' , char(10), 'Elliptic (', num2str(ellipOrder), '. order)'  ],[ 'FIR (Window) (', num2str(firfilterorder), '. order)' ]);
xlabel('Frequency (Hz)');
ylabel('Samples');

%% Plots, Phase Delay Filtfilt vs Filter
load('PhaseDelayTest.mat');

x = forSaving;

y_kilosort_phaseDelay1 = filtfilt(b_kilosort,a_kilosort,x);
y_kilosort_phaseDelay2 = filter(b_kilosort,a_kilosort, x); 

y_kilosort_phaseDelay3 = filter(b_kilosort, a_kilosort, x);
y_kilosort_phaseDelay3 = flipud(y_kilosort_phaseDelay3);
y_kilosort_phaseDelay3 = filter(b_kilosort, a_kilosort, y_kilosort_phaseDelay3);
y_kilosort_phaseDelay3 = flipud(y_kilosort_phaseDelay3);

figure('pos',[500 500 900 400]);
plot(x);
hold on;
plot(y_kilosort_phaseDelay3);
plot(y_kilosort_phaseDelay1);
xlim([20 100]);
grid on;
legend('Raw signal','Forward Kilosort (3. order)','Forward-Backward Kilosort (3. order)');
title([ 'Zero-Phase filtering response in samples' ]);
xlabel('Samples');
ylabel('Amplitude');