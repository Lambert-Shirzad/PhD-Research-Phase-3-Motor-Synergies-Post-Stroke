%------------------------------%
% COMMENTS
% - This function filters the raw data stored in the .xlsx file in the dirSource folder.
%    The output of this function is another worksheet named 'filtered' in
%    the .xlsx file.
% - FilterNoVisual.m filters the data that is:
% (1) Not in the camera view. For the PS3 system, specified seconds of data
%        after the controller not in sight will be also filtered out due to
%        observed data jump.
% (2) Before the first click or first centering motion. This is used as
%        an indicator that the user starts the game.
% - This FilterNoVisual.m function is also used to calculate the total
%    time played, the distance travelled for all the .bin files in the
%    dirSource folder, and the time the user spent using the Mirror Mode
%    and the Wheel Mode. This output is only presented in the MATLAB
%    window.
% - This function calls OverallMovement.m to calculate the total time
%    played and total distance travelled for each hand for each file.
%
% INPUT PARAMETERS
% - dirSource: the folder where the .xlsx files you wish to process is stored in.
%    ** note: this should be the dirResult folder that is fed into the
%    FEATHERS_Motion_RawBinData_Process.m
%
% OUTPUT TO EXCEL
% - filtered data will be saved on a worksheet named "filtered". It will
%    have the same format as the raw data on 'Sheet 1'. 
%
% Author: Tina Hung
%------------------------------%

