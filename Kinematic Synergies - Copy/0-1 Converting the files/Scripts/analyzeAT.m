function [ test, axesHandles, allTargetsData ] = analyzeAT( filepath, graph )
%ANALYZEAT Analyzes a filtered "Assessment Tool" Excel data file.
%   Detailed explanation goes here

%% Constants

X_RATIO = 1.43;
Y_RATIO = 1.55;
Z_RATIO = 1.11;

NO_BTN_PRESSED = 0;
RED_BTN_PRESSED = 1;
WHITE_BTN_PRESSED = 2;
BOTH_BTN_PRESSED = 3;

SUBJECT_ID = 'SubjectID';
DATA_TYPE = 'DataType';
CLICKING_HAND = 'ClickingHand';
CLICKING_MODE = 'ClickingMode';
MOTION_MODE = 'MotionMode';
EASY_CENTER = 'EasyCentering';
CURSOR_SENSITIVITY = 'Cursor (%)';
CENTER_SENSITIVITY = 'Centering (%)';
X_OFFSET = 'xoff (cm)';
Y_OFFSET = 'yoff (cm)';
RUMBLE = 'Rumble';

FIRST_TARGET_LABEL = 2;
LAST_TARGET_LABEL = 17;

FIRST_DATA_COL = 4;

SHEET = 'Sheet1';

SCREEN_WIDTH = 1366; %[px]
SCREEN_HEIGHT = 768; %[px]

PS3 = 2;
KINECT = 3;

%% Helper Functions

    function goToNextTarget(~,~)
        if currentAxesIndex+1 <= length(axesHandles)
            currentAxesIndex = currentAxesIndex+1;
        end
        refreshFigure();
    end

    function goToPrevTarget(~,~)
        if currentAxesIndex-1 >= 1
            currentAxesIndex = currentAxesIndex-1;
        end
        refreshFigure();
    end

    function refreshFigure()
        for targetIndex=1:length(axesHandles)    
            setC(axesHandles(targetIndex),'visible','off');
        end
        
        setC(axesHandles(currentAxesIndex),'visible','on');
        try
            axes(axesHandles(currentAxesIndex));
        catch
        end
    end

    function addPlot()
        ha = axes('parent',hFig);
        plotIndex = plotIndex+1;
        axesHandles(plotIndex) = ha;
    end

    function addPanel(handle)
        set(handle,'parent',hFig);
        plotIndex = plotIndex+1;
        axesHandles(plotIndex) = handle;
    end

%% Main

[~,~,raw] = xlsread(filepath, SHEET);

%Make a map between settings keys and vals. Example use:
%settings('DataType') returns the values for the 'DataType' field.
settings = containers.Map(raw(5:15,1), raw(5:15,2));

if settings(DATA_TYPE) == PS3
    LAST_DATA_COL = 18;
    
    TIMESTAMP = 1;
    CURSOR_X = 2;
    CURSOR_Y = 3;
    CENTERING = 4;
    LEFT_X = 5;
    LEFT_Y = 6;
    LEFT_Z = 7;
    LEFT_CLICK = 8;
    LEFT_VISUAL = 9;
    RIGHT_X = 10;
    RIGHT_Y = 11;
    RIGHT_Z = 12;
    RIGHT_CLICK = 13;
    RIGHT_VISUAL = 14;
    TARGET = 15;
    EXCLUDED = 16;
    
    data = cell2mat(raw(2:end,FIRST_DATA_COL:LAST_DATA_COL));
    
    %apply ratios
    data(:,LEFT_X) = data(:,LEFT_X)/(X_RATIO*10);
    data(:,LEFT_Y) = -1*data(:,LEFT_Y)/(Y_RATIO*10);
    data(:,LEFT_Z) = data(:,LEFT_Z)/(Z_RATIO*10);
    data(:,RIGHT_X) = data(:,RIGHT_X)/(X_RATIO*10);
    data(:,RIGHT_Y) = -1*data(:,RIGHT_Y)/(Y_RATIO*10);
    data(:,RIGHT_Z) = data(:,RIGHT_Z)/(Z_RATIO*10);
    
    %split the data up into segments for each target.
    direction = 1;
    for target=FIRST_TARGET_LABEL:LAST_TARGET_LABEL
        indices = find(data(:,TARGET)==target);
        segmentStartIndex = indices(1);
        for i=1:length(indices)-1
            if (indices(i+1) - indices(i) > 1) || (i+1 == length(indices))
                allTargetsData{direction} = data(segmentStartIndex:indices(i),:);
                allTargetsData{direction}(1,end+1) = 0;
                direction = direction+1;
                segmentStartIndex = indices(i+1);
            end
        end
    end
    
    numTargets = length(allTargetsData);
    
    if graph       
        hFig = figure;
