function [ y ] = fibonacciMB( x )
%FIBONACCIMB Summary of this function goes here
%   Detailed explanation goes here
%create fibonacci sequence of length nfibo
nfibo=x+2;
fibonacci=[0,1,zeros(1,nfibo-2)];
for Y = 1:x
    fibonacci(Y+2)=fibonacci(Y+1)+fibonacci(Y);
end

y = fibonacci(Y+2);
%fibonacci = fibonacci(3:numel(fibo)); % Remove initial

end

