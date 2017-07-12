% Phase 3: compare synergies to find merged/fractionated synergies

% 20170314 Written by Navid Lambert-Shirzad

function Compare_Synergies_Merge_Fractinate
    clc
    load('Healthy_Synergy_Template.mat')
    load('clusters.mat')
    DOF = 8;
    IDs = [1:14];
    FM = [40,58,13,49,36,37,32,23,29,35,18,30,37,41]; %Fugl-Meyer Score
    RPS = [28,36,11,34,24,32,17,8,17,25,8,18,27,30]; %Reaching Performance Score
    TSS = [16,23,47,74,16,74,39,110,46,74,25,302,75,16]; %time since stroke (months)
    NumParticipants = size(IDs,2);
    
    CurrentDirectory = cd;
    CurrentDirectoryUp = strrep(CurrentDirectory,'compare the two sides',''); 
    OrigSynergiesFolder = strcat(CurrentDirectoryUp, '1 identifying synergies\');
    
    Num_Preserved = zeros(NumParticipants,1);
    Num_Cluster = zeros(NumParticipants,1);
    Num_Merged = zeros(NumParticipants,1);
    Num_Fractionated = zeros(NumParticipants,1);
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
                %there is no merging
                X(:,j)=zeros(size(X(:,j)));
            else 
                %recalculate the coefficients by including just the
                %synergies with an initial coefficient of 0.2
                X(find(X(:,j)),j) = lsqnonneg(Healthy_Synergy_Template(find(X(:,j)),:)',Synergies_Weak(j,:)');
            end              
            %similarity(j) = Synergies_Weak(j,:)*(Synergies_Strong'*X(:,j)/norm(Synergies_Strong'*X(:,j)));
            similarity(j) = Synergies_Weak(j,:)*(Healthy_Synergy_Template'*X(:,j)/norm(Healthy_Synergy_Template'*X(:,j)));
            if ceil(similarity(j)*100) >= 81
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
        for j=1:4%ndim_Strong(i,1) %
%             X(:,j) = lsqnonneg(Synergies_Weak',Synergies_Strong(j,:)');
            X(:,j) = lsqnonneg(Synergies_Weak',Healthy_Synergy_Template(j,:)');
            for k=1:size(X(:,j),1)
                if X(k,j)<0.2
                    X(k,j)=0;
                end
            end
            if size(find(X(:,j)),1) <2
                %there is no fractionation
                X(:,j)=zeros(size(X(:,j)));
            else
                %recalculate the coefficients by including just the
                %synergies with an initial coefficient of 0.2
                X(find(X(:,j)),j) = lsqnonneg(Synergies_Weak(find(X(:,j)),:)',Healthy_Synergy_Template(j,:)');
            end 
%             similarity(j) = Synergies_Strong(j,:)*(Synergies_Weak'*X(:,j)/norm(Synergies_Weak'*X(:,j)));
        end
        %Need to make sure each weak synergy is counted as
        %fractionation of only one of the strong ones
        for j=1:ndim_Weak(i,1)
            [MaxValue, ind] = max(X(j,:));
            X(j,:)=zeros(size(X(j,:)));
            X(j,ind)=MaxValue;
        end
        %how good is the reconstruction?
        for j=1:4
            if size(find(X(:,j)),1) <2
                %there is no fractionation
                X(:,j)=zeros(size(X(:,j)));
            else 
                X(find(X(:,j)),j) = lsqnonneg(Synergies_Weak(find(X(:,j)),:)',Healthy_Synergy_Template(j,:)');
            end
            similarity(j) = Healthy_Synergy_Template(j,:)*(Synergies_Weak'*X(:,j)/norm(Synergies_Weak'*X(:,j)));
            if ceil(similarity(j)*100) >= 81
                Num_Fractionated(i)=Num_Fractionated(i)+1;
            end 
        end

        X
        similarity
