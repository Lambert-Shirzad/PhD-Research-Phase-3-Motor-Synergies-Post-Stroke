clear
clc

FM = [40,58,13,49,36,37,32,23,29,35,18,30,37,41]'; %Fugl-Meyer Score
RPS = [28,36,11,34,24,32,17,8,17,25,8,18,27,30]'; %Reaching Performance Score
TSS = [16,23,47,70,16,74,39,110,46,72,25,302,76,16]'; %time since stroke (months)
constants1 = ones(size(FM));
NumParticipants = 14;

Merged = [1.333333333	0.333333333	2
1	0	0
1.5	0.5	3
1	0	0
2.5	0.5	4
1	0	0
1.333333333	0.333333333	2
1.5	0.5	2
2	0.666666667	3
1	0	0
2.5	1	4
1.333333333	0.333333333	2
1.5	0.333333333	2
1.333333333	0.333333333	0];

Fractionated = [0.333333333	0.666666667
0.25	0.5
0.25	0.5
0.2	0.6
0.5	1
0.2	0.4
0.333333333	0.666666667
0	0
0	0
0	0
0.5	1
0.333333333	0.666666667
0	0
0.333333333	0.666666667
];

Preserved = 100*[1
0.75
0.5
0.4
0.5
0.4
0.666666667
0.5
0.333333333
0.666666667
1
0.333333333
0.666666667
1
];

new_structure(:,1) = [0,0,1,1,0,1,0,0,0,0,0,0,0,0]';
new_structure(:,2) = [0,0,0.25,0.2,0,0.2,0,0,0,0,0,0,0,0]';

[B_mergedFM,~,~,~,S_mergedFM] = regress(100*Merged(:,2), [constants1, FM]) 
[B_mergedRPS,~,~,~,S_mergedRPS] = regress(100*Merged(:,2), [constants1, RPS]) 
%[B_fract,~,~,~,S_fract] = regress(Fractionated(:,1), [constants1, log10(TSS)]) 
[B_preserv,~,~,~,S_preserv] = regress(Preserved, [constants1, log10(TSS)]) 
figure
subplot(1,3,1)
mergeFM = [1 0;1 66]* B_mergedFM; %[constants1, FM] * B_mergedFM;
scatter(FM, 100*Merged(:,2))
hold on
plot([0,66], mergeFM)
text(35, 90, strcat('r = ',num2str(B_mergedFM(2))),'fontsize',11)
text(35, 80, strcat('p = ',num2str(S_mergedFM(3))),'fontsize',11)
xlabel('Fugl-Meyer Score')
ylabel('% Affected Arm Synergies Reconstructable by Merging')
axis([0 66 -10 110])
subplot(1,3,2)
mergeRPS = [1 0;1 36]*B_mergedRPS;% [constants1, RPS] * B_mergedRSP;
scatter(RPS, 100*Merged(:,2))
hold on
plot([0,36], mergeRPS)
text(20, 90, strcat('r = ',num2str(B_mergedRPS(2))),'fontsize',11)
text(20, 80, strcat('p = ',num2str(S_mergedRPS(3))),'fontsize',11)
xlabel('Reaching Performance Score')
ylabel('% Affected Arm Synergies Reconstructable by Merging')
axis([0 36 -10 110])
subplot(1,3,3)
preservTSS = [1 1;1 log10(500)] * B_preserv;
semilogx((TSS), Preserved, 'o')
hold on
semilogx([10 500], preservTSS)
text(250, 90, strcat('r = ',num2str(B_preserv(2))),'fontsize',11)
text(250, 80, strcat('p = ',num2str(S_preserv(3))),'fontsize',11)
xlabel('Post-stroke Duration (months)')
ylabel('% Affected Arm Synergies Preserved')
axis([10 500 -10 110])


[B_FM,~,~,~,S_FM] = regress(FM, [constants1, Merged(:,3), Fractionated(:,2), Preserved]) 
[B_RPS,~,~,~,S_RPS] = regress(RPS, [constants1, Merged(:,3), Fractionated(:,2), Preserved]) 

