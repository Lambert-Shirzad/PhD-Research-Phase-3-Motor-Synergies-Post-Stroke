function [ F ] = finiteDerivative( x, f, order )
%FINITEDERIVATIVE Computes the given order derivative of a finite data set 
%based on finite differences. If f(x) is the function, this returns 
%F(x) = f^(order)(x).
%   "x" - vector of the domain
%   "f" - vector of the function values
%   "order" - the order of the derivative to take

timeIntervals = diff(x);
denom = timeIntervals .^order;
numerator = diff(f,order);
denom = denom(1:length(numerator));
[~,n] = size(numerator);
F = numerator./repmat(denom,[1,n]);

end

