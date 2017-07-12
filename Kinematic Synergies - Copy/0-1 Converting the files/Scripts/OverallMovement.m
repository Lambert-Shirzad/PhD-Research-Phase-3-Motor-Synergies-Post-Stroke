%------------------------------%
% COMMENTS
% - This function calculates the total time played and total distance 
%    travelled of both hand and return the results.
%
% Author: Tina Hung
%------------------------------%

function [leftmove,rightmove] =OverallMovement(FilteredData)
    % Initialize variables
    LeftMovedDistance=0;
    RightMovedDistance=0;
    
    % Extract data for distance calculation.
    LeftWristPosition= FilteredData(1:end,5:7);
    RightWristPosition = FilteredData(1:end,10:12);
    ExistData=isnan(LeftWristPosition(:,1));

    i=1;
    while(i<length(ExistData))
        % calculate the total delx+dely+delz for each hand
        LeftMovedDistance = LeftMovedDistance+sqrt((LeftWristPosition(i+1,1)- LeftWristPosition(i,1))^2+(LeftWristPosition(i+1,2)- LeftWristPosition(i,2))^2+(LeftWristPosition(i+1,3)- LeftWristPosition(i,3))^2);
        RightMovedDistance = RightMovedDistance+sqrt((RightWristPosition(i+1,1)- RightWristPosition(i,1))^2+(RightWristPosition(i+1,2)- RightWristPosition(i,2))^2+(RightWristPosition(i+1,3)- RightWristPosition(i,3))^2);
        i=i+1;
    end

    leftmove=LeftMovedDistance;
    rightmove=RightMovedDistance;
    
end