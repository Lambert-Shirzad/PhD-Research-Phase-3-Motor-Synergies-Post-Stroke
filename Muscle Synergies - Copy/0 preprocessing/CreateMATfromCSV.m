% This script takes in raw EMG data from 16 channels (8 channels from each
% side of the body) in CSV format, and saves the data in .mat format. 


% 20160321 Written by Navid Shirzad
% 20170104 Modified by Navid Lambert-Shirzad


function CreateMATfromCSV(SubjectIDs)
    CurrentDirectory = cd;
    for subjectcounter = 1:size(SubjectIDs,2)

        if SubjectIDs(subjectcounter) < 10
            SubjID = strcat('0', num2str(SubjectIDs(subjectcounter)));
        else
            SubjID = num2str(SubjectIDs(subjectcounter));
        end
        
        for sessions = 1:5
            xlsxDataFileName = strcat('SS', SubjID, '_P', num2str(sessions), '.csv');          
            xlsxFileString = strcat(CurrentDirectory, '\', xlsxDataFileName);
            [NUMERIC, TEXT] = xlsread(xlsxFileString); %Numeric now has all the data in it

            if sessions == 1
                rightside = NUMERIC(1:370001,1:9); %ignoring everything after 185s
                leftside = [NUMERIC(1:370001,1) , NUMERIC(1:370001,10:17)];
            else
                rightside = vertcat(rightside, NUMERIC(1:370001,1:9));
                leftside = vertcat(leftside, [NUMERIC(1:370001,1) , NUMERIC(1:370001,10:17)]);
            end
            sessions
        end
        
        size(rightside)
        rightside(:,1) = [0:370000*5+4]*0.0005;
        leftside(:,1) = [0:370000*5+4]*0.0005;
        
        
        % save data in mat file
        OutputRight = strcat('SS', SubjID, '_Right.mat');
        OutputLeft = strcat('SS', SubjID, '_Left.mat');
        save(OutputRight, 'rightside');
        save(OutputLeft, 'leftside');
        
    end
    
    HEADERS = {'time','Delt_Ant','Delt_Med','Delt_Post','Biceps','Triceps_Long','Triceps_Lat','Brachi','Pect-Maj'};
    save('EMG_Headers.mat', 'HEADERS');
    
