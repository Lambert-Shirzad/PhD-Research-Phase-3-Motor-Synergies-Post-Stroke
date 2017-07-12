function [ coords, TARGET_RADIUS ] = getTargetCoordinates( targetLabel, screenHeight, screenWidth )
%GETTARGETCOORDINATES Returns the center of the target, as well as the
%target's radius.

TARGET_RADIUS = 40; %[px]

outerRadius = screenHeight/2 - TARGET_RADIUS; %[px]
innerRadius = screenHeight/4 - TARGET_RADIUS; %[px]

centerX = screenWidth/2;
centerY = screenHeight/2;

switch targetLabel
    case 2
        angle = 3*pi/2;
        radius = innerRadius;
    case 3
        angle = 7*pi/4;
        radius = innerRadius;
    case 4
        angle = 0;
        radius = innerRadius;
    case 5
        angle = pi/4;
        radius = innerRadius;
    case 6
        angle = pi/2;
        radius = innerRadius;
    case 7
        angle = 3*pi/4;
        radius = innerRadius;
    case 8
        angle = pi;
        radius = innerRadius;
    case 9
        angle = 5*pi/4;
        radius = innerRadius;
    case 10
        angle = 3*pi/2;
        radius = outerRadius;
    case 11
        angle = 7*pi/4;
        radius = outerRadius;
    case 12
        angle = 0;
        radius = outerRadius;
    case 13
        angle = pi/4;
        radius = outerRadius;
    case 14
        angle = pi/2;
        radius = outerRadius;
    case 15
        angle = 3*pi/4;
        radius = outerRadius;
    case 16
        angle = pi;
        radius = outerRadius;
    case 17
        angle = 5*pi/4;
        radius = outerRadius;
    otherwise
        fprintf('You''re a goof. That''s not a valid target');
end

coords = [centerX + radius*cos(angle), centerY + radius*sin(angle)];

end

