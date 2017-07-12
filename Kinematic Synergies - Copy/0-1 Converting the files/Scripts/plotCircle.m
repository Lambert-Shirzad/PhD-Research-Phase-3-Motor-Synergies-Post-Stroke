function [ ] = plotCircle( center, radius, varargin )
%PLOTCIRCLE Plots a circle of given radius at the given center on the
%active figure
%
%   Can also further specify the plot properties.

angle = linspace(0,2*pi,100)';
points = radius * [cos(angle), sin(angle)];
points = points + repmat(center,[length(points),1]);
plot(points(:,1), points(:,2), varargin{1:nargin-2});

end