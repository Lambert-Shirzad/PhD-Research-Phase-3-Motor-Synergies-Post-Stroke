
clear
clc


%% Create the EMG plot 

% %Calculate a moving window rms to reduce the number of data points
% load('EMG_SS03_Left.mat')
% load('EMG_SS03_Right.mat')
% windowlength = 75; 
% overlap = 5;
% delta = windowlength - overlap;
% indices = 1:delta:length(ProcessedRightSide);
% if length(ProcessedRightSide) - indices(end) + 1 < windowlength
%     indices = indices(1:find(indices+windowlength-1 <= length(ProcessedRightSide), 1, 'last'));
% end
% NewRightSide = zeros(length(indices),size(ProcessedRightSide,2)); %data has 8 columns
% NewLeftSide = zeros(length(indices),size(ProcessedLeftSide,2));
% % Square the samples in the loaded data
% ProcessedRightSide = ProcessedRightSide.^2;
% ProcessedLeftSide = ProcessedLeftSide.^2;
% 
% index = 0;
% for i = indices
%     index = index+1;
%     % Average and take the square root of each window
%     NewRightSide(index,:) = sqrt(mean(ProcessedRightSide(i:i+windowlength-1,:)));
%     NewLeftSide(index,:) = sqrt(mean(ProcessedLeftSide(i:i+windowlength-1,:)));
% end
% 
% %Normalize each channel (column) to its maximum and save as a percentage
% maxRight = max(NewRightSide);
% maxLeft = max(NewLeftSide);
% for i=2:size(NewRightSide,2) %assuming right and left side have the same size
%     NewRightSide(:,i) = 100*NewRightSide(:,i)/maxRight(1,i);
%     NewLeftSide(:,i) = 100*NewLeftSide(:,i)/maxLeft(1,i);
% 
% end
% %Plot
% Ylabels = {'DeltAnt','DeltMed','DeltPos','Biceps','TriLong','TriLat','Brachi','PectMaj'};
% figure
% for i=1:8
%     subplot(8,1,i)
%     plot(NewLeftSide(:,1),NewLeftSide(:,i+1),'r')
%     hold on
%     plot(NewRightSide(:,1),NewRightSide(:,i+1),'k')
%     axis([0 900 0 100])
%     %ylim([0 100])
%     ylabel(Ylabels(i))
%     if i==8
%         xlabel('Time(s)')
%     end
%     if i==1
%         title('EMG Data, Participant S03')
%         legend('Left Arm','Right Arm')
%     end
% end

% %% Create the joint motion data
% 
% load('SS05.mat')
% RightFullSet = [NumericData(:,1:6) NumericData(:,8:12) ];  %10DOFs
% LeftFullSet = [NumericData(:,1:4) NumericData(:,13:14) NumericData(:,16:20)];
% RightFullSet = repmat([0 90 90 90 90 0 90 0 90 10 70],size(RightFullSet,1),1) + RightFullSet; %[90 90 90 90 0 90 0 90 ] from OpenSim model, abs(lower bound) of each DOF
% LeftFullSet = repmat([0 90 90 90 90 0 90 0 90 10 70],size(LeftFullSet,1),1) + LeftFullSet;
% RightFullSet(:,1) = [0:1/30:(length(RightFullSet(:,1))-1)*(1/30)];
% LeftFullSet(:,1) = [0:1/30:(length(LeftFullSet(:,1))-1)*(1/30)];
% %RMS filter
% windowlength = 40; 
% overlap = 30;
% delta = windowlength - overlap;
% indices = 1:delta:length(RightFullSet);
% if length(RightFullSet) - indices(end) + 1 < windowlength
%     indices = indices(1:find(indices+windowlength-1 <= length(RightFullSet), 1, 'last'));
% end
% NewRightSide = zeros(length(indices),size(RightFullSet,2)); %data has 8 columns
% NewLeftSide = zeros(length(indices),size(LeftFullSet,2));
% % Square the samples in the loaded data
% RightFullSet = RightFullSet.^2;
% LeftFullSet = LeftFullSet.^2;
% 
% index = 0;
% for i = indices
%     index = index+1;
%     % Average and take the square root of each window
%     NewRightSide(index,:) = sqrt(mean(RightFullSet(i:i+windowlength-1,:)));
%     NewLeftSide(index,:) = sqrt(mean(LeftFullSet(i:i+windowlength-1,:)));
% end
% 
% NewRightSide = repmat(-[0 90 90 90 90 0 90 0 90 10 70],size(NewRightSide,1),1) + NewRightSide; %[90 90 90 90 0 90 0 90 ] from OpenSim model, abs(lower bound) of each DOF
% NewLeftSide = repmat(-[0 90 90 90 90 0 90 0 90 10 70],size(NewLeftSide,1),1) + NewLeftSide;
% 
% Ylabels={'ShFlEx', 'ShAbAd', 'ShRot', 'ElFlEx', 'ElPrSu', 'WrDev', 'WrFlEx'};
% Ylimits=[-90 130;
%         0 180;
%         -90 20;
%         0 130;
%         -90 90; 
%         -10 25;
%         -70 70];
% % NewLeftSide(:,1) = [0:1/30:(length(NewLeftSide(:,1))-1)*(1/30)];
% % NewRightSide(:,1) = [0:1/30:(length(NewRightSide(:,1))-1)*(1/30)];
% 
% figure
% for i=4:10
%     subplot(7,1,i-3)
%     plot(NewLeftSide(:,1),NewLeftSide(:,i+1),'r')
%     hold on
%     plot(NewRightSide(:,1),NewRightSide(:,i+1),'k')
%     if i==4
%         title('Joint Motion Data, Participant S03')
%         legend('Left Arm','Right Arm')
%     end
%     ylabel(Ylabels(i-3))
%     if i==10
%         xlabel('Time(s)')
%     end
%     xlim([0 900])
%     ylim([Ylimits(i-3,1)  Ylimits(i-3,2)])
% end

