% Phase 3: compare synergies to find merged/fractionated synergies

% 20170314 Written by Navid Lambert-Shirzad

function Compare_Synergies_Merge_Fractinate
    clc
    load('KinHealthyTemplate.mat')
    DOF = 10;
    IDs = [1:14];
    FM = [40,58,13,49,36,37,32,23,29,35,18,29]; %Fugl-Meyer Score
    RPS = [28,36,11,34,24,32,17,8,17,25,8,18]; %Reaching Performance Score
    TSS = [16,23,47,74,16,74,39,110,46,74,25,302]; %time since stroke (months)
    NumParticipants = size(IDs,2);
    
    CurrentDirectory = cd;
    CurrentDirectoryUp = strrep(CurrentDirectory,'compare the two sides',''); 
    OrigSynergiesFolder = strcat(CurrentDirectoryUp, '1 identifying synergies\');
    
    Num_Preserved = zeros(NumParticipants,1);
    Num_Merged = zeros(NumParticipants,1);
    for i=1:NumParticipants
        if IDs(i) < 10
            SubjID = strcat('0', num2str(IDs(i)));
        else
            SubjID = num2str(IDs(i));
        end
        load(strcat(OrigSynergiesFolder,'S', SubjID, '_Strong_Synergies.mat' )); 
        load(strcat(OrigSynergiesFolder,'S', SubjID, '_Weak_Synergies.mat' )); 
        if SubjStrongHand == 'R'
            ndim_Strong(i,1) = ndim_R;
            ndim_Weak(i,1) = ndim_L;
            Synergies_Strong = Synergies_R;
            Synergies_Weak = Synergies_L;
        else
            ndim_Strong(i,1) = ndim_L;
            ndim_Weak(i,1) = ndim_R;
            Synergies_Strong = Synergies_L;
            Synergies_Weak = Synergies_R;
        end
        
        i
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%merging of synergies%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        for j=1:ndim_Weak(i,1)
%             X(:,j) = lsqnonneg(Synergies_Strong',Synergies_Weak(j,:)');
            X(:,j) = lsqnonneg(Healthy_Synergy_Template',Synergies_Weak(j,:)');
            for k=1:size(X(:,j),1)
                if X(k,j)<0.2
                    X(k,j)=0;
                end
            end
            %at least 2 synergies are merging (1 to 1 is not merging)
            if size(find(X(:,j)),1) <2
                X(:,j)=zeros(size(X(:,j)));
            end              
            %similarity(j) = Synergies_Weak(j,:)*(Synergies_Strong'*X(:,j)/norm(Synergies_Strong'*X(:,j)));
            similarity(j) = Synergies_Weak(j,:)*(Healthy_Synergy_Template'*X(:,j)/norm(Healthy_Synergy_Template'*X(:,j)));
            if ceil(similarity(j)*100) >= 90
                Num_Merged(i)=Num_Merged(i)+1;
            end
        end
        
        X
        similarity
        clear X
        clear similarity

        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%fractionantion of synergies%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for j=1:3%ndim_Strong(i,1) %
%             X(:,j) = lsqnonneg(Synergies_Weak',Synergies_Strong(j,:)');
            X(:,j) = lsqnonneg(Synergies_Weak',Healthy_Synergy_Template(j,:)');
            for k=1:size(X(:,j),1)
                if X(k,j)<0.2
                    X(k,j)=0;
                end
            end
