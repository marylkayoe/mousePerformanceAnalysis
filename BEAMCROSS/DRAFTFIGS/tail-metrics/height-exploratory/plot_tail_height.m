function plot_tail_height
here=fileparts(mfilename('fullpath'));T=readtable(fullfile(here,'mouse-day-motion-height.csv'),'TextType','string');
groups=["sedentary","walk","run"];colors=[0.1 0.1 0.1;0 .52 .25;.05 .36 .76];days=["D00","D07","D14"];
metrics={'meanHeight','medianHeight','sdHeight','iqrHeight'};labels={'Mean of motion heights (mm)','Median of motion heights (mm)','Within-crossing SD (mm)','Within-crossing IQR (mm)'};
f=figure('Color','w','Visible','off','Position',[50 50 1650 800]);lay=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
for k=1:numel(metrics)
 ax=nexttile(lay);hold(ax,'on'); metric=metrics{k};handles=gobjects(1,3);
 for g=1:3
  C=colors(g,:);light=.82+.18*C;G=T(T.group==groups(g),:);mice=unique(G.mouseID);
  for i=1:numel(mice)
   M=G(G.mouseID==mice(i),:);v=nan(1,3);
   for d=1:3,z=M.(metric)(M.day==days(d));if numel(z)==1,v(d)=z;end,end
   plot(ax,1:3,v,'Color',light,'LineWidth',.6,'HandleVisibility','off');
  end
  mu=nan(1,3);se=mu;
  for d=1:3,v=G.(metric)(G.day==days(d));v=v(isfinite(v));mu(d)=mean(v);se(d)=std(v)/sqrt(numel(v));end
  handles(g)=errorbar(ax,(1:3)+(g-2)*.035,mu,se,'-o','Color',C,'MarkerFaceColor',C,'LineWidth',2,'MarkerSize',5,'DisplayName',groups(g));
 end
 xlim(ax,[.75 3.25]);xticks(ax,1:3);xticklabels(ax,{'D0','D7','D14'});ylabel(ax,labels{k});grid(ax,'on');title(ax,labels{k});
 if k==1,legend(ax,handles,'Location','best');end
end
title(lay,{'Motion-height summaries by group and day','Pale: mice; bold: group mean ± SEM; each crossing equally weighted within mouse'});
base=fullfile(here,'motion-height-group-day');savefig(f,[base '.fig']);exportgraphics(f,[base '.png'],'Resolution',160);print(f,[base '.svg'],'-dsvg');
% Distribution of paired D14-D0 changes, showing cage means separately.
f=figure('Color','w','Visible','off','Position',[50 50 1650 800]);lay=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
for k=1:numel(metrics)
 ax=nexttile(lay);hold(ax,'on');metric=metrics{k};
 for g=1:3
  G=T(T.group==groups(g),:);mice=unique(G.mouseID);vals=[];cages=strings(0,1);
  for i=1:numel(mice)
   M=G(G.mouseID==mice(i),:);a=M.(metric)(M.day=="D00");b=M.(metric)(M.day=="D14");
   if numel(a)==1&&numel(b)==1&&isfinite(a)&&isfinite(b),vals(end+1)=b-a;cages(end+1)=M.cageID(1);end %#ok<AGROW>
  end
  jitter=linspace(-.13,.13,numel(vals));scatter(ax,g+jitter,vals,27,colors(g,:),'filled','MarkerFaceAlpha',.38,'MarkerEdgeAlpha',.38);
  uniqueCages=unique(cages);
  for j=1:numel(uniqueCages),cv=mean(vals(cages==uniqueCages(j)));scatter(ax,g-.24,cv,45,colors(g,:),'d','filled','MarkerEdgeColor','w');end
  plot(ax,[g-.15 g+.15],[mean(vals) mean(vals)],'Color',colors(g,:),'LineWidth',3);
 end
 yline(ax,0,':','Color',[.5 .5 .5]);xlim(ax,[.5 3.5]);xticks(ax,1:3);xticklabels(ax,cellstr(groups));ylabel(ax,'D14 − D0 (mm)');title(ax,labels{k});grid(ax,'on');
end
title(lay,{'Between-group comparison of changes in repeatedly measured mice','Circles: mice; diamonds: cage means; bars: mouse means; exploratory'});
base=fullfile(here,'motion-height-d14-minus-d0');savefig(f,[base '.fig']);exportgraphics(f,[base '.png'],'Resolution',160);print(f,[base '.svg'],'-dsvg');
end
