clear all;
close all;
clc;

rng default;

x = [-3:.1:3];
norm = normpdf(x,0,0.5);

x1 = [-3:.1:2.9];

norm1 = diff(norm);
norm1 = norm1.*5;

x2 = [-2.9:.1:2.9];

norm2 = diff(norm1);
norm2 = norm2.*5;

figure('rend','painters','pos',[500 500 700 400]);
plot(x,norm)
hold on;
plot(x1,norm1)
plot(x2,norm2)
xlim([-2 2]);
ylim([-1 1]);
%grid on;
title('Gaussian and derivatives');
legend('Gaussian Distribution','Gradient (1st derivative)','Laplacian (2nd derivative)');
xlabel('x','FontSize',16);
ylabel('g(x,\mu,\sigma)','FontSize',16);

N = 3.0;
x=linspace(-N, N,50);
y=x;

figure('rend','painters','pos',[500 500 700 400]);
[X,Y]=meshgrid(x,y);
z=(1/sqrt(2*pi).*exp(-(X.^2/2)-(Y.^2/2)));
surf(X,Y,z);
title('2D Gaussian Distribution');
xlabel('x','FontSize',13);
ylabel('y','FontSize',13);
zlabel('g(x,y,\mu,\sigma)','FontSize',13);
view(125,15);

figure('rend','painters','pos',[500 500 700 400]);
[X,Y]=meshgrid(x,y);
X1 = X(1:49,:);
Y1 = Y(1:49,:);
z1 = diff(z);
z1 = z1.*5;
surf(X1,Y1,z1);
title('2D Gradient of Gaussian');
xlabel('x','FontSize',13);
ylabel('y','FontSize',13);
zlabel('g(x,y,\mu,\sigma)','FontSize',13);
view(125,15);

figure('rend','painters','pos',[500 500 700 400]);
[X,Y]=meshgrid(x,y);
X2 = X(2:49,:);
Y2 = Y(2:49,:);
z2 = diff(z1);
z2 = z2.*5;
surf(X2,Y2,z2);
title('2D Laplacian of Gaussian');
xlabel('x','FontSize',13);
ylabel('y','FontSize',13);
zlabel('g(x,y,\mu,\sigma)','FontSize',13);
view(125,15);