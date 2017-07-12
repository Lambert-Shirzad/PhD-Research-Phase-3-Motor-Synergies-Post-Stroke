% Phase 3: compare synergies of the weak arm to find similar synergies
% Are these clusters merging/fractionation of the healthy synergies?

% 20170403 Written by Navid Lambert-Shirzad

function Cluster_Analysis
    clc
    clear
    load('KinHealthyTemplate.mat')
    DOF = 10;
    IDs = [1:14];
    FM = [40,58,13,49,36,37,32,23,29,35,18,30,37,41]; %Fugl-Meyer Score
    RPS = [28,36,11,34,24,32,17,8,17,25,8,18,27,30]; %Reaching Performance Score
    TSS = [16,23,47,74,16,74,39,110,46,74,25,302,75,16]; %time since stroke (months)
    NumParticipants = size(IDs,2);
    
    CurrentDirectory = cd;
    CurrentDirectoryUp = strrep(CurrentDirectory,'cluster analysis',''); 
    OrigSynergiesFolder = strcat(CurrentDirectoryUp, '1 identifying synergies\');
    Synergies_Weak = [];
    WSyn_ID = [];
    for i=1:NumParticipants
        if IDs(i) < 10
            SubjID = strcat('0', num2str(IDs(i)));
        else
            SubjID = num2str(IDs(i));
        end
        %load(strcat(OrigSynergiesFolder,'S', SubjID, '_Strong_Synergies.mat' )); 
        load(strcat(OrigSynergiesFolder,'S', SubjID, '_Weak_Synergies.mat' )); 
        if SubjWeakHand == 'L'
            WSyn_ID(end+1:end+ndim_L,1) = i;
            %Synergies_Strong = Synergies_R;
            Synergies_Weak(end+1:end+ndim_L,:) = Synergies_L;
        else
            WSyn_ID(end+1:end+ndim_R,1) = i;
            %Synergies_Strong = Synergies_L;
            Synergies_Weak(end+1:end+ndim_R,:) = Synergies_R;
        end
    end
    numberofsynergies = length(WSyn_ID);
    numHealthySyn = 3;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%Create Clusters%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    numClusters = 2;
    goodfit = 0;
    while goodfit == 0
        %7clusters ensures that the synergies of each individual ends up in
        %different clusters
        [ClusterID, Centroids, SumDist] = kmeans(Synergies_Weak, numClusters);

        %normalize the cluster synergies and make sure all the weak-synergies
        %in the cluster are similar to the mean of the cluster
        DP_clust = [];
        DP_clust_avg = zeros(1,numClusters);
        for i=1:numClusters
           Centroids(i,:)=Centroids(i,:)/norm(Centroids(i,:)); 
           indID = find(ClusterID == i);
           groupedSynergies = Synergies_Weak(indID,:);
           for j=1:size(groupedSynergies,1)
               DP_clust(end+1) = Centroids(i,:)*groupedSynergies(j,:)'; 
               DP_clust_avg(i) = DP_clust_avg(i) + DP_clust(end);
           end
           DP_clust_avg(i) = DP_clust_avg(i)/size(groupedSynergies,1);
        end
        %bar(DP_clust)
        if sum(DP_clust > 0.81)>numberofsynergies-1 %similarity_range_DP
            %weak synergy vectors were similar to their associated
            %cluster's mean
            goodfit = 1;
            mean(SumDist)
        end        
    end
    Num_Preserved = 0;
    Num_Merged = 0;
    Num_Fractionated = 0;      
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%merging of synergies%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    for j=1:numClusters%ndim_Weak(i,1)
        X(:,j) = lsqnonneg(Healthy_Synergy_Template',Centroids(j,:)');
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
            X(find(X(:,j)),j) = lsqnonneg(Healthy_Synergy_Template(find(X(:,j)),:)',Centroids(j,:)');
        end              
        %similarity(j) = Synergies_Weak(j,:)*(Synergies_Strong'*X(:,j)/norm(Synergies_Strong'*X(:,j)));
        similarity(j) = Centroids(j,:)*(Healthy_Synergy_Template'*X(:,j)/norm(Healthy_Synergy_Template'*X(:,j)));
        if ceil(similarity(j)*100) >= 81
            Num_Merged=Num_Merged+1;
        end
    end

    X_Merge = X
    sim_Merge = similarity
    clear X
    clear similarity


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%fractionantion of synergies%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j=1:numHealthySyn%ndim_Healthy
        X(:,j) = lsqnonneg(Centroids',Healthy_Synergy_Template(j,:)');
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
            X(find(X(:,j)),j) = lsqnonneg(Centroids(find(X(:,j)),:)',Healthy_Synergy_Template(j,:)');
        end 
    end
    %Need to make sure each weak synergy is counted as
    %fractionation of only one of the strong ones
    for j=1:numClusters
        [MaxValue, ind] = max(X(j,:));
        X(j,:)=zeros(size(X(j,:)));
        X(j,ind)=MaxValue;
    end
    %how good is the reconstruction?
    for j=1:numHealthySyn
        if size(find(X(:,j)),1) <2
            %there is no fractionation
            X(:,j)=zeros(size(X(:,j)));
        else 
            X(find(X(:,j)),j) = lsqnonneg(Centroids(find(X(:,j)),:)',Healthy_Synergy_Template(j,:)');
        end
        similarity(j) = Healthy_Synergy_Template(j,:)*(Centroids'*X(:,j)/norm(Centroids'*X(:,j)));
        if ceil(similarity(j)*100) >= 81
            Num_Fractionated=Num_Fractionated+1;
        end 
    end

    X_Fraction = X
    sim_Fraction = similarity
    clear X
    clear similarity


    %%%%%%%%%%%%%%%%%%%%%%%
    %%%Preserved Synergies%%%
    %%%%%%%%%%%%%%%%%%%%%%%
    subjOne = Healthy_Synergy_Template;         
    subjTwo = Centroids;
    DP_All = zeros(numHealthySyn, numClusters); %DP for dot product
    for k = 1:numHealthySyn 
        for j = 1:numClusters
            DP_All(k,j) = subjOne(k,:)*subjTwo(j,:)'; 
        end
    end
    %matching on the rows
    DP_All
    NumMatched = 0;
    smallerDOF = numClusters;
    while NumMatched < smallerDOF
        for RowNum = 1:numHealthySyn
            %find the max DP in the row
            [MaxDPRow, IndRow] = max(DP_All(RowNum,:));
            %check to see if the max in row is also max in column
            %if so it is a match
            [~, IndCol] = max(DP_All(:,IndRow));
            if MaxDPRow ~= 0 %this row is not previously matched
                if IndCol == RowNum
                    %this is a match
                    if ceil(MaxDPRow*100) >= 81%0.81 %similarity_range_DP
                        Num_Preserved = Num_Preserved + 1;
                        Preserved_vectors(RowNum)=IndCol;
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
    DP_clust_avg
        

    Num_Merged
    Num_Fractionated
    Num_Preserved
    Preserved_vectors
    save('clusters.mat', 'X_Merge', 'X_Fraction', 'sim_Merge', 'sim_Fraction', ...
        'DP_All', 'vector_matches', 'Num_Merged', 'Num_Fractionated', 'Num_Preserved', ...
        'ClusterID', 'Centroids', 'WSyn_ID', 'DP_clust_avg')
    
    
end %function
    
    
    
  