%             similarity(j) = Synergies_Strong(j,:)*(Synergies_Weak'*X(:,j)/norm(Synergies_Weak'*X(:,j)));
            similarity(j) = Healthy_Synergy_Template(j,:)*(Synergies_Weak'*X(:,j)/norm(Synergies_Weak'*X(:,j)));
        end
        X
        similarity
        clear X
        clear similarity
        
        
        %%%%%%%%%%%%%%%%%%%%%%%
        %%%Preserved Synergies%%%
        %%%%%%%%%%%%%%%%%%%%%%%
        subjOne = Healthy_Synergy_Template;         
        subjTwo = Synergies_Weak;
        DP_All = zeros(3, ndim_Weak(i,1)); %DP for dot product
        for k = 1:3 
            for j = 1:ndim_Weak(i,1)
                DP_All(k,j) = subjOne(k,:)*subjTwo(j,:)'; 
            end
        end
        %matching on the rows
        DP_All
        NumMatched = 0;
        
        while NumMatched < ndim_Weak(i,1)
            for RowNum = 1:3
                %find the max DP in the row
                [MaxDPRow, IndRow] = max(DP_All(RowNum,:));
                %check to see if the max in row is also max in column
                %if so it is a match
                [~, IndCol] = max(DP_All(:,IndRow));
                if MaxDPRow ~= 0 %this row is not previously matched
                    if IndCol == RowNum
                        %this is a match
                        if ceil(MaxDPRow*100) >= 90%0.87 %similarity_range_DP
                            Num_Preserved(i) = Num_Preserved(i) + 1;
                            Preserved_vectors(i,RowNum)=IndCol;
                        end
                        NumMatched = NumMatched+1;                       
                        %temp_DP(RowNum, SubjCount2) = MaxDPRow;%temp_DP(RowNum)+MaxDPRow;
                        DP_All(RowNum,:) = zeros(size(DP_All(RowNum,:)));
                        DP_All(:,IndRow) = zeros(size(DP_All(:,IndRow)));
                        vector_matches(RowNum)=IndRow;
                        %RowNum
                        %IndRow
                    end
                    if NumMatched == ndim_Weak(i,1)
                        break
                    end
                end
            end    
        end
        vector_matches
            
        if i==9 %example graph for merging 
            figure()
            %add the template to the figure
            subplot(2, 3, 1)
            barh(Healthy_Synergy_Template(1,:), 'k')
            title('H#1', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            yt = get(gca, 'YTick');
            set(gca, 'YTick', yt, 'YTickLabel', {'TrRol' 'TrYaw' 'TrPit' ...
                'ShFlEx' 'ShAbAd' 'ShRot' 'ElFlEx' 'ElPrSu' 'WrDev' 'WrFlEx' },'fontsize',10)
            subplot(2, 3, 2)
            barh(Healthy_Synergy_Template(3,:), 'k')
            title('H#3', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            subplot(2, 3, 3)
            barh(Healthy_Synergy_Template(2,:), 'k')
            title('H#2', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            
            subplot(2, 3, 4.5)
            barh(Synergies_Weak(1,:)/norm(Synergies_Weak(1,:)), 'k')
            xlabel('A#1')
            axis([0 1 0 DOF+1])
            title('DP = 0.94')
            yt = get(gca, 'YTick');
            set(gca, 'YTick', yt, 'YTickLabel', {'TrRol' 'TrYaw' 'TrPit' ...
                'ShFlEx' 'ShAbAd' 'ShRot' 'ElFlEx' 'ElPrSu' 'WrDev' 'WrFlEx' },'fontsize',10)
            subplot(2, 3, 6)
            barh(Synergies_Weak(2,:)/norm(Synergies_Weak(2,:)), 'k')
            xlabel('A#2')
            axis([0 1 0 DOF+1])
            title('DP = 0.97')
       
        end
        
    end
    load('clusters.mat')
    figure()
    %kinematic synergy clusters
    subplot(1, 2, 1)
    barh(Centroids(2,:), 'k')
    title({'Cluster #1'; '(n=4, DP=0.96)'}, 'FontWeight' , 'normal')
    xlabel({'Preservation of';'Healthy Synergy #2'})
    axis([0 1 0 DOF+1])
    yt = get(gca, 'YTick');
    set(gca, 'YTick', yt, 'YTickLabel', {'TrRol' 'TrYaw' 'TrPit' ...
                'ShFlEx' 'ShAbAd' 'ShRot' 'ElFlEx' 'ElPrSu' 'WrDev' 'WrFlEx' },'fontsize',10)
    
    subplot(1, 2, 2)
    barh(Centroids(1,:), 'k')
    title({'Cluster #2'; '(n=15, DP=0.98)'}, 'FontWeight' , 'normal')
    xlabel({'Merging of';'Healthy Synergies #1,3'})
    axis([0 1 0 DOF+1])
   
    suptitle('Affected Arm Kinematic Synergy Clusters')
    
    Num_Merged
    Num_Preserved
    Preserved_vectors
    
    
end %function
    
    
    
  