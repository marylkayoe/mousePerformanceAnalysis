function plotEntranceDetectorStages
out='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_entry_review_20261107';
dest=fullfile(out,'detector_figures');if ~exist(dest,'dir'),mkdir(dest);end
groups=["sedentary","walk","run"];colors=[.3 .3 .3;.0 .45 .75;.85 .25 .1];
S=readtable(fullfile(out,'all_D0_speed_summary.csv'),'TextType','string');
bins=["0","(0,5]","(5,20]","(20,40]","(40,100]",">100"];
f=figure('Visible','off','Position',[50 50 1350 900],'Color','w');t=tiledlayout(2,2,'TileSpacing','compact');
nexttile;hold on
for g=1:3
 a=S(S.Group==groups(g),:);[~,idx]=ismember(bins,a.SpeedBin);v=a.Seconds(idx);plot(1:6,100*v/sum(v),'-o','Color',colors(g,:),'DisplayName',groups(g));
end
xticks(1:6);xticklabels(bins);xlabel('Forward speed (pixels/s)');ylabel('% of group entry time');title('All eligible D0 crossings: exposure');legend('Location','best');grid on
nexttile;hold on
for g=1:3
 a=S(S.Group==groups(g),:);[~,idx]=ismember(bins,a.SpeedBin);plot(1:6,100*a.AboveThresholdFraction(idx),'-o','Color',colors(g,:),'DisplayName',groups(g));
end
xticks(1:6);xticklabels(bins);xlabel('Forward speed (pixels/s)');ylabel('% frames with final trace > 2.5');title('Frame exceedance, before event morphology');grid on
M=readtable(fullfile(out,'detector_stage_mouse_summary.csv'),'TextType','string');nexttile;hold on
for g=1:3
 a=M(M.Group==groups(g),:);scatter(a.MedianSpeed,a.MedianRawWeighted,65,colors(g,:),'filled');
 for i=1:height(a),text(a.MedianSpeed(i),a.MedianRawWeighted(i)," "+a.MouseID(i),'Interpreter','none','FontSize',7);end
end
xlabel('Mouse median entry speed (pixels/s)');ylabel('Mouse median raw weighted motion');title('Reviewed trials: one point per mouse');grid on
R=readtable(fullfile(out,'detector_raw_amplitude_strata.csv'),'TextType','string');nexttile;hold on
for g=1:3
 a=R(R.Group==groups(g),:);plot(a.RawWeightedBin,100*a.FractionAboveThreshold,'-o','Color',colors(g,:));
end
xticks(1:4);xlabel('Shared weighted raw-motion quartile');ylabel('% frames with final trace > 2.5');title('Reviewed trials; descriptive, time-weighted');grid on
title(t,{'D0 entry detector behavior | camera-field fraction 0.90-0.95','Frames/events are not independent animals; purposeful visual sample for lower panels'});
exportgraphics(f,fullfile(dest,'group_detector_behavior.png'),'Resolution',140);close(f)

E=readtable(fullfile(out,'reviewed_event_detector_stages.csv'),'TextType','string');
P=readtable(fullfile(out,'comparable_raw_event_pairs.csv'),'TextType','string');
% Purposeful qualified examples: low speed, baseline contrast, and both cohorts.
selected=table();
comparisons=["BLIND_07","BLIND_11";"BLIND_02","BLIND_06";"BLIND_17","BLIND_23";"BLIND_01","BLIND_05"];
for k=1:4
 use=P.ReviewA==comparisons(k,1)&P.ReviewB==comparisons(k,2);pair=P(use,:);assert(height(pair)==1);selected=[selected;pair]; %#ok<AGROW>
 f=figure('Visible','off','Position',[50 50 1300 1200],'Color','w');layout=tiledlayout(6,2,'TileSpacing','compact');
 ids=[pair.ReviewA,pair.ReviewB];
 for col=1:2
  ev=E(E.ReviewID==ids(col),:);D=readtable(fullfile(out,'detector_stages',char(ev.File+".csv")));
  D=D(D.OriginalFrame>=ev.StartOriginalFrame-48&D.OriginalFrame<=ev.EndOriginalFrame+48,:);
  fields={'RawUnweighted','RawWeighted','SpeedMultiplier','SpeedAdjusted','Smoothed','FinalTrace'};
  labels={'Raw unweighted','Raw weighted','160 / log1p(speed)','Speed adjusted','Smoothed adjusted','Final normalized'};
  for r=1:6
   nexttile((r-1)*2+col);y=D.(fields{r});y(~isfinite(y))=NaN;plot(D.OriginalFrame,y,'k');hold on
   xline(ev.StartOriginalFrame,'b:');xline(ev.EndOriginalFrame,'b:');
   if r==5,yline(ev.PreNormalizedThreshold,'r--');end
   if r==6,yline(2.5,'r--');end
   ylabel(labels{r});grid on
   if r==1,title(sprintf('%s | %s | %s',ids(col),ev.Group,ev.MouseID),'Interpreter','none');end
   if r==6,xlabel('Original video frame');end
  end
 end
 title(layout,{sprintf('Comparable weighted raw peaks | ratio %.3f | %s',pair.RawPeakRatioAoverB,pair.Cohort),'Same cohort; duration within factor 2; not matched anatomy/full waveform. Separate y scales.'});
 exportgraphics(f,fullfile(dest,sprintf('raw_matched_pair_%d.png',k)),'Resolution',140);close(f)
end
writetable(selected,fullfile(out,'plotted_comparable_pairs.csv'));

name='TMCS3_S07_T1_C03_BB_D00_20260219_THT_TRIAL4_gray.mp4';
D=readtable(fullfile(out,'detector_stages',[name '.csv']));D=D(D.OriginalFrame>=1069&D.OriginalFrame<=1935,:);
f=figure('Visible','off','Position',[50 50 1250 1100],'Color','w');layout=tiledlayout(6,1,'TileSpacing','compact');
fields={'RawWeighted','ForwardSpeed','SpeedMultiplier','SpeedAdjusted','Smoothed','FinalTrace'};
for i=1:6
 nexttile;y=D.(fields{i});y(~isfinite(y))=NaN;plot(D.OriginalFrame,y,'k');hold on;xline(1756,'b:');xline(1777,'b:');ylabel(fields{i},'Interpreter','none');grid on
 if i==6,yline(2.5,'r--');xlabel('Original video frame');end
end
title(layout,{'TMCS3_S07 D0 trial 4 | unchanged detector stages','Blue lines bracket zero gap 1756-1777; nonfinite intermediate values appear as gaps, not zeros'});
exportgraphics(f,fullfile(dest,'target_detector_stages.png'),'Resolution',140);close(f)
end
