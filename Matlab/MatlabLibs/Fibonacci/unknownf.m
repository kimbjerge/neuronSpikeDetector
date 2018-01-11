%%
function y=unknownf(x)
y = x.^4 - 10*x.^3 + 160*x.^2 - 70*x;
y = -y;
end