%         if i==6
%             X
%         end
        clear X
        clear similarity
        
        
        %%%%%%%%%%%%%%%%%%%%%%%
        %%%Preserved Synergies%%%
        %%%%%%%%%%%%%%%%%%%%%%%
        subjOne = Healthy_Synergy_Template;         
        subjTwo = Synergies_Weak;
        DP_All = zeros(4, ndim_Weak(i,1)); %DP for dot product
        for k = 1:4 
            for j = 1:ndim_Weak(i,1)
                DP_All(k,j) = subjOne(k,:)*subjTwo(j,:)'; 
            end
        end
        %matching on the rows
        DP_All
        NumMatched = 0;
        
        if ndim_Weak(i,1)<4
            smallerDOF = ndim_Weak(i,1);
        else
            smallerDOF = 4;
        end
        while NumMatched < smallerDOF
            for RowNum = 1:4
                %find the max DP in the row
                [MaxDPRow, IndRow] = max(DP_All(RowNum,:));
                %check to see if the max in row is also max in column
                %if so it is a match
                [~, IndCol] = max(DP_All(:,IndRow));
                if MaxDPRow ~= 0 %this row is not previously matched
                    if IndCol == RowNum
                        %this is a match
                        if ceil(MaxDPRow*100) >= 85%0.81 %similarity_range_DP
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
                    if NumMatched == smallerDOF
                        break
                    end
                end
            end    
        end
        vector_matches

        
        %%%%%%%%%%%%%%%%%%%%%%%
        %%%Cluster Synergies%%%
        %%%%%%%%%%%%%%%%%%%%%%%
        subjOne = Centroids7;         
        subjTwo = Synergies_Weak;
        DP_All_Cluster = zeros(7, ndim_Weak(i,1)); %DP for dot product
        for k = 1:7 
            for j = 1:ndim_Weak(i,1)
                DP_All_Cluster(k,j) = subjOne(k,:)*subjTwo(j,:)'; 
            end
        end
        %matching on the rows
        DP_All_Cluster
        NumMatched = 0;
        Cluster_matches = zeros(1,7);
        if ndim_Weak(i,1)<7
            smallerDOF = ndim_Weak(i,1);
        else
            smallerDOF = 7;
        end
        while NumMatched < smallerDOF
            for RowNum = 1:7
                %find the max DP in the row
                [MaxDPRow, IndRow] = max(DP_All_Cluster(RowNum,:));
                %check to see if the max in row is also max in column
                %if so it is a match
                [~, IndCol] = max(DP_All_Cluster(:,IndRow));
                if MaxDPRow ~= 0 %this row is not previously matched
                    if IndCol == RowNum
                        %this is a match
                        if ceil(MaxDPRow*100) >= 77%0.81 %similarity_range_DP
                            Num_Cluster(i) = Num_Cluster(i) + 1;
                            Cluster_vectors(i,RowNum)=IndCol;
                            Cluster_matches(RowNum)=IndRow;
                        end
                        NumMatched = NumMatched+1;                       
                        %temp_DP(RowNum, SubjCount2) = MaxDPRow;%temp_DP(RowNum)+MaxDPRow;
                        DP_All_Cluster(RowNum,:) = zeros(size(DP_All_Cluster(RowNum,:)));
                        DP_All_Cluster(:,IndRow) = zeros(size(DP_All_Cluster(:,IndRow)));
                        
                        %RowNum
                        %IndRow
                    end
                    if NumMatched == smallerDOF
                        break
                    end
                end
            end    
        end
        Cluster_matches
        
        if i==4 %example graph for fractionation 
            figure()
            %add the template to the figure
            subplot(2, 5, 1)
            barh(Healthy_Synergy_Template(1,:), 'k')
            title('H#1', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            yt = get(gca, 'YTick');
            set(gca, 'YTick', yt, 'YTickLabel', {'DelAnt' 'DelMed' 'DelPos' ...
                'Biceps' 'TriLong' 'TriLat' 'Brachi' 'PectMaj'},'fontsize',10)
            subplot(2, 5, 2)
            barh(Healthy_Synergy_Template(3,:), 'k')
            title('H#3', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            subplot(2, 5, 3)
            barh(Healthy_Synergy_Template(2,:), 'k')
            title('H#2', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            subplot(2, 5, 4)
            barh(Healthy_Synergy_Template(4,:), 'k')
            title('H#4', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            
            subplot(2, 5, 6)
            barh(Synergies_Weak(4,:)/norm(Synergies_Weak(4,:)), 'k')
            xlabel('A#4')
            axis([0 1 0 DOF+1])
            title('DP = 0.95')
            yt = get(gca, 'YTick');
            set(gca, 'YTick', yt, 'YTickLabel', {'DelAnt' 'DelMed' 'DelPos' ...
                'Biceps' 'TriLong' 'TriLat' 'Brachi' 'PectMaj'},'fontsize',10)
            subplot(2, 5, 7)
            barh(Synergies_Weak(5,:)/norm(Synergies_Weak(5,:)), 'k')
            xlabel('A#5')
            axis([0 1 0 DOF+1])
            title('DP = 0.96')
            subplot(2, 5, 8)
            barh(Synergies_Weak(1,:)/norm(Synergies_Weak(1,:)), 'k')
            xlabel('A#1')
            axis([0 1 0 DOF+1])
            subplot(2, 5, 9)
            barh(Synergies_Weak(2,:)/norm(Synergies_Weak(2,:)), 'k')
            xlabel('A#2')
            axis([0 1 0 DOF+1])
            title('DP = 0.96')
            subplot(2, 5, 10)
            barh(Synergies_Weak(3,:)/norm(Synergies_Weak(3,:)), 'k')
            xlabel('A#3')
            axis([0 1 0 DOF+1])
        end

            
        if i==8 %example graph for merging 
            figure()
            %add the template to the figure
            subplot(2, 4, 1)
            barh(Healthy_Synergy_Template(1,:), 'k')
            title('H#1', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            yt = get(gca, 'YTick');
            set(gca, 'YTick', yt, 'YTickLabel', {'DelAnt' 'DelMed' 'DelPos' ...
                'Biceps' 'TriLong' 'TriLat' 'Brachi' 'PectMaj'},'fontsize',10)
            subplot(2, 4, 2)
            barh(Healthy_Synergy_Template(4,:), 'k')
            title('H#4', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            subplot(2, 4, 3)
            barh(Healthy_Synergy_Template(2,:), 'k')
            title('H#2', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            subplot(2, 4, 4)
            barh(Healthy_Synergy_Template(3,:), 'k')
            title('H#3', 'FontWeight' , 'normal')
            axis([0 1 0 DOF+1])
            
            subplot(2, 4, 5.5)
            barh(Synergies_Weak(1,:)/norm(Synergies_Weak(1,:)), 'k')
            xlabel('A#1')
            axis([0 1 0 DOF+1])
            title('DP = 0.88')
            yt = get(gca, 'YTick');
            set(gca, 'YTick', yt, 'YTickLabel', {'DelAnt' 'DelMed' 'DelPos' ...
                'Biceps' 'TriLong' 'TriLat' 'Brachi' 'PectMaj'},'fontsize',10)
            subplot(2, 4, 7)
            barh(Synergies_Weak(2,:)/norm(Synergies_Weak(2,:)), 'k')
            xlabel('A#2')
            axis([0 1 0 DOF+1])
            title('DP = 0.92')
       
        end
        
    end
    
    figure()
    %muscle synergy clusters
    subplot(1, 7, 1)
    barh(Centroids7(7,:), 'k')
    title({'Cluster #1'; '(n=5, DP=0.96)'}, 'FontWeight' , 'normal')
    xlabel({'Preservation of';'Healthy Synergy #1'})
    axis([0 1 0 DOF+1])
    yt = get(gca, 'YTick');
    set(gca, 'YTick', yt, 'YTickLabel', {'DelAnt' 'DelMed' 'DelPos' ...
        'Biceps' 'TriLong' 'TriLat' 'Brachi' 'PectMaj'},'fontsize',10)
    subplot(1, 7, 2)
    barh(Centroids7(1,:), 'k')
    title({'Cluster #2'; '(n=9, DP=0.95)'}, 'FontWeight' , 'normal')
    xlabel({'Preservation of';'Healthy Synergy #2'})
    axis([0 1 0 DOF+1])
    subplot(1, 7, 3)
    barh(Centroids7(4,:), 'k')
    title({'Cluster #3'; '(n=7, DP=0.97)'}, 'FontWeight' , 'normal')
    xlabel({'Preservation of';'Healthy Synergy #3'})
    axis([0 1 0 DOF+1])
    subplot(1, 7, 4)
    barh(Centroids7(3,:), 'k')
    title({'Cluster #4'; '(n=7, DP=0.92)'}, 'FontWeight' , 'normal')
    xlabel({'Preservation of';'Healthy Synergy #4'})
    axis([0 1 0 DOF+1])
    subplot(1, 7, 5)
    barh(Healthy_Synergy_Template'*X_Merge(:,2)/norm(Healthy_Synergy_Template'*X_Merge(:,2)) , 'k')
    %%%%%%%%barh(Centroids7(2,:)/norm(Centroids7(2,:)), 'k')
%     hold on
%     Merging24 = Healthy_Synergy_Template(2,:)*0.3258+ Healthy_Synergy_Template(4,:)*0.5854;
%     Merging24 = Merging24/norm(Merging24);
%     barh([Centroids7(2,:);Merging24]')
    title({'Cluster #5'; '(n=7, DP=0.94)'}, 'FontWeight' , 'normal')
    xlabel({'Merging of';'Healthy Synergies #2,4'})
    axis([0 1 0 DOF+1])
    subplot(1, 7, 6)
    barh(Healthy_Synergy_Template'*X_Merge(:,5)/norm(Healthy_Synergy_Template'*X_Merge(:,5)) , 'k')
    %%%%%%%barh(Centroids7(5,:)/norm(Centroids7(5,:)), 'k')
%     hold on
%     Merging134 = Healthy_Synergy_Template(1,:)*0.4603+ Healthy_Synergy_Template(3,:)*0.3838+ Healthy_Synergy_Template(4,:)*0.2602;
%     Merging134 = Merging134/norm(Merging134);
%     barh([Centroids7(5,:);Merging134]')
    title({'Cluster #6'; '(n=7, DP=0.88)'}, 'FontWeight' , 'normal')
    xlabel({'Merging of';'Healthy Synergies #1,3,4'})
    axis([0 1 0 DOF+1])
    subplot(1, 7, 7)
    barh(Centroids7(6,:), 'k')
    title({'Cluster #7'; '(n=3, DP=0.96)'}, 'FontWeight' , 'normal')
    xlabel({'New Synergy'})
    axis([0 1 0 DOF+1])
    suptitle('Affected Arm Muscle Synergy Clusters')
    
    Num_Merged
    Num_Fractionated
    
    Num_Preserved
    Preserved_vectors
    ndim_Weak
    Num_Cluster
    Cluster_vectors
end %function
    
    
    
  