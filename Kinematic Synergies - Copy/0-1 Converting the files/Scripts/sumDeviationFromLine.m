function [ sumDev ] = sumDeviationFromLine( crookedPath, line )
%SUMDEVIATIONFROMLINE Calculates the shortest distance from every point on
%a path to a line, and sums all these deviations.
%
%   The given path and line need to be in the same dimension space. They
%   needn't have the same number of steps. The line must have at least 2
%   steps.
%   
%   Example: crookedPath = [0 0; 1 3; 4 3; 6 5] (2D path)
%            line = [0 0; 10 10] (2D line)
%            sumDeviationFromLine(crookedPath, line)

[~, dimension] = size(line);
if dimension == 2
   % path and line need to be at least 3D to use cross()
   crookedPath = [crookedPath, zeros(length(crookedPath),1)];
   line = [line, zeros(length(line),1)];
end

v1 = line(1,:);
v2 = line(2,:);
b = v2-v1; %vector pointing along line

sumDev = 0;
for i=1:length(crookedPath)
    a = crookedPath(i,:) - v1; %vector from point on line to point on path
    
    if a == 0
       l = 0;
    else
        l = norm(cross(a,b))/norm(b);
    end
    
    sumDev = sumDev + l;
end

end