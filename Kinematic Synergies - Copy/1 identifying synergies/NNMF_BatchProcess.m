% Phase 3: Analysis step 1
% Factorize motion data of stroke participants into synergies of the
% strong and weak sides of the body using NNMF and save the
% synergies for the next steps of analysis.

% The function batch-processes the data of participants.
% SubjectIDs: ID of participants that this step of analysis will be run for
% try [1:12] to run participants 1-12
% HandStrength: Which hand is stronger for each subject in SubjectIDs, 1
% for right hand and 0 for left hand. Example: [1,1,0]

%  NNMF_BatchProcess([1:12],[1,1,1,0,1,1,1,1,1,0,1,1])

% Outcome will be saved in .mat files (Y01_Dom_Synergies.mat and Y01_NonDom_Synergies.mat) for each participant.

% 20160609 Written by Navid Shirzad
% 20170307 Editted by NLS

function NNMF_BatchProcess(SubjectIDs, HandStrength)
    DOF = 10;
    RangeofMotion = [180, 180, 180, 220, 180, 110, 130, 180, 35, 140]; 
    
    for subjectcounter = 1:size(SubjectIDs,2)

        if SubjectIDs(subjectcounter) < 10
            SubjID = strcat('0', num2str(SubjectIDs(subjectcounter)));
        else
            SubjID = num2str(SubjectIDs(subjectcounter));
        end


        NumberFolds = 1;
        RightVAF = zeros(DOF,NumberFolds); LeftVAF = zeros(DOF,NumberFolds); %VAF for each number of synergies
        DeltaRightVAF = zeros(DOF,NumberFolds); DeltaLeftVAF = zeros(DOF,NumberFolds); %how much VAF changes when a synergy vector is added
        RightDOF_VAF = zeros(DOF,DOF,NumberFolds); LeftDOF_VAF = zeros(DOF,DOF,NumberFolds); %how VAF of each DOF changes as more synergies are added for each fold. first DOF is the synergies included, the second is the DOF being observed, third is the fold number
                
        tic
        %there are k=1 fold (we are looking at the participant's entire data
        %I was lazy and did not take this out (look at k-fold
        %croos-validation of Phase 1-A)
        for fold = 1:NumberFolds

            %load the data (joint motion data)
            load(strcat('SS', SubjID, '.mat'))
            NumericData(:,2) = NumericData(:,2) + sign(mean(NumericData(:,2)))*mean(NumericData(:,2));
            NumericData(:,3) = NumericData(:,3) + sign(mean(NumericData(:,3)))*mean(NumericData(:,3));
            NumericData(:,4) = NumericData(:,4) + sign(max(NumericData(:,4)))*max(NumericData(:,4));
            RightFullSet = [NumericData(:,2:6) NumericData(:,8:12) ]; %RightFullSet = [FullSet(:,2:6) FullSet(:,8:10)]; %10DOFs
            LeftFullSet = [NumericData(:,2:4) NumericData(:,13:14) NumericData(:,16:20)];%LeftFullSet = [FullSet(:,2:4) FullSet(:,13:14) FullSet(:,16:18)]; %t=0s is not included in FullSet (first row is t=1/30s)

            %make sure data is non-negative
            RightFullSet = repmat([90 90 90 90 0 90 0 90 10 70],size(RightFullSet,1),1) + RightFullSet; %[90 90 90 90 0 90 0 90 ] from OpenSim model, abs(lower bound) of each DOF
            LeftFullSet = repmat([90 90 90 90 0 90 0 90 10 70],size(LeftFullSet,1),1) + LeftFullSet;
            
            %normalize the data
% % % % % %         maxRight = max(RightFullSet);
% % % % % %         maxLeft = max(LeftFullSet);       
% % % % % %         for i=1:DOF %assuming right and left side have the same size
% % % % % %             RightFullSet(:,i) = 100*RightFullSet(:,i)/maxRight(1,i);
% % % % % %             LeftFullSet(:,i) = 100*LeftFullSet(:,i)/maxLeft(1,i);
% % % % % %             
% % % % % %         end        
            for i=1:DOF
                RightFullSet(:,i) = 100*RightFullSet(:,i) / RangeofMotion (i);
                LeftFullSet(:,i) = 100*LeftFullSet(:,i) / RangeofMotion (i);
            end

            %check training is properly done (and record all the data so you can generate plots)
            GoodTrainR = 0; GoodTrainL=0; 
            numSynergy = 1;
            while numSynergy < DOF 
                %perform NNMF on data
                true = 0; count = 1;
                while true == 0 && count < 10 && GoodTrainR == 0
                    [ScoresRightTrTemp, SynergiesRightTrAll] = nnmf(RightFullSet, numSynergy); 
                    if rank(SynergiesRightTrAll) == numSynergy
                        true = 1; %not underfitting or stuck in local minima
                    end
                    count = count + 1;
                    if count == 10
                        SynergiesRightTrAll = zeros(size(SynergiesRightTrAll));
                    end
                end
                true = 0; count = 1;
                while true == 0 && count < 10 && GoodTrainL == 0
                    [ScoresLeftTrTemp, SynergiesLeftTrAll] = nnmf(LeftFullSet, numSynergy); 
                    if rank(SynergiesLeftTrAll) == numSynergy
                        true = 1; %not underfitting or stuck in local minima
                    end
                    count = count + 1;
                    if count == 10
                        SynergiesLeftTrAll = zeros(size(SynergiesLeftTrAll));
                    end
                end
                

                if GoodTrainR == 0 || GoodTrainL == 0
                    RightApprox = ScoresRightTrTemp * SynergiesRightTrAll;
                    RightVAF(numSynergy,fold) = 100*(1 - (sum(sum((RightFullSet - RightApprox).^2,2),1)) / (sum(sum((RightFullSet).^2,2),1))); %1-SSE/SST
                    LeftApprox = ScoresLeftTrTemp * SynergiesLeftTrAll;
                    LeftVAF(numSynergy,fold) = 100*(1 - (sum(sum((LeftFullSet - LeftApprox).^2,2),1)) / (sum(sum((LeftFullSet).^2,2),1))); %1-SSE/SST
                    if numSynergy ~= 1
                        DeltaRightVAF(numSynergy,fold)=RightVAF(numSynergy,fold)-RightVAF(numSynergy-1,fold);
                        DeltaLeftVAF(numSynergy,fold)=LeftVAF(numSynergy,fold)-LeftVAF(numSynergy-1,fold);
                    else
                        DeltaRightVAF(numSynergy,fold)=RightVAF(numSynergy,fold);
                        DeltaLeftVAF(numSynergy,fold)=LeftVAF(numSynergy,fold);
                    end
                    RightDOF_VAF(numSynergy,:,fold) = 100*(1 - sum((RightFullSet - RightApprox).^2,1) ./ sum((RightFullSet).^2,1));
                    LeftDOF_VAF(numSynergy,:,fold) = 100*(1 - sum((LeftFullSet - LeftApprox).^2,1) ./ sum((LeftFullSet).^2,1));
                end

                if GoodTrainR==0 & RightVAF(numSynergy,fold)>90 & DeltaRightVAF(numSynergy,fold)<5 & RightDOF_VAF(numSynergy,:,fold)>65
                    ndim_R = numSynergy;
                    VAF_R = RightVAF(numSynergy,fold);
                    DeltaVAF_R = DeltaRightVAF(numSynergy,fold);
                    DOF_VAF_R = RightDOF_VAF(numSynergy,:,fold);
                    GoodTrainR = 1
                    Synergies_R = SynergiesRightTrAll;
                    Scores_R = ScoresRightTrTemp;
                end
                if GoodTrainL==0 & LeftVAF(numSynergy,fold)>90 & DeltaLeftVAF(numSynergy,fold)<5 & LeftDOF_VAF(numSynergy,:,fold)>65
                    ndim_L = numSynergy;
                    VAF_L = LeftVAF(numSynergy,fold);
                    DeltaVAF_L = DeltaLeftVAF(numSynergy,fold);
                    DOF_VAF_L = LeftDOF_VAF(numSynergy,:,fold);
                    GoodTrainL = 1
                    Synergies_L = SynergiesLeftTrAll;
                    Scores_L = ScoresLeftTrTemp;
                end
                             
                numSynergy = numSynergy+1;
                if numSynergy == DOF
                    if GoodTrainR==0 || GoodTrainL==0 
                        numSynergy = 1;
                    end
                end
                if GoodTrainR==1 && GoodTrainL==1 
                        numSynergy = DOF; %terminate training
                end
            end          
           
            %%%%validation

            %reconstruct the data 
            RightApprox = Scores_R * Synergies_R;
            LeftApprox = Scores_L * Synergies_L;

            %avg reconstruction error of each data point (degrees)
            AvgReconsErr_R = (1/size(RightFullSet,1))*sum((1/DOF*sum((RightFullSet-RightApprox).^2,2)).^0.5); %10 DOF
            AvgReconsErr_L = (1/size(LeftFullSet,1))*sum((1/DOF*sum((LeftFullSet -LeftApprox).^2,2)).^0.5); %10 DOF

            %correlation coefficient (slope)

            for temp = 1:DOF %10 DOFs
               [AllregcoeffRTrain(fold,temp), bint, r, rint, stats] = regress(RightApprox(:,temp), RightFullSet(:,temp));
               [AllregcoeffLTrain(fold,temp), bint, r, rint, stats] = regress(LeftApprox(:,temp), LeftFullSet(:,temp));
            end
            RegCoeff_R = sum(AllregcoeffRTrain(fold,:),2)/DOF;%Average correlation coefficient
            RegCoeff_L = sum(AllregcoeffLTrain(fold,:),2)/DOF;

            %dim of common subspace (weak measure)
            for i = 1:ndim_L
                for j = 1:ndim_R
                    AllCommonCoeff(i,j) = regress(Synergies_L(i,:)', Synergies_R(j,:)');
                end
            end
            nCommonAll = 0; 
            for i = 1:ndim_L
                if max(abs(AllCommonCoeff(i,:)))>0.8
                    nCommonAll = nCommonAll+1;
                end
            end
            nCommonAll = nCommonAll/max(ndim_L, ndim_R);

        end
        timeElapsed = toc;

               
        %% save the synergies
            if HandStrength(subjectcounter) == 1
                SubjStrongHand = 'R';
                save(strcat('S', SubjID, '_Strong_Synergies.mat'), ...
                    'VAF_R', 'DeltaVAF_R', 'DOF_VAF_R', 'Synergies_R', ...
                    'Scores_R', 'ndim_R', 'AvgReconsErr_R', 'RegCoeff_R', ...
                    'nCommonAll', 'SubjStrongHand', 'timeElapsed');
                
                SubjWeakHand = 'L';
                save(strcat('S', SubjID, '_Weak_Synergies.mat'), ...
                    'VAF_L', 'DeltaVAF_L', 'DOF_VAF_L', 'Synergies_L', ...
                    'Scores_L', 'ndim_L', 'AvgReconsErr_L', 'RegCoeff_L', ...
                    'nCommonAll', 'SubjWeakHand', 'timeElapsed');
            else
                SubjStrongHand = 'L';
                save(strcat('S', SubjID, '_Strong_Synergies.mat'), ...
                    'VAF_L', 'DeltaVAF_L', 'DOF_VAF_L', 'Synergies_L', ...
                    'Scores_L', 'ndim_L', 'AvgReconsErr_L', 'RegCoeff_L', ...
                    'nCommonAll', 'SubjStrongHand', 'timeElapsed');
                
                SubjWeakHand = 'R';
                save(strcat('S', SubjID, '_Weak_Synergies.mat'), ...
                    'VAF_R', 'DeltaVAF_R', 'DOF_VAF_R', 'Synergies_R', ...
                    'Scores_R', 'ndim_R', 'AvgReconsErr_R', 'RegCoeff_R', ...
                    'nCommonAll', 'SubjWeakHand', 'timeElapsed');
                
            end      
        
        %% Plotting function(when you call the main function, edit to define which hand is dominant/stronger)
        
        %%use when right hand is not affected

        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(LeftPC1,'DisplayName','LeftPC1')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(RightPC1,'DisplayName','RightPC1')
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 1                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(LeftPC2,'DisplayName','LeftPC2')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(RightPC2,'DisplayName','RightPC2')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 2                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(LeftPC3,'DisplayName','LeftPC3')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(RightPC3,'DisplayName','RightPC3')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 3                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(LeftPC4,'DisplayName','LeftPC4')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(RightPC4,'DisplayName','RightPC4')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 4                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(LeftPC5,'DisplayName','LeftPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(RightPC5,'DisplayName','RightPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 5                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(5,2,1)
        % % % % bar(LeftPC1,'DisplayName','LeftPC1')
        % % % % axis([0 11 -1 1])
        % % % % subplot(5,2,2)
        % % % % bar(RightPC1,'DisplayName','RightPC1')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 1                                                           .'))
        % % % % 
        % % % % subplot(5,2,3)
        % % % % bar(LeftPC2,'DisplayName','LeftPC2')
        % % % % axis([0 11 -1 1])
        % % % % subplot(5,2,4)
        % % % % bar(RightPC2,'DisplayName','RightPC2')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 2                                                           .'))
        % % % % 
        % % % % 
        % % % % subplot(5,2,5)
        % % % % bar(LeftPC3,'DisplayName','LeftPC3')
        % % % % axis([0 11 -1 1])
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(5,2,6)
        % % % % bar(RightPC3,'DisplayName','RightPC3')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 3                                                           .'))
        % % % % 
        % % % % subplot(5,2,7)
        % % % % bar(LeftPC4,'DisplayName','LeftPC4')
        % % % % axis([0 11 -1 1])
        % % % % subplot(5,2,8)
        % % % % bar(RightPC4,'DisplayName','RightPC4')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 4                                                           .'))
        % % % % 
        % % % % subplot(5,2,9)
        % % % % bar(LeftPC5,'DisplayName','LeftPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % subplot(5,2,10)
        % % % % bar(RightPC5,'DisplayName','RightPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 5                                                           .'))


        %%use when left hand is not impaired
        
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(RightPC1,'DisplayName','RightPC1')
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % axis([0 11 -1 1])
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(LeftPC1,'DisplayName','LeftPC1')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 1                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(RightPC2,'DisplayName','RightPC2')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(LeftPC2,'DisplayName','LeftPC2')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 2                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(RightPC3,'DisplayName','RightPC3')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(LeftPC3,'DisplayName','LeftPC3')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 3                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(RightPC4,'DisplayName','RightPC4')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(LeftPC4,'DisplayName','LeftPC4')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 4                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(1,2,1)
        % % % % bar(RightPC5,'DisplayName','RightPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(1,2,2)
        % % % % bar(LeftPC5,'DisplayName','LeftPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 5                                                           .'))
        % % % % 
        % % % % figure()
        % % % % subplot(5,2,1)
        % % % % bar(RightPC1,'DisplayName','RightPC1')
        % % % % axis([0 11 -1 1])
        % % % % subplot(5,2,2)
        % % % % bar(LeftPC1,'DisplayName','LeftPC1')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 1                                                           .'))
        % % % % 
        % % % % subplot(5,2,3)
        % % % % bar(RightPC2,'DisplayName','RightPC2')
        % % % % axis([0 11 -1 1])
        % % % % subplot(5,2,4)
        % % % % bar(LeftPC2,'DisplayName','LeftPC2')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 2                                                           .'))
        % % % % 
        % % % % 
        % % % % subplot(5,2,5)
        % % % % bar(RightPC3,'DisplayName','RightPC3')
        % % % % axis([0 11 -1 1])
        % % % % ylabel('Normalized Weight of Each DOF')
        % % % % subplot(5,2,6)
        % % % % bar(LeftPC3,'DisplayName','LeftPC3')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 3                                                           .'))
        % % % % 
        % % % % subplot(5,2,7)
        % % % % bar(RightPC4,'DisplayName','RightPC4')
        % % % % axis([0 11 -1 1])
        % % % % subplot(5,2,8)
        % % % % bar(LeftPC4,'DisplayName','LeftPC4')
        % % % % axis([0 11 -1 1])
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 4                                                           .'))
        % % % % 
        % % % % subplot(5,2,9)
        % % % % bar(RightPC5,'DisplayName','RightPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Impaired Arm')
        % % % % subplot(5,2,10)
        % % % % bar(LeftPC5,'DisplayName','LeftPC5')
        % % % % axis([0 11 -1 1])
        % % % % xlabel('Kinematic DOFs of Unimpaired Arm')
        % % % % title(strcat('SS', num2str(subjectID),' Kinematic Synergy Vector 5                                                           .'))
        
% % %         figure()
% % %         subplot(5,2,1)
% % %         bar(LeftPC1','DisplayName','LeftPC1')
% % %         axis([0 11 -1 1])
% % %         subplot(5,2,2)
% % %         bar(RightPC1','DisplayName','RightPC1')
% % %         axis([0 11 -1 1])
% % %         title(strcat('SS', num2str(1),' Kinematic Synergy Vector 1                                                           .'))
% % %         
% % %         subplot(5,2,3)
% % %         bar(LeftPC2','DisplayName','LeftPC2')
% % %         axis([0 11 -1 1])
% % %         subplot(5,2,4)
% % %         bar(RightPC2','DisplayName','RightPC2')
% % %         axis([0 11 -1 1])
% % %         title(strcat('SS', num2str(1),' Kinematic Synergy Vector 2                                                           .'))
% % %         
% % %         
% % %         subplot(5,2,5)
% % %         bar(LeftPC3','DisplayName','LeftPC3')
% % %         axis([0 11 -1 1])
% % %         ylabel('Normalized Weight of Each DOF')
% % %         subplot(5,2,6)
% % %         bar(RightPC3','DisplayName','RightPC3')
% % %         axis([0 11 -1 1])
% % %         title(strcat('SS', num2str(1),' Kinematic Synergy Vector 3                                                           .'))
% % %         
% % %         subplot(5,2,7)
% % %         bar(LeftPC4','DisplayName','LeftPC4')
% % %         axis([0 11 -1 1])
% % %         subplot(5,2,8)
% % %         bar(RightPC4','DisplayName','RightPC4')
% % %         axis([0 11 -1 1])
% % %         title(strcat('SS', num2str(1),' Kinematic Synergy Vector 4                                                           .'))
% % %         
% % %         subplot(5,2,9)
% % %         bar(LeftPC5','DisplayName','LeftPC5')
% % %         axis([0 11 -1 1])
% % %         xlabel('Kinematic DOFs of Impaired Arm')
% % %         subplot(5,2,10)
% % %         bar(RightPC5','DisplayName','RightPC5')
% % %         axis([0 11 -1 1])
% % %         xlabel('Kinematic DOFs of Unimpaired Arm')
% % %         title(strcat('SS', num2str(1),' Kinematic Synergy Vector 5                                                           .'))
% % % 
% % % 
% % %         figure()
% % %         subplot(5,2,1)
% % %         bar(LeftPC1Avg,'DisplayName','LeftPC1')
% % %         axis([0 11 -1 1])
% % %         subplot(5,2,2)
% % %         bar(RightPC1Avg,'DisplayName','RightPC1')
% % %         axis([0 11 -1 1])
% % %         title(strcat('Subj ', num2str(1),' Muscle Synergy Vector 1                                                           .'))
% % %         
% % %         subplot(5,2,3)
% % %         bar(LeftPC2Avg,'DisplayName','LeftPC2')
% % %         axis([0 11 -1 1])
% % %         subplot(5,2,4)
% % %         bar(RightPC2Avg,'DisplayName','RightPC2')
% % %         axis([0 11 -1 1])
% % %         title(strcat('Subj ', num2str(1),' Muscle Synergy Vector 2                                                           .'))
% % %         
% % %         
% % %         subplot(5,2,5)
% % %         bar(LeftPC3Avg,'DisplayName','LeftPC3')
% % %         axis([0 11 -1 1])
% % %         ylabel('Normalized Weight of Each DOF')
% % %         subplot(5,2,6)
% % %         bar(RightPC3Avg,'DisplayName','RightPC3')
% % %         axis([0 11 -1 1])
% % %         title(strcat('Subj ', num2str(1),' Muscle Synergy Vector 3                                                           .'))
% % %         
% % %         subplot(5,2,7)
% % %         bar(LeftPC4Avg,'DisplayName','LeftPC4')
% % %         axis([0 11 -1 1])
% % %         subplot(5,2,8)
% % %         bar(RightPC4Avg,'DisplayName','RightPC4')
% % %         axis([0 11 -1 1])
% % %         title(strcat('Subj ', num2str(1),' Muscle Synergy Vector 4                                                           .'))
% % %         
% % %         subplot(5,2,9)
% % %         bar(LeftPC5Avg,'DisplayName','LeftPC5')
% % %         axis([0 11 -1 1])
% % %         xlabel('Muscle DOFs of Left Arm')
% % %         subplot(5,2,10)
% % %         bar(RightPC5Avg,'DisplayName','RightPC5')
% % %         axis([0 11 -1 1])
% % %         xlabel('Muscle DOFs of Right Arm')
% % %         title(strcat('Subj ', num2str(1),' Muscle Synergy Vector 5                                                           .'))
    
    end
end