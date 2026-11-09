folder=fileparts(mfilename('fullpath'));t=readtable(fullfile(folder,'example-motion-height-time-frames.csv'),'TextType','string');
files={'TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4','TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4'};
names={'Sedentary TMCS3\_S09 — D14 trial 2','Run TMCS2\_S18 — D14 trial 2'};factor=700/1201;bandMM=5;
fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1450 900]);lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');allrows=table; summary=table;
for k=1:2
 a=t(t.File==files{k},:);z=load(fullfile(folder,'example-row-profiles',[files{k} '.profiles.mat']),'P');P=z.P;
 h=double(P.rowHeightRelativeToBar(:))*factor; w=double(P.probabilityWeighted); assert(size(w,2)==height(a));
 exclude=h>=0 & h<bandMM; result=nan(height(a),4); excludedFraction=nan(height(a),1);
 for j=1:height(a)
  v=w(:,j); if P.invalidFramePairMask(j)||any(~isfinite(v))||any(v<0)||sum(v)<=0, continue; end
  total=sum(v);excludedFraction(j)=sum(v(exclude))/total;
  for c=1:2
   x=v; if c==2,x(exclude)=0;end;total2=sum(x); if total2<=0,continue;end
   result(j,2*c-1)=sum(x.*h)/total2;
   idx=find(cumsum(x)>=total2/2,1,'first');result(j,2*c)=h(idx);
  end
 end
 curves=nan(size(result));
 for c=1:4
  v=result(:,c);ok=isfinite(v);starts=find(diff([false;ok;false])==1);ends=find(diff([false;ok;false])==-1)-1;
  for j=1:numel(starts),ii=starts(j):ends(j);curves(ii,c)=movmean(v(ii),5);end
 end
 valid=isfinite(result(:,1))&isfinite(a.MotionHeightMM); assert(max(abs(result(valid,1)-a.MotionHeightMM(valid)))<.001);
 ax=nexttile(lay);hold(ax,'on');plot(ax,a.ElapsedSeconds,curves(:,2),'Color',[.35 .35 .35],'LineWidth',1.2,'DisplayName','All rows');plot(ax,a.ElapsedSeconds,curves(:,4),'Color',[.05 .38 .68],'LineWidth',1.4,'DisplayName','Exclude 0 to <5 mm above bar');yline(ax,0,'--','Color',[.5 .5 .5],'HandleVisibility','off');xlim(ax,[0 max(a.ElapsedSeconds)]);grid(ax,'on');title(ax,names{k});xlabel(ax,'Time since start of tracked crossing (s)');ylabel(ax,{'Weighted median motion height','relative to bar (mm)'});if k==1,legend(ax,'Location','best');end
 r=table(repmat(string(files{k}),height(a),1),a.TraversalFrame,a.OriginalFrame,a.ElapsedSeconds,result(:,1),result(:,3),result(:,2),result(:,4),curves(:,1),curves(:,3),curves(:,2),curves(:,4),excludedFraction,'VariableNames',{'File','TraversalFrame','OriginalFrame','ElapsedSeconds','MeanAllMM','MeanExcludeMM','MedianAllMM','MedianExcludeMM','MeanAllSmoothedMM','MeanExcludeSmoothedMM','MedianAllSmoothedMM','MedianExcludeSmoothedMM','ExcludedMotionFraction'});allrows=[allrows;r];
 paired=all(isfinite(result),2);deltaMean=result(paired,3)-result(paired,1);deltaMedian=result(paired,4)-result(paired,2);
 s=table(string(files{k}),sum(paired),sum(isfinite(result(:,2))&~isfinite(result(:,4))),mean(deltaMean,'omitnan'),median(deltaMean,'omitnan'),mean(deltaMedian,'omitnan'),median(deltaMedian,'omitnan'),mean(abs(deltaMean),'omitnan'),mean(abs(deltaMedian),'omitnan'),mean(excludedFraction(paired),'omitnan'),'VariableNames',{'File','PairedFrames','LostFrames','MeanMeanDifferenceMM','MedianMeanDifferenceMM','MeanMedianDifferenceMM','MedianMedianDifferenceMM','MeanAbsMeanDifferenceMM','MeanAbsMedianDifferenceMM','MeanExcludedMotionFraction'});summary=[summary;s];
end
title(lay,{'Weighted median motion height: removing motion just above the bar','5-frame mean; below-bar motion retained; these are two example crossings'});
base=fullfile(folder,'example-median-height-exclude-0to5mm-D14');writetable(allrows,[base '.csv']);writetable(summary,[base '-summary.csv']);savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');disp(summary);
