%------------------------------%
% COMMENTS
% - This file is for processing FEATHERS Motion .bin data for both 
%    the Kinect and PS3 system, as well as the assessment files for 
%    both systems.
% - This is the main processing file that calls ReadInRawBinData.m,
%    FilterNoVisual.m file to process raw data .bin files into an Excel
%    Worksheet that contains a worksheet 'Sheet1' with the unfiltered 
%    raw data, and another worksheet 'filtered' with filtered data.
%    
% PRE-PROCESSING OF THE INPUT FILE
% - The data input file should have the same template as the
%   "Log Data Template_FINAL.xlsx"
%
% INPUT PARAMETERS
% - dirSource: the folder where the files you wish to process is stored in.
% - dirResult: the folder where you want the output files to be.
% - Sample directories should be strings. 
%    i.e., dirSource ='C:\bin_testing\' or dirResult = 'C:\bin_testing\result\';
%
% OUTPUT FILE
% - The processed file will be a .xlsx file output in the dirResult folder. The 
%    output file name is the same as the binary raw file.  This Excel file contains 
%    a worksheet 'Sheet1' with the unfiltered raw data, and another worksheet 
%    'filtered' with filtered data.
%
% Author: Tina Hung
%------------------------------%


function y= FEATHERS_Motion_RawBinData_Process(dirSource, dirResult)

MAX_EXCEL_ROWS = 1048576;

% Create a list of files in the dirSource that ends with .bin
files = dir(fullfile(dirSource, '*.bin') );

% Constants. The values are calculated based on the logged data bit sizes
% for different system. If Log Data Template_FINAL.xlsx is changed, then
% this needs to be modified. 
byte_size=8; % 1 byte = 8 bits.
bit_skip=880; % this is for the Kinect
PS3_bit_skip=208; % this is for the PS3.
% initialize system as value 2. 0=PS3 system and 1=Kinect system.
System = 2;  

    for filecounter = 1:length(files)
        % Extract the name of the bin file to use it for output Excel
        % file name.
        filename=files(filecounter).name(1:end-4);
        binfile = fullfile(dirSource,strcat(filename,'.bin'));
        C = fopen(binfile);

        fprintf('Reading %s bin file...', filename);

        % Start from the beginning of the .bin file, read in the
        % settings. The definition for each setting value is in the
        % "Log Data Template_FINAL.xlsx" file.
        fseek(C,0,'bof'); 
        SubjectID=fread(C,1,'bit64');
        DataType=fread(C,1,'bit8');
        ClickingHand=fread(C,1,'bit8'); 
        ClickingMode=fread(C,1,'bit8'); 
        MotionMode=fread(C,1,'bit8');
        EasyCentering = fread(C,1,'bit8');
        Cursor=fread(C,1,'bit8');
        Centering=fread(C,1,'bit8');
        xoff=fread(C,1,'bit8');
        yoff=fread(C,1,'bit8');
        Rumble=fread(C,1,'bit8');

        % Determine which data type is each .bin file for reading in
        % the raw binary data.
        if (DataType == 1 || DataType == 3) % if the data type is Kinect, then there are more columns to include in the file.
            System = 1;
            [AllData] = ReadInRawBinData(C,System, bit_skip,byte_size);
        end

        if (DataType == 0 || DataType == 2) % if the data type is PS3, then there are less columns to include in the file.
            System = 0;
            [AllData] = ReadInRawBinData(C,System, PS3_bit_skip,byte_size);
        end
        fprintf('DONE\n');

        % Putting the raw data into an output Excel sheet.
        Titles = {'SubjectID', 'DataType','ClickingHand','ClickingMode','MotionMode', 'EasyCentering', 'Cursor (%)','Centering (%)','xoff (cm)','yoff (cm)','Rumble'}';
        Setting=[SubjectID,DataType,ClickingHand, ClickingMode,MotionMode,EasyCentering,Cursor,Centering,xoff,yoff,Rumble]';

        % if the data is Kinect
        if (DataType == 1 || DataType == 3) 
        ColumnTitles = {'TimeStamp (ms)','CursorX','CursorY','CenteringStatus',...
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

        % if the data is PS3
        if (DataType == 0 || DataType == 2)  
        ColumnTitles = {'TimeStamp (ms)','CursorX','CursorY','CenteringStatus',...
            'PosX_LWrist','PosY_LWrist','PosZ_LWrist','LeftClickState','LWristVisualState',...
            'PosX_RWrist','PosY_RWrist','PosZ_RWrist','RightClickState','RWristVisualState','TargetLabel'};    
        end

        %prepare to write to Excel files
        maxNumRows = floor(MAX_EXCEL_ROWS/2); %this can't be too big for memory purposes
        [numRows,~] = size(AllData);
        numFiles = floor(numRows/maxNumRows) + 1;

        %split all data into a sub matrices
        lastFileRows = mod(numRows, maxNumRows);
        M = maxNumRows*ones(1,numFiles);
        M(end) = lastFileRows;
        AllDataSplit = mat2cell(AllData,M);

        for i=1:numFiles
            if numFiles == 1
                outputfile = fullfile(dirResult,sprintf('%s.xlsx',filename));
            else
                outputfile = fullfile(dirResult,sprintf('%s_%d.xlsx',filename,i));
            end

            % Write the data into the output Excel file.
            fprintf('Writing %s to Excel...', outputfile);

            % To speed up Excel writing [1/2]
            Excel = actxserver ('Excel.Application'); 
            if ~exist(outputfile,'file') 
                ExcelWorkbook = Excel.workbooks.Add; 
                ExcelWorkbook.SaveAs(outputfile); 
                ExcelWorkbook.Close(false);
            end
            invoke(Excel.Workbooks,'Open',outputfile);

            xlswrite1(outputfile,Titles,'Sheet1','A5');
            xlswrite1(outputfile,Setting,'Sheet1','B5');
            xlswrite1(outputfile,ColumnTitles,'Sheet1','D1');
            xlswrite1(outputfile, AllDataSplit{i}, 'Sheet1','D2');

            % To speed up Excel writing [2/2]
            invoke(Excel.ActiveWorkbook,'Save'); 
            Excel.Quit 
            Excel.delete 
            clear Excel

            fprintf('DONE\n');
        end

        fclose('all');
    end

    % After converting all the raw .bin files to readable Excel files. Call
    % FilterNoVisual.m to filter the raw data that is:
    % (1) Not in the camera view. For the PS3 system, specified seconds of data
    % after the controller not in sight will be also filtered out due to
    % observed data jump.
    % (2) Before the first click or first centering motion. This is used as
    % an indicator that the user starts the game.
    %
    % The FilterNoVisual.m function is also used to calculate the total
    % time played and distance travelled for all the .bin files in the
    % dirSource folder.
    pause(1); %allowing time for temporary .xlsx files to disappear
    FilterNoVisual(dirResult);
end
