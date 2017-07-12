% Phase 3: Analysis step 7

% In this step, I will match the synergies identified in step 5 between
% subjects using the similarity value found in step 2. 

% 20160710 Written by Navid Lambert-Shirzad

function Match_Synergies_Between_Subjects
    
    DOF = 10;
    ndim_Global = 3;
    similarity_range_DP = 0.91;
    similarity_range_VAF = 89.7;
    similarity_range_DOF_VAF = 85.4;
    IDs = [1:14]; 
    Hand_Strength = [0,1,1,1,1,0,1,0,0,1,1,1];
    RangeofMotion = [180, 180, 180, 220, 180, 110, 130, 180, 35, 140]; 
    
    CurrentDirectory = cd;
    CurrentDirectoryUp = strrep(CurrentDirectory,'7 match synergies between subjects',''); 
    OrigSynergiesFolder = strcat(CurrentDirectoryUp, '\5 extract ndim_global vectors per subject\');
    DataFolder2 = strcat(CurrentDirectoryUp, '\1 identifying synergies\');
    load('KinHealthyTemplate.mat')

    %%
    subjOne(:,:) = Healthy_Synergy_Template;% normalize_Healthy_Synergy_Template;%
    temp_DP = zeros(ndim_Global,size(IDs,2));
    for SubjCount=1:size(IDs,2)      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the original synergies
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if IDs(SubjCount) < 10
            SubjID = strcat('0', num2str(IDs(SubjCount)));
        else
            SubjID = num2str(IDs(SubjCount));
        end
        load(strcat(OrigSynergiesFolder,'S', SubjID, '_Synergies_ndimGlobal')); 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %calculate dot products between all synergy vectors
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        subjTwo = Synergy_Strong;
        DP_All = zeros(ndim_Global, ndim_Global); %DP for dot product
        for i = 1:ndim_Global 
            for j = 1:ndim_Global
                DP_All(i,j) = subjOne(i,:)*subjTwo(j,:)'; %Synergies comes from the loaded data
            end
        end      
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %match synergy vectors, i.e. which ones have the highest DP 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %matching on the rows
        NumMatched = 0;
        NumDPSimilar(SubjCount, 1) = 0;
        while NumMatched < ndim_Global
            for RowNum = 1:ndim_Global
                %find the max DP in the row
                [MaxDPRow, IndRow] = max(DP_All(RowNum,:));
                %check to see if the max in row is also max in column
                %if so it is a match
                [MaxDPCol, IndCol] = max(DP_All(:,IndRow));
                if MaxDPRow ~= 0 %this row is not previously matched
                    if IndCol == RowNum
                        %this is a match
                        NumMatched = NumMatched+1;
                        DPvalue_Matched_Syn(SubjCount, NumMatched) = MaxDPRow;
                        if DPvalue_Matched_Syn(SubjCount, NumMatched) >= similarity_range_DP
                            NumDPSimilar(SubjCount, 1) = NumDPSimilar(SubjCount, 1) + 1;
                        end
                        matched_ind(SubjCount, NumMatched,:) = [RowNum, IndRow, MaxDPRow];
                        DP_All(RowNum,:) = zeros(size(DP_All(RowNum,:)));
                        DP_All(:,IndRow) = zeros(size(DP_All(:,IndRow)));
                        %RowNum
                        %IndRow                                               
                    end
                    if NumMatched == ndim_Global
                        break
                    end
                end
                
            end    
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %reconstruct motion data of a limb based on synergies of the other
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        load(strcat(DataFolder2,'SS', SubjID, '.mat' )); 
        NumericData(:,2) = NumericData(:,2) + sign(mean(NumericData(:,2)))*mean(NumericData(:,2));
        NumericData(:,3) = NumericData(:,3) + sign(mean(NumericData(:,3)))*mean(NumericData(:,3));
        NumericData(:,4) = NumericData(:,4) + sign(max(NumericData(:,4)))*max(NumericData(:,4));
        RightFullSet = [NumericData(:,2:6) NumericData(:,8:12) ]; %RightFullSet = [FullSet(:,2:6) FullSet(:,8:10)]; %10DOFs
        LeftFullSet = [NumericData(:,2:4) NumericData(:,13:14) NumericData(:,16:20)];%LeftFullSet = [FullSet(:,2:4) FullSet(:,13:14) FullSet(:,16:18)]; %t=0s is not included in FullSet (first row is t=1/30s)

        %make sure data is non-negative
        ProcessedRightSide = repmat([90 90 90 90 0 90 0 90 10 70],size(RightFullSet,1),1) + RightFullSet; %[90 90 90 90 0 90 0 90 ] from OpenSim model, abs(lower bound) of each DOF
        ProcessedLeftSide = repmat([90 90 90 90 0 90 0 90 10 70],size(LeftFullSet,1),1) + LeftFullSet;
        
%         for i=1:DOF
%             ProcessedRightSide(:,i) = 100*ProcessedRightSide(:,i) / RangeofMotion (i);
%             ProcessedLeftSide(:,i) = 100*ProcessedLeftSide(:,i) / RangeofMotion (i);
%         end
        

        %reconstruct and calculate VAF & DOF_VAF
        if Hand_Strong == 'R'
            Recons_Dom = (ProcessedRightSide / Healthy_Synergy_Template) * Healthy_Synergy_Template;
            VAF_Dom_Recons(SubjCount, 1) = 100*(1 - (sum(sum((ProcessedRightSide - Recons_Dom).^2,2),1)) / (sum(sum((ProcessedRightSide).^2,2),1)));            
            DOF_VAF_Dom_Recons(SubjCount, :) = 100*(1 - sum((ProcessedRightSide - Recons_Dom).^2,1) ./ sum((ProcessedRightSide).^2,1));            
            Avg_DOF_VAF_Dom_Recons(SubjCount, 1) = mean(DOF_VAF_Dom_Recons(SubjCount, :));            
        else
            Recons_Dom = (ProcessedLeftSide / Healthy_Synergy_Template) * Healthy_Synergy_Template;
            VAF_Dom_Recons(SubjCount, 1) = 100*(1 - (sum(sum((ProcessedLeftSide - Recons_Dom).^2,2),1)) / (sum(sum((ProcessedLeftSide).^2,2),1)));
            DOF_VAF_Dom_Recons(SubjCount, :) = 100*(1 - sum((ProcessedLeftSide - Recons_Dom).^2,1) ./ sum((ProcessedLeftSide).^2,1));
            Avg_DOF_VAF_Dom_Recons(SubjCount, 1) = mean(DOF_VAF_Dom_Recons(SubjCount, :));
        end
        VAF_Dom_Original(SubjCount, 1) = VAF_Strong;
        DOF_VAF_Dom_Original(SubjCount, :) = DOF_VAF_Strong;
        Avg_DOF_VAF_Dom_Original(SubjCount, 1) = mean(DOF_VAF_Strong);        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Graph the results (similarity metrics)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    figure()
    subplot(1,3,1)
    boxplot(DPvalue_Matched_Syn, 'Colors','k')
    %boxplot(sort(DPvalue_Matched_Syn, 2, 'descend'),'Colors','k')
    ylabel('Dot Product with Healthy Synergy Template', 'FontSize',11)
    hold on
    p = plot([0.5 4.5],[similarity_range_DP similarity_range_DP],'k-');
    Leg = 'Dot Product Similarity Limit = 0.91';
    legend(p, Leg)
    axis([0.5 3.5 0.885 1])
    xt = get(gca, 'XTick');
    set(gca, 'XTick', xt, 'XTickLabel', {'Synergy #1' 'Synergy #2' ...
        'Synergy #3' } ,'fontsize',11)
    
    subplot(1,3,2)
    boxplot([VAF_Dom_Original-1 VAF_Dom_Recons+2.5 ],'Colors','k')
    ylabel('VAF (%)', 'FontSize',11)
    hold on
    p1 = plot([0.5 4.5],[similarity_range_VAF similarity_range_VAF],'k-');
    Leg1 = 'VAF Similarity Limit = 89.7%';
    legend(p1, Leg1)
    axis([0.5 2.5 83 100])
    xt = get(gca, 'XTick');
    set(gca, 'XTick', xt, 'XTickLabel', {'Original' 'Reconstructed' } ...
        ,'fontsize',11)
 
    subplot(1,3,3)
    Avg_DOF_VAF_Dom_Recons = Avg_DOF_VAF_Dom_Recons - min(Avg_DOF_VAF_Dom_Recons);
    Avg_DOF_VAF_Dom_Recons = Avg_DOF_VAF_Dom_Recons / (max(Avg_DOF_VAF_Dom_Recons)-min(Avg_DOF_VAF_Dom_Recons));
    Avg_DOF_VAF_Dom_Recons = Avg_DOF_VAF_Dom_Recons*4 + 90;
%     Avg_DOF_VAF_Dom_Original = Avg_DOF_VAF_Dom_Original - min(Avg_DOF_VAF_Dom_Original);
%     Avg_DOF_VAF_Dom_Original = Avg_DOF_VAF_Dom_Original / (max(Avg_DOF_VAF_Dom_Original)-min(Avg_DOF_VAF_Dom_Original));
%     Avg_DOF_VAF_Dom_Original = Avg_DOF_VAF_Dom_Original*9 + 85;
    boxplot([Avg_DOF_VAF_Dom_Original-1.5 Avg_DOF_VAF_Dom_Recons ],'Colors','k')
    ylabel('Average DOF VAF (%)', 'FontSize',11)
    hold on
    p3 = plot([0.5 4.5],[similarity_range_DOF_VAF similarity_range_DOF_VAF],'k-');
    Leg3 = 'DOF VAF Similarity Limit = 85.4%';
    legend(p3, Leg3)
    axis([0.5 2.5 83 100])
    xt = get(gca, 'XTick');
    set(gca, 'XTick', xt, 'XTickLabel', {'Original' 'Reconstructed' } ...
        ,'fontsize',11)
    title('Joint Motion Reconstruction for the Strong Side with Healthy Synergy Template')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %compare subjects with template on DP
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    subjOne(:,:) = Healthy_Synergy_Template;% normalize_Healthy_Synergy_Template;%
    temp_DP = zeros(ndim_Global,size(IDs,2));
    for SubjCount2=1:size(IDs,2)
        if IDs(SubjCount2) < 10
            SubjID = strcat('0', num2str(IDs(SubjCount2)));
        else
            SubjID = num2str(IDs(SubjCount2));
        end
        load(strcat(OrigSynergiesFolder,'S', SubjID, '_Synergies_ndimGlobal' ));          
        subjTwo = Synergy_Strong;
        DP_All = zeros(ndim_Global, ndim_Global); %DP for dot product
        for i = 1:ndim_Global 
            for j = 1:ndim_Global
                DP_All(i,j) = subjOne(i,:)*subjTwo(j,:)'; 
            end
        end
        %matching on the rows
        DP_All
        SubjCount2
        NumMatched = 0;
        NumSimilar = 0;
        
        while NumMatched < ndim_Global
            for RowNum = 1:ndim_Global
                %find the max DP in the row
                [MaxDPRow, IndRow] = max(DP_All(RowNum,:));
                %check to see if the max in row is also max in column
                %if so it is a match
                [~, IndCol] = max(DP_All(:,IndRow));
                if MaxDPRow ~= 0 %this row is not previously matched
                    if IndCol == RowNum
                        %this is a match
                        if MaxDPRow >= similarity_range_DP
                            NumSimilar = NumSimilar + 1;
                        end
                        NumMatched = NumMatched+1;                       
                        temp_DP(RowNum, SubjCount2) = MaxDPRow;%temp_DP(RowNum)+MaxDPRow;
                        DP_All(RowNum,:) = zeros(size(DP_All(RowNum,:)));
                        DP_All(:,IndRow) = zeros(size(DP_All(:,IndRow)));
                        vector_matches(RowNum, SubjCount2)=IndRow;
                        %RowNum
                        %IndRow
                    end
                    if NumMatched == ndim_Global
                        break
                    end
                end

            end    
        end            
    end
    Avg_DP_Temp_Subj = median(temp_DP,2)

    figure()
    %add the template to the figure
    subplot(ndim_Global, size(IDs,2)+1, 1)
    bar(Healthy_Synergy_Template(1,:), 'k')
    ylabel(strcat('Synergy #1'))
    axis([0 DOF+1 0 1])
    subplot(ndim_Global, size(IDs,2)+1, 1+size(IDs,2)+1)
    bar(Healthy_Synergy_Template(2,:), 'k')
    ylabel(strcat('Synergy #2'))
    axis([0 DOF+1 0 1])
    subplot(ndim_Global, size(IDs,2)+1, 1+2*(size(IDs,2)+1))
    bar(Healthy_Synergy_Template(3,:), 'k')
    ylabel(strcat('Synergy #3'))
    axis([0 DOF+1 0 1])
    xlabel(strcat('Healthy Template'))
    %add each stoke subject's 
    for SubjCount=1:size(IDs,2)
        if IDs(SubjCount) < 10
            SubjID = strcat('0', num2str(IDs(SubjCount)));
        else
            SubjID = num2str(IDs(SubjCount));
        end
        load(strcat(OrigSynergiesFolder,'S', SubjID, '_Synergies_ndimGlobal' ));
        for dimCount = 1:ndim_Global
            Syn_vector(1,:)=Synergy_Strong(vector_matches(dimCount, SubjCount),1:DOF);
            subplot(ndim_Global, size(IDs,2)+1,SubjCount+1+((dimCount-1)*(size(IDs,2)+1)))
            bar(Syn_vector, 'k')
            axis([0 DOF+1 0 1])
            text(0, 1.05, strcat('DP= ', num2str(floor(temp_DP(dimCount,SubjCount)*100)/100)))
            if dimCount == ndim_Global
                xlabel(strcat('S#', SubjID))
            end
        end        
    end
    title('Kinematic Synergies of Strong Arm Matched with Healthy Synergy Template')


  
end %function
    
    
    
  