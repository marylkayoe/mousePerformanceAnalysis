folder=fileparts(mfilename('fullpath'));t=readtable(fullfile(folder,'mouse-day-values.csv'),'TextType','string');p=readtable(fullfile(folder,'group-comparisons.csv'),'TextType','string');
groups={'sedentary','walk','run'}; colors=[0 0 0;0 141 63;8 100 207]/255; days={'D00','D07','D14'};
fig=figure('Color','w','Visible','off','Units','pixels','Position',[70 70 1750 650]);lay=tiledlayout(fig,1,4,'TileSpacing','compact','Padding','compact');rng(42);
for d=1:4
 ax=nexttile(lay);hold(ax,'on');
 for g=1:3
  if d<4
   a=t(t.day==days{d} & t.group==groups{g},:);values=a.meanLegacy;
  else
   a=t(t.day=="D14" & t.group==groups{g},:);b=t(t.day=="D00" & t.group==groups{g},:);[found,idx]=ismember(a.mouseID,b.mouseID);assert(all(found));values=a.meanLegacy-b.meanLegacy(idx);
  end
  scatter(ax,g+(rand(height(a),1)-.5)*.3,values,27,colors(g,:),'filled','MarkerFaceAlpha',.4);
  cages=unique(a.cageID);for j=1:numel(cages),mu=mean(values(a.cageID==cages(j)),'omitnan');scatter(ax,g-.26,mu,46,'d','MarkerFaceColor',colors(g,:),'MarkerEdgeColor','k');end
  mu=mean(values,'omitnan');plot(ax,[g-.16 g+.16],[mu mu],'Color',colors(g,:),'LineWidth',3);
 end
 set(ax,'XTick',1:3,'XTickLabel',groups);xlim(ax,[.5 3.5]);grid(ax,'on');
 if d<4,period=days{d};title(ax,period);ylim(ax,[0 1.8]);if d==1,ylabel(ax,'Whole-range tail-motion index (a.u.)');end
 else,period='D14-D00';title(ax,'D14 − D0, within mouse');ylim(ax,[-.8 1]);ylabel(ax,'Change in whole-range index (a.u.)');yline(ax,0,':','Color',[.4 .4 .4],'HandleVisibility','off');end
 q=p(p.metric=="Legacy" & p.period==period,:);sw=q(q.pair=="walk minus sedentary",:);sr=q(q.pair=="run minus sedentary",:);wr=q(q.pair=="run minus walk",:);
 text(ax,.04,.97,sprintf('Overall p raw=%.3f\nPairs raw: S–W %.3f  S–R %.3f  W–R %.3f\nPairs Holm: S–W %.3f  S–R %.3f  W–R %.3f',q.overallP(1),sw.p_raw,sr.p_raw,wr.p_raw,sw.p_holm_3_pairs,sr.p_holm_3_pairs,wr.p_holm_3_pairs),'Units','normalized','VerticalAlignment','top','FontSize',10);
end
title(lay,{'Reweighted whole-range tail motion across daily crossings','Circles: mice; diamonds: cage means; bars: mouse means','Exploratory cage-level tests within cohort; Holm across 3 group pairs per panel'});
base=fullfile(folder,'whole-motion-reweighted-days-and-change');set(fig,'Visible','on','WindowStyle','normal','CreateFcn',@(src,~)movegui(src,'center'));movegui(fig,'center');savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');

assert(strcmp(fig.Visible,'on')&&strcmp(fig.WindowStyle,'normal')&&~isempty(fig.CreateFcn));
close(fig);
