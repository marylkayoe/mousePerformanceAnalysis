root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
p=load(fullfile(root,'BEAMCROSS/DRAFTFIGS/tail-metrics/example-row-profiles/TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4.profiles.mat'),'P');e=load(fullfile(root,'BEAMCROSS/results/running_column_export_L40_halfdepth_20261109/column_contributions.mat'),'E');
P=p.P;E=e.E;assert(size(P.probabilityWeighted,2)==678 && isequal(P.invalidFramePairMask(:),E.invalidFramePairMask(:)));writematrix(P.probabilityWeighted','/private/tmp/run-movie-row-profiles.csv');fprintf('BAR_TOP=%d BAR_WIDTH=%d\n',E.barTopOriginal,E.barWidth);

f=figure('Visible','off','Color','white','Units','pixels','Position',[50 50 1100 820],'PaperPositionMode','auto');ax=axes(f,'Position',[0 0 1 1],'Units','normalized');set(ax,'XLim',[0 1100],'YLim',[0 820],'YDir','reverse','Visible','off');hold(ax,'on');
text(ax,80,23,'Post-mouse crop: D14 running example','FontSize',12,'FontWeight','bold');
text(ax,620,23,'Motion by height','Color',[.5 .1 .65],'FontSize',12,'FontWeight','bold');
text(ax,870,23,'Motion height','FontSize',12,'FontWeight','bold');
text(ax,870,43,'(mm from bar)','FontSize',10);
text(ax,870,84,'Original frame','FontSize',10);
text(ax,80,791,'Green: above-bar motion    Red: corrected below-bar motion    Purple: weighted motion by height','FontSize',10);
text(ax,80,808,'Fixed scales; 30 fps viewing playback; flagged frame pairs show no profiles or height','FontSize',10);
line(ax,[610 830],[50+2*208 50+2*208],'Color',[.6 .6 .6],'LineStyle','--');
print(f,'/private/tmp/tail-demo-background.png','-dpng','-r0');
