function [ output_args ] = setC( parent, varargin )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

children = get(parent,'children');

for i=1:length(children)
   set(children(i),varargin{1:nargin-1});
end
set(parent,varargin{1:nargin-1});

end