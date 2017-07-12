function [ distance ] = pathLength( pathMatrix )
%PATHLENGTH For any path in n-space, calculates total
%distance traveled by a particle on that path.
%
%   pathMatrix: An (m x n) matrix. Path takes "m" steps in
%   "n"-dimensional space.
%   
%   Example: P = [0 0; 1 2; 4 3];
%            (a 2D path with 3 steps: (0,0)->(1,2)->(4,3))
%            pathLength(P)
%            ans = 5.3983

[~,n] = size(pathMatrix);

innerSum = 0;
for i=1:n
    innerSum = innerSum + diff(pathMatrix(:,i)).^2;
end

distance = sum(sqrt(innerSum));

end