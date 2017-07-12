%------------------------------%
% COMMENTS
% - This file converts binary data and returns the converted values.
%
% INPUT PARAMETERS
% - fileindicator: the file indicator that was used to "open" a binary file.
% - System: PS3 = 0, Kinect = 1
% - bit_skip: bits that are repetitive. This is calculated based on the specific 
%    binary data format. 
% - byte_size: convert bits to byte.
%
% Author: Tina Hung
%------------------------------%

function [Data] = ReadInRawBinData(fileindicator,System, bit_skip,byte_size)

    C=fileindicator;

    % Read in TargetLabel first to truncate other data. Since
    % there might be an extra row of incomplete data at the end. 
    if(System == 1)
        fseek(C,127,'bof');
        TargetLabel=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
        TargetLabel=TargetLabel';
        Size_TL = size(TargetLabel);
    end

    if(System == 0)
        fseek(C,43,'bof');
        TargetLabel = fread(C,[1,inf],'bit8', bit_skip-(byte_size*1));
        TargetLabel = TargetLabel';
        Size_TL = size(TargetLabel);
    end

    fseek(C,18,'bof');
    TimeStamp=fread(C,[1,inf],'bit32',bit_skip-(byte_size*4));
    TimeStamp=TimeStamp(1,1:Size_TL(1))'; % convert into a column matrix. Similar for the operations below.

    fseek(C,22,'bof');
    CursorXY=fread(C,[2,inf],'2*bit16',bit_skip-(byte_size*4));
    CursorXY=CursorXY(1:2,1:Size_TL(1))';

    fseek(C,26,'bof');
    CenteringStatus=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
    CenteringStatus=CenteringStatus(1,1:Size_TL(1))';

    fseek(C,27,'bof');
    PosXYZ_LWrist=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
    PosXYZ_LWrist=PosXYZ_LWrist(1:3,1:Size_TL(1))';

    fseek(C,33,'bof');
    LeftClickState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1)); 
    LeftClickState=LeftClickState(1,1:Size_TL(1))';

    fseek(C,34,'bof');
    LWristVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
    LWristVisualState=LWristVisualState(1,1:Size_TL(1))';

    fseek(C,35,'bof');
    PosXYZ_RWrist=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
    PosXYZ_RWrist=PosXYZ_RWrist(1:3,1:Size_TL(1))';

    fseek(C,41,'bof');
    RightClickState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1)); 
    RightClickState=RightClickState(1,1:Size_TL(1))';

    fseek(C,42,'bof');
    RWristVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
    RWristVisualState=RWristVisualState(1,1:Size_TL(1))';

    if (System == 1) % if the data type is Kinect, then there are more columns to include in the file.
            fseek(C,43,'bof');
            PosXYZ_LHand=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_LHand=PosXYZ_LHand(1:3,1:Size_TL(1))';

            fseek(C,49,'bof');
            LHandVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            LHandVisualState=LHandVisualState(1,1:Size_TL(1))';

            fseek(C,50,'bof');
            PosXYZ_RHand=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_RHand=PosXYZ_RHand(1:3,1:Size_TL(1))';

            fseek(C,56,'bof');
            RHandVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            RHandVisualState=RHandVisualState(1,1:Size_TL(1))';

            fseek(C,57,'bof');
            PosXYZ_LElbow=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_LElbow=PosXYZ_LElbow(1:3,1:Size_TL(1))';

            fseek(C,63,'bof');
            LElbowVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            LElbowVisualState=LElbowVisualState(1,1:Size_TL(1))';

            fseek(C,64,'bof');
            PosXYZ_RElbow=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_RElbow=PosXYZ_RElbow(1:3,1:Size_TL(1))';

            fseek(C,70,'bof');
            RElbowVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            RElbowVisualState=RElbowVisualState(1,1:Size_TL(1))';

            fseek(C,71,'bof');
            PosXYZ_LShoulder=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_LShoulder=PosXYZ_LShoulder(1:3,1:Size_TL(1))';

            fseek(C,77,'bof');
            LShoulderVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            LShoulderVisualState=LShoulderVisualState(1,1:Size_TL(1))';

            fseek(C,78,'bof');
            PosXYZ_RShoulder=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_RShoulder=PosXYZ_RShoulder(1:3,1:Size_TL(1))';

            fseek(C,84,'bof');
            RShoulderVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            RShoulderVisualState=RShoulderVisualState(1,1:Size_TL(1))';

            fseek(C,85,'bof');
            PosXYZ_CShoulder=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_CShoulder=PosXYZ_CShoulder(1:3,1:Size_TL(1))';

            fseek(C,91,'bof');
            CShoulderVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            CShoulderVisualState=CShoulderVisualState(1,1:Size_TL(1))';

            fseek(C,92,'bof');
            PosXYZ_Head=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_Head=PosXYZ_Head(1:3,1:Size_TL(1))';

            fseek(C,98,'bof');
            HeadVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            HeadVisualState=HeadVisualState(1,1:Size_TL(1))';

            fseek(C,99,'bof');
            PosXYZ_Spine=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_Spine=PosXYZ_Spine(1:3,1:Size_TL(1))';

            fseek(C,105,'bof');
            SpineVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            SpineVisualState=SpineVisualState(1,1:Size_TL(1))';

            fseek(C,106,'bof');
            PosXYZ_CHip=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_CHip=PosXYZ_CHip(1:3,1:Size_TL(1))';

            fseek(C,112,'bof');
            CHipVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            CHipVisualState=CHipVisualState(1,1:Size_TL(1))';

            fseek(C,113,'bof');
            PosXYZ_LHip=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_LHip=PosXYZ_LHip(1:3,1:Size_TL(1))';

            fseek(C,119,'bof');
            LHipVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            LHipVisualState=LHipVisualState(1,1:Size_TL(1))';

            fseek(C,120,'bof');
            PosXYZ_RHip=fread(C,[3,inf],'3*bit16',bit_skip-(byte_size*6));
            PosXYZ_RHip=PosXYZ_RHip(1:3,1:Size_TL(1))';

            fseek(C,126,'bof');
            RHipVisualState=fread(C,[1,inf],'bit8',bit_skip-(byte_size*1));
            RHipVisualState=RHipVisualState(1,1:Size_TL(1))';
    end

    if(System == 1) % if the system is Kinect
             Data = cat(2,TimeStamp,CursorXY,CenteringStatus , ...
             PosXYZ_LWrist , LeftClickState , LWristVisualState , ...
             PosXYZ_RWrist , RightClickState , RWristVisualState ,...
             PosXYZ_LHand , LHandVisualState ,...
             PosXYZ_RHand , RHandVisualState ,...
             PosXYZ_LElbow , LElbowVisualState ,...
             PosXYZ_RElbow , RElbowVisualState ,...
             PosXYZ_LShoulder , LShoulderVisualState ,...
             PosXYZ_RShoulder , RShoulderVisualState ,...
             PosXYZ_CShoulder , CShoulderVisualState ,...
             PosXYZ_Head , HeadVisualState , PosXYZ_Spine , SpineVisualState ,...
             PosXYZ_CHip , CHipVisualState , PosXYZ_LHip , LHipVisualState ,...
             PosXYZ_RHip , RHipVisualState , TargetLabel);
     end

    if (System == 0) % if the system is PS3
             Data = cat(2,TimeStamp,CursorXY,CenteringStatus , PosXYZ_LWrist , LeftClickState , LWristVisualState ,...
             PosXYZ_RWrist , RightClickState , RWristVisualState , TargetLabel);
    end
end