function y = FilterNoVisual(dirSource)
    warning('off', 'MATLAB:xlswrite:AddSheet');

    files = dir(fullfile(dirSource, '*.xlsx') );

    %%%% SET PARAMETERS %%%%
    AfterNoVisualFilter = 0.5; % this is the seconds to filter out after the not tracked data for PS3.
    SystemFrameRate = 30; % this is the system frame rate operates at x Hz. PS3 operates around 30-60 Hz.
    X_Ratio = 1.43;
    Y_Ratio = 1.55;
    Z_Ratio = 1.11; 
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    % This is to calculate the accumulated time play and distance travelled for
    % each person within a certain amount of time. In our case, this is to
    % generate the weekly report.
    TotalTimePlayed = 0;
    TotalLeftDistanceTravelled = 0;
    TotalRightDistanceTravelled = 0;
    TotalTimeWheelMode = 0;
    TotalTimeMirrorMode = 0;    
    
    % this flag is to indicate if each file contains wanted data. Default
    % value is true (the file is not wanted). 
    isFileUnwanted = 1; 

    for filecounter = 1:length(files)
        filename=files(filecounter).name;
        fprintf('Filtering %s...',filename);
        filename= fullfile(dirSource,filename);

        [NUMERIC,~,RAW] = xlsread(filename,'Sheet1');

        CursorX=NUMERIC(:,4); %4 -> E column

        % check for NaN values
        NaNvalue=isnan(CursorX);
        SizeNaN=size(NaNvalue);

        SystemSettings = RAW(5:15,1:2); %A5:B15
        AddTitles={'TimePlayed (s)','LeftTotalDistance','RightTotalDistance'}';
        MotionMode = NUMERIC(8,1); %B9
        DataType = NUMERIC(5,1); %B6
        
        if (DataType == 1 || DataType == 3) % if the data type is Kinect, then there are more columns to include in the file.
            System = 1;
        end

        if (DataType == 0 || DataType == 2) % if the data type is PS3, then there are less columns to include in the file.
            System = 0;
        end
        
        AllData = NUMERIC(:,3:end); %all of the play data

        % apply ratios and convert the data to cm
        AllData(1:end,5) = AllData(1:end,5)/(X_Ratio*10); %Left_xpos
        AllData(1:end,6) = AllData(1:end,6)/(Y_Ratio*10); %Left_ypos
        AllData(1:end,7) = AllData(1:end,7)/(Z_Ratio*10); %Left_zpos
        AllData(1:end,10) = AllData(1:end,10)/(X_Ratio*10); %Right_xpos
        AllData(1:end,11) = AllData(1:end,11)/(Y_Ratio*10); %Right_ypos
 	    AllData(1:end,12)  = AllData(1:end,12)/(Z_Ratio*10);  %Right_zpos  
       
        CenteringState=AllData(1:end,4);
        Leftclickstate=AllData(1:end,8);
        LWristvisualstate=AllData(1:end,9);
        Rightclickstate=AllData(1:end,13);
        RWristvisualstate=AllData(1:end,14);
        
        % Initializing counters & flags
        StartData=1;
        Enddata=SizeNaN(1);
        StartRecordData=1;
        EndRecordData=1;
        firstclick=0;
        TimePlayed_AllSection = 0;
        i=1;
        k=1; %counter k to count the starting of each rightclicked section
        novisualwithin = 0;     
        
        if(filecounter ~= 1 && isFileUnwanted == 0)
            Data_accumulated(:,:)=[]; % Initialize the Data_accumulated matrix when processing multiple files
            recorddata=zeros(Enddata,1);
        end

        % Add a worksheet of filtered data in the current file. 
        if(System==0)
             DataLabel = {'TimeStamp (ms)','Cursor x','Cursor y','Centeringstate','Left_Wrist x','Left_Wrist y','Left_Wrist z','LeftClickState','LeftVisualState','Right_Wrist x','Right_Wrist y','Right_Wrist z','RightClickState','RightVisualState','TargetLabel'};
        elseif(System==1)
            DataLabel = {'TimeStamp (ms)','CursorX','CursorY','CenteringStatus',...
            'PosX_LWrist','PosY_LWrist','PosZ_LWrist','LeftClickState','LWristVisualState',...
            'PosX_RWrist','PosY_RWrist','PosZ_RWrist','RightClickState','RWristVisualState',...
            'PosX_LHand','PosY_LHand','PosZ_LHand','LHandVisualState',...
            'PosX_RHand','PosY_RHand','PosZ_RHand','RHandVisualState',...
            'PosX_LElbow','PosY_LElbow','PosZ_LElbow','LElbowVisualState',...
            'PosX_RElbow','PosY_RElbow','PosZ_RElbow','RElbowVisualState',...
            'PosX_LShoulder','PosY_LShoulder','PosZ_LShoulder','LShoulderVisualState',...
            'PosX_RShoulder','PosY_RShoulder','PosZ_RShoulder','CShoulderVisualState',...
            'PosX_CShoulder','PosY_CShoulder','PosZ_CShoulder','CShoulderVisualState',...
            'PosX_Head','PosY_Head','PosZ_Head','HeadVisualState','PosX_Spine','PosY_Spine','PosZ_Spine','SpineVisualState',...
            'PosX_CHip','PosY_CHip','PosZ_CHip','CHipVisualState','PosX_LHip','PosY_LHip','PosZ_LHip','LHipVisualState',...
            'PosX_RHip','PosY_RHip','PosZ_RHip','RHipVisualState','TargetLabel'};
        end
        
        % this while loop is to indicate which data row to filter. The decision
        % is stored in recorddata matrix. 
        while i <= Enddata
            recorddata(i)= 1;

            % Look for the row where the user did a first left click or
            % centering motion
            if((i~=1) && (firstclick == 0) && ((System == 0 && (Leftclickstate(i) == 2 || Rightclickstate(i) == 2||Leftclickstate(i) == 1 || Rightclickstate(i) == 1)) || (System == 1 && (Leftclickstate(i) == 1 || Rightclickstate(i) == 1 || CenteringState(i) == 1))))
                firstclick = 1;        
            end

