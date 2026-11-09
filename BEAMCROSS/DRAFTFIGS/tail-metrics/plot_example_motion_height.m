folder=fileparts(mfilename('fullpath')); t=readtable(fullfile(folder,'example-motion-height-frames.csv'),'TextType','string');
groups={'sedentary','run'}; names={'Sedentary TMCS3\_S09 — D14 trial 2','Run TMCS2\_S18 — D14 trial 2'};colors=[0 0 0;8 100 207]/255;
fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1450 900]); lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
for k=1:2
 a=t(t.Group==groups{k},:); ax=nexttile(lay);hold(ax,'on');
 scatter(ax,a.PositionMM,a.MotionHeightMM,12,'MarkerFaceColor',colors(k,:),'MarkerEdgeColor','none','MarkerFaceAlpha',.10,'DisplayName','Individual valid frames');
 edges=0:10:700;[~,~,b]=histcounts(a.PositionMM,edges);mu=nan(1,70);
 for j=1:70, values=a.MotionHeightMM(b==j);if ~isempty(values),mu(j)=mean(values,'omitnan');end;end
 plot(ax,5:10:695,mu,'Color',colors(k,:),'LineWidth',2.2,'DisplayName','Mean in 10 mm bin');yline(ax,0,'--','Color',[.4 .4 .4],'LineWidth',1.2,'DisplayName','Detected bar top');
 xlim(ax,[0 700]);ylim(ax,[-20 65]);xticks(ax,0:100:700);grid(ax,'on');title(ax,names{k});ylabel(ax,{'Motion-weighted height','relative to bar (mm)'});xlabel(ax,'Mouse position between tape marks (mm; exit 0, entry 700)');if k==1,legend(ax,'Location','northeast');end
end
title(lay,{'Height of detected post-mouse motion along the beam','D14 trial 2; pale dots: valid frames; line: mean within each 10 mm position bin'});
base=fullfile(folder,'example-motion-weighted-height-by-position-D14');savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');
