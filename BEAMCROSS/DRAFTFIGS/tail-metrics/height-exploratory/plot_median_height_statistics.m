function plot_median_height_statistics
% Match the posture/slip figure: individual mice, cage means, mouse means.
here=fileparts(mfilename('fullpath')); t=readtable(fullfile(here,'mouse-day-motion-height.csv'),'TextType','string');p=readtable(fullfile(here,'group-comparisons.csv'),'TextType','string');
assert(all(ismember(["D00","D07","D14"],unique(t.day))));
% Keep original four-panel layout; provide D7-D0 as a separate companion.
makeFigure(t,p,["D00","D07","D14","D14-D00"],fullfile(here,'median-motion-height-statistics'));
makeFigure(t,p,"D07-D00",fullfile(here,'median-motion-height-D07-minus-D00-statistics'));
end
function makeFigure(t,p,periods,base)
groups=["sedentary","walk","run"]; colors=[0 0 0;0 141 63;8 100 207]/255;
fig=figure('Color','w','Visible','off','Units','pixels','Position',[70 70 650*numel(periods) 780]);lay=tiledlayout(fig,1,numel(periods),'TileSpacing','compact','Padding','compact');rng(42);
% Fixed scales within the three day panels and within the change panels.
allDays=t.medianHeight(isfinite(t.medianHeight)); allChanges=[];
for later=["D07","D14"]
 a=t(t.day==later,:);b=t(t.day=="D00",:);[ok,idx]=ismember(a.mouseID,b.mouseID);assert(all(ok));allChanges=[allChanges;a.medianHeight-b.medianHeight(idx)]; %#ok<AGROW>
end
for d=1:numel(periods)
 period=periods(d);ax=nexttile(lay);hold(ax,'on');isChange=contains(period,'-');
 for g=1:3
  if ~isChange,a=t(t.day==period & t.group==groups(g),:);values=a.medianHeight;
  else
   later=extractBefore(period,'-');a=t(t.day==later & t.group==groups(g),:);b=t(t.day=="D00" & t.group==groups(g),:);[found,idx]=ismember(a.mouseID,b.mouseID);assert(all(found));values=a.medianHeight-b.medianHeight(idx);
  end
  assert(all(isfinite(values)));scatter(ax,g+(rand(height(a),1)-.5)*.3,values,35,colors(g,:),'filled','MarkerFaceAlpha',.4);
  cages=unique(a.cageID);for j=1:numel(cages),mu=mean(values(a.cageID==cages(j)));scatter(ax,g-.26,mu,53,'d','MarkerFaceColor',colors(g,:),'MarkerEdgeColor','k');end
  mu=mean(values);plot(ax,[g-.16 g+.16],[mu mu],'Color',colors(g,:),'LineWidth',3);
 end
 set(ax,'XTick',1:3,'XTickLabel',groups);xlim(ax,[.5 3.5]);grid(ax,'on');
 if ~isChange
  low=min(0,floor(min(allDays)/5)*5); high=ceil(max(allDays)/5)*5; span=high-low;ylim(ax,[low high+.42*span]);title(ax,period);ylabel(ax,'Median motion height (mm)');
 else
  lo=floor(min(allChanges)/5)*5;hi=ceil(max(allChanges)/5)*5;span=hi-lo;ylim(ax,[lo hi+.42*span]);title(ax,replace(period,'-',' − ')+", within mouse");ylabel(ax,'Change in median motion height (mm)');yline(ax,0,':','Color',[.4 .4 .4],'HandleVisibility','off');
 end
 q=p(p.metric=="medianHeight" & p.period==period,:);assert(height(q)==3);
 sw=q(q.pair=="walk minus sedentary",:);sr=q(q.pair=="run minus sedentary",:);wr=q(q.pair=="run minus walk",:);
 text(ax,.04,.97,sprintf('Overall p raw=%.3f\nPairs raw: S–W %.3f  S–R %.3f  W–R %.3f\nPairs Holm: S–W %.3f  S–R %.3f  W–R %.3f',q.overallP(1),sw.p_raw,sr.p_raw,wr.p_raw,sw.p_holm_3_pairs,sr.p_holm_3_pairs,wr.p_holm_3_pairs),'Units','normalized','VerticalAlignment','top','FontSize',10);
end
title(lay,{'Median height of detected post-mouse motion','Circles: mice; diamonds: cage means; bars: mouse means','Exploratory cage-level tests within cohort; Holm: three group pairs per panel'});
savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');
end