%             if(firstclick == 0)
%                 recorddata(i)=0;
%             end

            if (i<=Enddata && (System == 0 && LWristvisualstate(i)== 0) || (System == 1 && ( LWristvisualstate(i)== 0 || LWristvisualstate(i)== 1)))
                recorddata(i)=0; % 1:true, 0:false
            end 

            if (i<=Enddata && (System == 0 && RWristvisualstate(i)== 0) || (System == 1 && ( RWristvisualstate(i)== 0 || RWristvisualstate(i)== 1)))
                recorddata(i)=0; % 1:true, 0:false
            end 

            if(System == 1)
                i=i+1; 
             elseif(System == 0 && firstclick == 0)
                i=i+1;
             elseif(System == 0 && firstclick == 1) % for PS3 system
                % below is to check when controller one changed from not
                % tracked to tracked, did controller one changed from not 
                % tracked to tracked and did the other controller also changed
                % from not tracked to tracked within the rows that should
                % be deleted (based on controller one).
                if(i+round(AfterNoVisualFilter*SystemFrameRate)-1<=Enddata && ((LWristvisualstate(i)==0&&LWristvisualstate(i+1)==1)||(RWristvisualstate(i)==0 && RWristvisualstate(i+1)==1)))
                    first_i = i+1;
                    prev_i = i+1;
                    checknext = i;

                    if(LWristvisualstate(i)==0 && LWristvisualstate(i+1)==1)
                        while((checknext+1 <= prev_i+round(AfterNoVisualFilter*SystemFrameRate))&&checknext+1<=Enddata)
                            % look for the row where the other controller
                            % changed from not tracked to tracked.
                            if((RWristvisualstate(checknext) == 0 && RWristvisualstate(checknext+1)==1)||(checknext+1 ~= first_i && LWristvisualstate(checknext) == 0 && LWristvisualstate(checknext+1)==1))
                                prev_i = checknext+1;
                                novisualwithin = checknext+1;
                            end                          
                            checknext = checknext+1;
                        end
                    elseif(RWristvisualstate(i)==0 && RWristvisualstate(i+1)==1)
                        while((checknext+1 <= prev_i+round(AfterNoVisualFilter*SystemFrameRate))&&checknext+1<=Enddata)
                            if((LWristvisualstate(checknext) == 0 && LWristvisualstate(checknext+1) == 1)||(checknext+1 ~= first_i && RWristvisualstate(checknext) == 0 && RWristvisualstate(checknext+1)==1))
                                prev_i = checknext+1;
                                novisualwithin = checknext+1;
                            end
                            checknext = checknext+1;
                        end
                    end

                    if(novisualwithin ~= 0) % if the other controller did not have 0->1 visual change within the "planned-to-delete" data
                        i=novisualwithin+round(AfterNoVisualFilter*SystemFrameRate);
                    else
                        i=i+1+round(AfterNoVisualFilter*SystemFrameRate); 
                    end
                    if(i>Enddata)
                        i=Enddata;
                    end
                    recorddata(first_i:i) = 0;
                    novisualwithin = 0;
                elseif(i+round(AfterNoVisualFilter*SystemFrameRate)-1>Enddata && i+1 <= Enddata &&  ((LWristvisualstate(i)==0 && LWristvisualstate(i+1)==1)||(RWristvisualstate(i)==0 && RWristvisualstate(i+1)==1)))
                    recorddata(i:Enddata) = 0;
                     i=Enddata+1;
                else
                    i=i+1;
                end 
            end
            
            if(i==Enddata && (LWristvisualstate(Enddata)==0 ||RWristvisualstate(Enddata)==0))
                    recorddata(Enddata) = 0;
            end
        end

        firstloop=0;
        % this while loop is to look at recorddata matrix and decide which
        % sections should be recorded and put into the Data_accumulated
        % matrix.
        while k <= Enddata
            if k == 1
                firstloop=1; % this is for the counter to decide if it is the first time that the program runs this loop.
            end

            while (k <= Enddata && recorddata(k)==0)
                k=k+1;
            end
            StartRecordData=k;

            while (k <= Enddata && recorddata(k)==1)
                k=k+1;
            end
            EndRecordData=k-1;   


            if StartRecordData < EndRecordData
                if firstloop == 1
                    Data_accumulated=AllData(StartRecordData:EndRecordData,1:end);
                    TimePlayed_AllSection = (AllData(EndRecordData,1)-AllData(StartRecordData,1))/1000; % convert to seconds
                else    
                    Data_addon=AllData(StartRecordData:EndRecordData,1:end);
                    TimePlayed_AllSection = TimePlayed_AllSection + (AllData(EndRecordData,1)-AllData(StartRecordData,1))/1000; % convert to seconds
                    Data_accumulated=[Data_accumulated;Data_addon];                 
                end
                firstloop=0; 
            end
        end
        
        isFileUnwanted = 1;
        % if the data in this whole file is not desired (i.e., no visual,
        % no first click, etc.), then do not account it nor output it.
        if(sum(recorddata) ~= 0)
            fprintf('Good data...');
            
            % some/all data in this file are wanted
            isFileUnwanted = 0;
                        
            % To speed up Excel writing [1/2]
            Excel = actxserver ('Excel.Application'); 
            if ~exist(filename,'file') 
                ExcelWorkbook = Excel.workbooks.Add; 
                ExcelWorkbook.SaveAs(filename);
                ExcelWorkbook.Close(false); 
            end 
            invoke(Excel.Workbooks,'Open',filename);
            
            % output labels to the excel sheet
            xlswrite1(filename,DataLabel,'filtered','D1');
            xlswrite1(filename, SystemSettings,'filtered','A5');
            xlswrite1(filename,AddTitles,'filtered','A16');

            % write the filtered data into the Excel sheet.
            xlswrite1(filename,Data_accumulated,'filtered','D2');

            % calculate time played and distance travelled for each .xlsx file
            [LeftMovedDistance,RightMovedDistance]=OverallMovement(Data_accumulated); 
            xlswrite1(filename,[TimePlayed_AllSection,LeftMovedDistance,RightMovedDistance]','filtered','B16');
            
            % To speed up Excel writing [2/2]
            invoke(Excel.ActiveWorkbook,'Save'); 
            Excel.Quit 
            Excel.delete 
            clear Excel
            
            % below is to calculate total time played, distance travelled, and
            % motion mode time distribution for all the files in the dirSource
            % folder.
            if(MotionMode == 0)
                TotalTimeMirrorMode = TotalTimeMirrorMode+TimePlayed_AllSection;
            elseif(MotionMode == 1)
                TotalTimeWheelMode = TotalTimeWheelMode+TimePlayed_AllSection;
            end

            TotalTimePlayed=TotalTimePlayed+TimePlayed_AllSection;
            TotalLeftDistanceTravelled = TotalLeftDistanceTravelled+LeftMovedDistance;
            TotalRightDistanceTravelled = TotalRightDistanceTravelled+RightMovedDistance;
        else
            fprintf('Bad data...');
        end
        
        fprintf('DONE\n');
    end

fclose('all');

% print overall summary in the MATLAB window.
fprintf('\tTotal Time Played (s): %i\n', TotalTimePlayed);
fprintf('\tTotal Time using MIRROR Mode (s): %i\n', TotalTimeMirrorMode);
fprintf('\tTotal Time using WHEEL Mode (s): %i\n', TotalTimeWheelMode);
fprintf('\tMirror Mode Percentage: %2.1f\n', TotalTimeMirrorMode/TotalTimePlayed*100);
fprintf('\tWheel Mode Percentage: %2.1f\n', TotalTimeWheelMode/TotalTimePlayed*100);
fprintf('\tTotal Left Wrist Distance (cm): %2.1f\n', TotalLeftDistanceTravelled);
fprintf('\tTotal Right Wrist Distance (cm): %2.1f\n', TotalRightDistanceTravelled);

y = [TotalTimePlayed; TotalTimeMirrorMode; TotalTimeWheelMode;...
     TotalTimeMirrorMode/TotalTimePlayed*100; TotalTimeWheelMode/TotalTimePlayed*100;...
     TotalLeftDistanceTravelled; TotalRightDistanceTravelled];
end