%% Create task space motion data
 
NUMERIC=xlsread('Stroke_Subj05_AllParts.xlsx',1); %Numeric now has all the data in it
% set column IDs
TimeStamp = 3;
CursorX = 4;
CursorY = 5;
LWristX = 7;
LWristY = 8;
RWristX = 12;
RWristY = 13;

% % TimePlayed = NUMERIC(end,TimeStamp) - NUMERIC(1,TimeStamp); %in ms
% % FrameTime = TimePlayed / size(NUMERIC,1); %duration of each frame in miliseconds
FrameTime = 33.3; %ms

% %histograms of position
% 
% figure()
% subplot(1,2,1) %everything is being shifted based on the min of the left wrist (PS3 doesn't give centre of the body, so we can't base everything on the location of centere of the body. that's why we are using the left hand.
% hist3([NUMERIC(:,LWristX)+abs(min(NUMERIC(:,LWristX))) NUMERIC(:,LWristY)+abs(min(NUMERIC(:,LWristY)))], 'edges', {[0:1.65:90.75]' [0:1.5:82.5]'}); % set the edges to the biggest range of motion between all subjects
% title(strcat('Left Wrist XY Position Histogram of Subject-', ' ', SubjectID))
% xlabel('X (cm)'); ylabel('Y (cm)');
% subplot(1,2,2)
% hist3([NUMERIC(:,RWristX)+abs(min(NUMERIC(:,LWristX))) NUMERIC(:,RWristY)+abs(min(NUMERIC(:,LWristY)))], 'edges', {[0:1.65:90.75]' [0:1.5:82.5]'});
% title(strcat('Right Wrist XY Position Histogram of Subject-', ' ', SubjectID))
% xlabel('X (cm)'); ylabel('Y (cm)');

%contour plots of position

HistDataL = hist3([NUMERIC(:,LWristY)+abs(min(NUMERIC(:,LWristY))) NUMERIC(:,LWristX)+abs(min(NUMERIC(:,LWristX)))], 'edges', {[0:2.5:65]' [0:2.5:90]'}); %resolution is 2.5 cm
[row, col, NZI] = find(HistDataL); %find non-zero indices, we don't want the indices with zero in them to affect calculation of the outliers
UpperBound = mean(NZI) + 2 * std(NZI);
% TotalL = 0;
for i=1:size(HistDataL,1)
    for j=1:size(HistDataL,2)
        if HistDataL(i,j) > UpperBound %i.e., outlier data point
           HistDataL(i,j) = UpperBound; %adjust the original value to the allowable upper bound
        end
%         TotalL = TotalL + HistDataL(i,j);
    end
end


HistDataR = hist3([NUMERIC(:,RWristY)+abs(min(NUMERIC(:,LWristY))) NUMERIC(:,RWristX)+abs(min(NUMERIC(:,LWristX)))], 'edges', {[0:2.5:65]' [0:2.5:90]'}); %resolution is 2.5 cm
[row, col, NZI] = find(HistDataR); %find non-zero indices, we don't want the indices with zero in them to affect calculation of the outliers
UpperBound = mean(NZI) + 2 * std(NZI);
% TotalR = 0;
for i=1:size(HistDataR,1)
    for j=1:size(HistDataR,2)
        if HistDataR(i,j) > UpperBound %i.e., outlier data point
           HistDataR(i,j) = UpperBound; %adjust the original value to the allowable upper bound
        end
%         TotalR = TotalR + HistDataR(i,j);
    end
end

HistDataCursor = hist3([NUMERIC(:,CursorY) NUMERIC(:,CursorX)], 'edges', {[0:30:750]' [0:30:1350]'}); %resolution is 2.5 pixels
[row, col, NZI] = find(HistDataCursor); %find non-zero indices, we don't want the indices with zero in them to affect calculation of the outliers
UpperBound = mean(NZI) + 2 * std(NZI);
% TotalR = 0;
for i=1:size(HistDataCursor,1)
    for j=1:size(HistDataCursor,2)
        if HistDataCursor(i,j) > UpperBound %i.e., outlier data point
           HistDataCursor(i,j) = UpperBound; %adjust the original value to the allowable upper bound
        end
%         TotalR = TotalR + HistDataR(i,j);
    end
end


% if max(HistDataL/TotalL) > max(HistDataR/TotalR)
%     MAXIMUM = max(HistDataL/TotalL);
% else
%     MAXIMUM = max(HistDataR/TotalR);
% end;

figure()
subplot(3,1,1)
contour([0:2.5:90]', [0:2.5:65]', HistDataL * FrameTime, 20, 'LineWidth', 2); %show time spent at each point
xlabel('X (cm)'); ylabel('Y (cm)');
colormap(gray)
colorbar('Ticks',[2000 4000 6000 8000 10000 12000],...
    'TickLabels',['2000',sprintf('\n'),'4000',sprintf('\n'),'6000',sprintf('\n'),'8000',sprintf('\n'),'10000',sprintf('\n'),'12000']);
title('Left Wrist Motion, Participant S03')
axis xy
subplot(3,1,2)
contour([0:2.5:90]', [0:2.5:65]', HistDataR * FrameTime, 20, 'LineWidth', 2); %
xlabel('X (cm)'); ylabel('Y (cm)');
colormap(gray)
colorbar('Ticks',[2000 4000 6000 8000 10000 12000],...
    'TickLabels',['2000',sprintf('\n'),'4000',sprintf('\n'),'6000',sprintf('\n'),'8000',sprintf('\n'),'10000',sprintf('\n'),'12000']);
title('Right Wrist Motion, Participant S03')
axis xy
subplot(3,1,3)
contour([0:30:1350]', [0:30:750]', HistDataCursor * FrameTime, 20, 'LineWidth', 2); %
xlabel('X (pixels)'); ylabel('Y (pixels)');
colormap(gray)
colorbar %use colorbar('Ticks',[0:MAXIMUM/5:MAXIMUM]) in MATLAB2014 in order not to manually set the maximum value between the two graphs
title('Cursor Motion, Participant S03')
axis xy

% %density plots of position
% figure()
% subplot(3,1,1)
% imagesc([0:2.5:90]', [0:2.5:65]', HistDataL, [1 100]) 
% xlabel('X (cm)'); ylabel('Y (cm)');
% colormap(bone)
% colorbar
% title(strcat('Left Wrist XY Probability Plot for Subject-', ' ', SubjectID))
% axis xy
% 
% subplot(3,1,2)
% imagesc([0:2.5:90]', [0:2.5:65]', HistDataR, [1 100])
% xlabel('X (cm)'); ylabel('Y (cm)');
% colormap(bone)
% colorbar
% title(strcat('Right Wrist XY Probability Plot for Subject-', ' ', SubjectID))
% axis xy
% 
% subplot(3,1,3)
% imagesc([0:25:1350]', [0:25:750]', HistDataCursor, [1 100])
% xlabel('X (cm)'); ylabel('Y (cm)');
% colormap(bone)
% colorbar
% title(strcat('Right Wrist XY Probability Plot for Subject-', ' ', SubjectID))
% axis xy