%         axesHandles = zeros(numTargets,1);
        prevTargetBtn = uicontrol('Style','pushbutton','String',...
            'Previous Target','units','normalized',...
            'Position',[0.01 0.01 0.05 0.05],...
            'callback', @goToPrevTarget);
        nextTargetBtn = uicontrol('Style','pushbutton','String',...
            'Next Target','units','normalized',...
            'Position',[0.94 0.01 0.05 0.05],...
            'callback',@goToNextTarget);
        currentAxesIndex = 1;
        set(hFig,'toolbar','figure');
        drawnow;
    end  
    
    numHit = 0;
    
    %for each target segment, analyze it
    plotIndex = 0;
    for i=1:numTargets
        targetData = allTargetsData{i};
        resTargetData = ResampleData(50,6,targetData(:,TIMESTAMP)/1000,targetData(:,[LEFT_X,LEFT_Y,LEFT_Z,RIGHT_X,RIGHT_Y,RIGHT_Z]));
        excluded = false;
        
        targetLabel = targetData(1,TARGET);
        [targetCenter, targetRadius] = getTargetCoordinates(targetLabel,SCREEN_HEIGHT,SCREEN_WIDTH);
        cursorPath = [targetData(:,CURSOR_X), targetData(:,CURSOR_Y)];
        cursorPathStart = [targetData(1,CURSOR_X),targetData(1,CURSOR_Y)];
        cursorPathEnd = [targetData(end,CURSOR_X),targetData(end,CURSOR_Y)];
        
        %calculations
        whiteIndices = find((targetData(:,RIGHT_CLICK) == WHITE_BTN_PRESSED)...
            | (targetData(:,LEFT_CLICK) == WHITE_BTN_PRESSED));
        redIndices = find(targetData(:,RIGHT_CLICK) == RED_BTN_PRESSED...
            | targetData(:,LEFT_CLICK) == RED_BTN_PRESSED);
        
        endDistanceFromTargetEdge = pathLength([targetCenter; targetData(end,CURSOR_X), targetData(end,CURSOR_Y)]) - targetRadius;
        hitTarget = endDistanceFromTargetEdge < 0;
        if hitTarget
            numHit = numHit + 1;
        end
        
        totalTimeSecs = (targetData(end,TIMESTAMP) - targetData(1,TIMESTAMP))/1000;
        totalCursorDistancePixels = pathLength(cursorPath);
        
        shortestPathToCenter = [cursorPathStart; targetCenter];
        shortestPathLength = pathLength(shortestPathToCenter) - targetRadius;
        percDiffPathLength = (totalCursorDistancePixels - shortestPathLength)/shortestPathLength*100;
        
        accumulatedDeviation = sumDeviationFromLine(cursorPath, shortestPathToCenter);
        deviationPerPoint = accumulatedDeviation/length(cursorPath);
        
        numRecenterings = length(find(diff(find(targetData(:,CENTERING)==1)) > 1));
        if numRecenterings > 0
            excluded = true;
        end
        
        totalLeftWristDistance = pathLength([targetData(:,LEFT_X),targetData(:,LEFT_Y)]);
        totalRightWristDistance = pathLength([targetData(:,RIGHT_X),targetData(:,RIGHT_Y)]);
        totalLeftWristZDistance = pathLength(targetData(:,LEFT_Z));
        totalRightWristZDistance = pathLength(targetData(:,RIGHT_Z));
        
        time = resTargetData(:,1);
        displacement{1} = resTargetData(:,2:4);
        displacement{2} = resTargetData(:,5:7);
        velocity{1} = finiteDerivative(time,displacement{1},1);
        velocity{2} = finiteDerivative(time,displacement{2},1);
        acceleration{1} = finiteDerivative(time,displacement{1},2);
        acceleration{2} = finiteDerivative(time,displacement{2},2);
        jerk{1} = finiteDerivative(time,displacement{1},3);
        jerk{2} = finiteDerivative(time,displacement{2},3);
        
        dirStr = ['X','Y'];
        handStr = {'Left','Right'};
        
        %find velocity profile peaks
        for direction=1:2
            for hand=1:2
                si = sign(mean(velocity{hand}(:,direction)));
                posVelocity = velocity{hand}(:,direction)*si;
                [~,velPeakLocs{hand}{direction}] = findpeaks(posVelocity,'minpeakheight',mean(posVelocity(posVelocity>0)));
                numPeaks{hand}{direction} = length(velPeakLocs{hand}{direction});
            end
            peakSummary{direction} = sprintf('%s-direction peaks: %d (%s), %d (%s); ',...
                dirStr(direction), numPeaks{1}{direction}, handStr{1},...
                numPeaks{2}{direction}, handStr{2});
        end
        targetFromScreenCenter = targetCenter - [SCREEN_WIDTH/2, SCREEN_HEIGHT/2];
        allPeaksSummary = strcat(cell2mat(strcat(peakSummary{targetFromScreenCenter ~= 0},{''})));
        
        allTargetsData{i}(1,EXCLUDED) = excluded;
        
        %create summary of analysis
        targetSummary = sprintf('%s%s\n%s\nTime taken: %0.1f s\nTotal cursor distance: %0.0f px\nShortest path to target edge: %0.0f px\nPercent difference from shortest path length: %0.1f%%\nNumber of recenterings: %d\nNormalized deviation from shortest path: %0.0f px/point\nTotal L XY distance: %0.0f cm\nTotal R XY distance: %0.0f cm\nUnnecessary L Z distance: %0.0f cm\nUnnecessary R Z distance: %0.0f cm\n',...
            allPeaksSummary,...
            iif(excluded,'EXCLUDED',''),...
            iif(hitTarget,'Hit target!',...
            sprintf('Missed target by %0.0f px.',endDistanceFromTargetEdge)),...
            totalTimeSecs, totalCursorDistancePixels,...
            shortestPathLength, percDiffPathLength,...
            numRecenterings, deviationPerPoint,...
            totalLeftWristDistance, totalRightWristDistance,...
            totalLeftWristZDistance, totalRightWristZDistance);
        fprintf('Target: %d\n%s---------------\n',targetLabel, targetSummary);
        
        if graph
            %plot the cursor path
            addPlot();
            
            hold on;
            plot(targetData(:,CURSOR_X), targetData(:,CURSOR_Y));
            plot(cursorPathStart(1), cursorPathStart(2), 'gd', 'MarkerFaceColor','g');
            plot(cursorPathEnd(1), cursorPathEnd(2), 'rd','MarkerFaceColor','r');
            plot(targetData(whiteIndices,CURSOR_X), targetData(whiteIndices,CURSOR_Y), 'o', 'MarkerFaceColor','w');
            plot(targetData(redIndices,CURSOR_X), targetData(redIndices,CURSOR_Y), 'o','MarkerFaceColor','r');
            plot(shortestPathToCenter(:,1), shortestPathToCenter(:,2), ':', 'Color', [1 0.5 0]);
            plotCircle(targetCenter, targetRadius, '-', 'Color', [1 0.5 0]);
            title(sprintf('Target %d', targetLabel));
            xlabel('Cursor X');
            ylabel('Cursor Y');
            xlim([0, SCREEN_WIDTH]);
            ylim([0, SCREEN_HEIGHT]);
            text(100, 200, targetSummary);
            hold off;
            
            %plot hand paths
            addPlot();
            
            hold on;
            plot3(displacement{1}(:,1),displacement{1}(:,3),displacement{1}(:,2),'-b'); %left hand XY path
            plot3(displacement{1}(1,1),displacement{1}(1,3),displacement{1}(1,2),'gd', 'MarkerFaceColor','g');
            plot3(displacement{1}(end,1),displacement{1}(end,3),displacement{1}(end,2),'rd', 'MarkerFaceColor','r');
            plot3(displacement{2}(:,1),displacement{2}(:,3),displacement{2}(:,2),'-r'); %right hand XY path
            plot3(displacement{2}(1,1),displacement{2}(1,3),displacement{2}(1,2),'gd', 'MarkerFaceColor','g');
            plot3(displacement{2}(end,1),displacement{2}(end,3),displacement{2}(end,2),'rd', 'MarkerFaceColor','r');
            view(0,0);
            grid on;
            xlabel('X (cm)');
            ylabel('Z (cm)');
            zlabel('Y (cm)');
            title(sprintf('Target %d - 3D Hand Paths', targetLabel));
            hold off;
            
            %plot displacement, velocity
            for direction=1:length(dirStr)
                hp = uipanel('parent',hFig,'position',[0 0 1 1],...
                    'title',sprintf('%s-Direction',dirStr(direction)),...
                    'titlePosition','centertop','fontsize',10);
                addPanel(hp);
                
                for hand=1:length(handStr)
                    subplot(2,2,hand,'parent',hp);
                    hold on;
                    plot(time,displacement{hand}(:,direction),'-b');
                    ylabel('Displacement (cm)');
                    title(sprintf('Target %d (%s Hand)', targetLabel,handStr{hand}));
                    xlim([time(1),time(end)]);
                    hold off;

                    subplot(2,2,hand+2,'parent',hp);
                    hold on;
                    plot(time(1:length(velocity{hand})),velocity{hand}(:,direction),'-g');
                    ylabel('Velocity (cm/s)');
                    xlabel('Time (s)');
                    xlim([time(1),time(end)]);
                    plot(time(velPeakLocs{hand}{direction}),velocity{hand}(velPeakLocs{hand}{direction},direction),'ro');
                    hold off;

%                     subplot(4,2,hand+4,'parent',hp);
%                     plot(time(1:length(acceleration{hand})),acceleration{hand}(:,direction),'-r');
%                     ylabel('Acceleration (cm/s^2)');
%                     xlim([time(1),time(end)]);
%                     
%                     subplot(4,2,hand+6,'parent',hp);
%                     plot(time(1:length(jerk{hand})),jerk{hand}(:,direction),'-m');
%                     xlabel('Time (s)');
%                     ylabel('Jerk (cm/s^3)');
%                     xlim([time(1),time(end)]);
                end
            end
        end
    end
    
    assessmentSummary = sprintf('ASSESSMENT SUMMARY\nNumber of targets hit: %d/%d\n',...
        numHit, numTargets);
    fprintf(assessmentSummary);
elseif settings(DATA_TYPE) == KINECT
    LAST_DATA_COL = 66;

    fprintf('This is not Derek''s part of the study!\n');
end

if graph
    refreshFigure();
end
end

