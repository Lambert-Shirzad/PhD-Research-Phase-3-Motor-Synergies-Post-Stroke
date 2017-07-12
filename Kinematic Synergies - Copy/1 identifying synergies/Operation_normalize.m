%Operation_normalize([1,2,5,6,9,10,11,12,14,15,17,18,19,20,21])
function Operation_normalize(SubjectIDs, StrongHand)
    
    for subjectcounter = 1:size(SubjectIDs,2)

        if SubjectIDs(subjectcounter) < 10
            SubjID = strcat('0', num2str(SubjectIDs(subjectcounter)));
        else
            SubjID = num2str(SubjectIDs(subjectcounter));
        end

        load(strcat('SS', SubjID, '.mat'))
        NumericData(:,2) = NumericData(:,2) + sign(mean(NumericData(:,2)))*mean(NumericData(:,2));
        NumericData(:,3) = NumericData(:,3) + sign(mean(NumericData(:,3)))*mean(NumericData(:,3));
        NumericData(:,4) = NumericData(:,4) + sign(max(NumericData(:,4)))*max(NumericData(:,4));
%         RightFullSet = [NumericData(:,2:6) NumericData(:,8:12) ]; %RightFullSet = [FullSet(:,2:6) FullSet(:,8:10)]; %10DOFs
%         LeftFullSet = [NumericData(:,2:4) NumericData(:,13:14) NumericData(:,16:20)];%LeftFullSet = [FullSet(:,2:4) FullSet(:,13:14) FullSet(:,16:18)]; %t=0s is not included in FullSet (first row is t=1/30s)

        if StrongHand == 1 %right hand
            DOF = 10;
            %load the data 
            NumericData(:,8:12) = NumericData(:,8:12) + 4.5*rand(size(NumericData(:,8:12)))
            ProcessedRightSide(:,2:9) = ProcessedRightSide(:,2:9) + 4.5*rand(size(ProcessedRightSide(:,2:9)));
            ProcessedLeftSide(:,2:9) = ProcessedLeftSide(:,2:9) + 4.5*rand(size(ProcessedLeftSide(:,2:9)));

            for i = 2:DOF+1 %1st column is time
                ProcessedRightSide(:,i) = 100*ProcessedRightSide(:,i) / max(ProcessedRightSide(:,i)); 
                ProcessedLeftSide(:,i) = 100*ProcessedLeftSide(:,i) / max(ProcessedLeftSide(:,i)); 
            end
        else 
            
        end
        
        
        
        save(strcat('Processed_Subj_', SubjID, '_Right.mat'), 'ProcessedRightSide')
        save(strcat('Processed_Subj_', SubjID, '_Left.mat'), 'ProcessedLeftSide')
        
%         save(strcat('Processed_Subj_02_Right.mat'), 'ProcessedRightSide')
%         save(strcat('Processed_Subj_02_Left.mat'), 'ProcessedLeftSide')
        
    end