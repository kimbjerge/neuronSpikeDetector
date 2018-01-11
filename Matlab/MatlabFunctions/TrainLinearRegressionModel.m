function [ Model, error  ] = TrainLinearRegressionModel( Prediction,  Response, PrintFiguresRunning, Order)
%TRAINLINEARREGRESSIONMODEL Summary of this function goes here
%   Detailed explanation goes here

    PredictionSize = size(Prediction);

    Model = 0;
    
    if PredictionSize(2) == 1

        N = PredictionSize(1);
        x = Prediction';
        y = Response';
        N = size(x);
        N = N(2);
        Z = getZOrderMatrix(Order, N, x);
        W = inv(Z'*Z)*Z'*y'  % w = (XT*X)-1 XT * T
        if strcmp(PrintFiguresRunning, 'YES') == 1
            plot(x,y, '.'), hold on
            YValues = getplotValueForDecisionB(Order, W, x);
            plot(x, YValues, 'k.')
        end
        Model = W;        
    elseif PredictionSize(2) == 2 
        
        FalsePrediction = Prediction(find(Response == -1),:);
        TruePrediction = Prediction(find(Response == 1),:);
        x1 = FalsePrediction(:,1);
        y1 = FalsePrediction(:,2);
        x2 = TruePrediction(:,1);
        y2 = TruePrediction(:,2);
        N1 = size(x1);
        N1 = N1(1);
        N2 = size(x2);
        N2 = N2(1);
        figure, scatter(x1, y1, 'r'), hold on, scatter(x2,y2, 'b')
        t(:,1) = [zeros(N1,1) ; ones(N2,1)];
        t(:,2) = [ones(N1,1) ; zeros(N2,1)];
        Z = [[x1;x2] [y1;y2] ones(N1+N2,1)];
        W = inv(Z'*Z)*Z'*t
        y_est = Z*W;
        [max_val,max_id] = max(y_est'); % find max. values
        t_est = max_id - 1 ; % id is 1,2,3.. in matlab - not 0,1,2..
        scatter(x1(t_est(1:N1)==1), y1(t_est(1:N1)==1), 'bx')
        scatter(x2(t_est(N1+1:end)==0), y2(t_est(N1+1:end)==0), 'rx')
        % decision boundary
        dwx = W(1,1)-W(1,2); dwy = W(2,1)-W(2,2); dwbias = W(3,1)-W(3,2);
        xdecbound = linspace(-2,3,30); % simply plotpoints
        plot(xdecbound, -(dwx/dwy)*xdecbound - (dwbias/dwy), 'k')  
    elseif PredictionSize(2) == 3
        
    end
end



function [ Z ] = getZOrderMatrix(Order, N, x)
    Z = 0;    

    if Order == 1
        Z = [ones(N,1) x'];
    elseif Order == 2
        Z = [ones(N,1) x' x'.^2];
    elseif Order == 3
        Z = [ones(N,1) x' x'.^2 x'.^3];
    elseif Order == 4
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4]; 
    elseif Order == 5
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5]; 
    elseif Order == 6
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6]; 
    elseif Order == 7
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7]; 
    elseif Order == 8
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7 x'.^8];
    elseif Order == 9
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7 x'.^8 x'.^9];
    elseif Order == 10
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7 x'.^8 x'.^9 x'.^10];
    elseif Order == 11
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7 x'.^8 x'.^9 x'.^10 x'.^11];
    elseif Order == 12   
        Z = [ones(N,1) x' x'.^2 x'.^3 x'.^4 x'.^5 x'.^6 x'.^7 x'.^8 x'.^9 x'.^10 x'.^11 x'.^12];
    end    
        
end


function [ Y ] = getplotValueForDecisionB(Order, W, x)
    Y = 0;    

    if Order == 1
        Y = W(1) + W(2).*x;
    elseif Order == 2
        Y = W(1) + W(2).*x + W(3).*x.^2;
    elseif Order == 3
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3;
    elseif Order == 4
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4;
    elseif Order == 5
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5; 
    elseif Order == 6
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6; 
    elseif Order == 7
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6 + W(8).*x.^7; 
    elseif Order == 8
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6 + W(8).*x.^7 + W(9).*x.^8; 
    elseif Order == 9
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6 + W(8).*x.^7 + ...
            W(9).*x.^8  + W(10).*x.^9;
    elseif Order == 10
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6 + W(8).*x.^7 + ...
            W(9).*x.^8 + W(10).*x.^9 + W(11).*x.^10 ;
    elseif Order == 11
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6 + W(8).*x.^7 + ...
            W(9).*x.^8  + W(10).*x.^9 + W(11).*x.^10 + W(12).*x.^11;
    elseif Order == 12   
        Y = W(1) + W(2).*x + W(3).*x.^2 + W(4).*x.^3 + W(5).*x.^4 + W(6).*x.^5 + W(7).*x.^6 + W(8).*x.^7 + ...
            W(9).*x.^8  + W(10).*x.^9 + W(11).*x.^10 + W(12).*x.^11 + W(13).*x.^12;
    end    
        
end

