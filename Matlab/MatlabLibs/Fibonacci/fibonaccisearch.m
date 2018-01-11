
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            Developed by Shakun Bansal,07010344,B-Tech Mechanical
%                                   IIT Guwahati, India               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The script fibonaccisearch.m finds the range in which the minima 
%of the non linear one dimension unconstrained problem lies.
% Input:
%  
%     1)Function in the proper format.
%       kindly ensure that fuction is unimodal in the given interval,the
%       script checks the unimodality of the function by calling the
%       function unimodal.m
%      2)Initial interval of uncertainity.
%      
%       3)No. of function evaluations
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
clc
clear all
b=2;warning off all
while b==2
    a=2;
    syms('x')
    
    while a==2
        try
            f=input('\nEnter the function in terms of variable x:');a=1;
        catch
            display('\nKindly recheck the index of variables and format of expression!');a=2;
        end
    end
    
    
    l=input('\nEnter the initial interval of uncertainity ex. [a,b]:');
    a=2;
    while a==2
        if l(2)<=l(1)
            display('\nkindly recheck the order ')
            input('\nenter the interval')
            a=2;
        else a=1;
        end
    end
    s=solve(diff(subs(f)));
    s=double(s);
    lmod=unimodal(s,l);
    
    if isempty(s)
    slope=double(diff(subs(f)));
    if slope>0
    fprintf('\nThe function is strictly increasing in its domain and hence it is unimodal in the given interval\n')
    elseif slope<0
        fprintf('\nThe function is strictly decreasing in its domain and hence it is unimodal in the given interval\n')
    end
      
end   
    if lmod==0
        b=2;
        fprintf('\n kindly ensure that function is unimodal in the interval you are choosing')
    else b=1;
%         fprintf('\nthe function is unimodal in the given interval')
    end
end
    

        n=input('\n-----------------------------------------------------\nEnter the number of functional evaluations:');
        n=n+1;
for j=1:n
    if j==1||j==2
        g(j)=1;
        
    else
        g(j)=g(j-1)+g(j-2);
    end
end
lo=l(2)-l(1);
l2=g(n-2)/g(n)*lo;
x1=l(1)+l2;
x2=l(2)-l2;

min=l(1);
max=l(2);
xf=x1;
xl=x2;
for k=2:6
    if subs(f,xf)<subs(f,xl)
        max=xl;
        xi=min+xl-xf;
        if xi>xf
            xl=xi;
        else xl=xf;
            xf=xi;
        end
    else min=xf;
        xi=min+xl-xf;
        if xi>xl
            xl=xi;
            xf=xl;
        else xi=xf;
        end
    end
end
fprintf('\nthe final interval of uncertainity is %f-%f\n',xf,xl)













%      display(g)
