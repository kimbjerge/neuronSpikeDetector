function x = fibosearch(fhandle,a,b,finalRange)
    % fibonacci search for maximum of unknown unimodal function in one variable
    %     x = fibosearch(fhandle,a,b,npoints)
    % a,b define the search interval with resolution 1/npoints

    numberOfIterations = 0;
    epsilon = 0.01;
    maxSearch = 50;


    range = finalRange/(b-a);
    fibonacciArray = [];
    %find number of required iterations
    for I = 1 : maxSearch
        fibonacciArray(I) = fibonacci(I); 
        if  fibonacciArray(I) >= (1+2*epsilon)/range;
            numberOfIterations = I - 1;
            break;
        end
    end

    kept = a;

    if numberOfIterations ~= 0
        for k=1:numberOfIterations
            pa = 1 - (fibonacciArray(numberOfIterations-k+1)/fibonacciArray(numberOfIterations-k+2));
            pb = pa;

            if k == numberOfIterations
               if kept == a 
                   pb = pb - epsilon;
               else
                   pa = pa - epsilon;
               end
            end

            x1 = a+pa*(b-a);
            x2 = b-(pb)*(b-a);
            fx1 = fhandle(x1);
            fx2 = fhandle(x2);

            if fx1<fx2
               a=x1;
               kept = a;
               %x1=x2; fx1=fx2;
               %x2=b-p*(b-a);
               %fx2=fhandle(x2);
            else
                b=x2;
                kept = b;
                %x2=x1; fx2=fx1;
                %x1=a+p*(b-a);
                %fx1=fhandle(x1);
            end
        end
        if fx1<fx2
            x=x2;
        else
            x=x1;
        end
        disp(x)
    end
end


function y=fibonacci(x)
%create fibonacci sequence of length nfibo
nfibo=x+2;
fibonacci=[0,1,zeros(1,nfibo-2)];
for Y = 1:x
    fibonacci(Y+2)=fibonacci(Y+1)+fibonacci(Y);
end

y = fibonacci(Y+2);
%fibonacci = fibonacci(3:numel(fibo)); % Remove initial
end

