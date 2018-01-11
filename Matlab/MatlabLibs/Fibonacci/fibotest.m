clear,clc
x=-pi/4:pi/24:5*pi/4;
y=unknownf(x); plot(x,y);grid on
x=fibosearch(@unknownf,0,1,0.001);
