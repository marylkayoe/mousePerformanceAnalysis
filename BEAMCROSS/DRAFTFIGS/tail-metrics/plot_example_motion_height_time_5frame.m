folder=fileparts(mfilename('fullpath'));t=readtable(fullfile(folder,'example-motion-height-time-frames.csv'),'TextType','string');
groups={'sedentary','run'};names={'Sedentary TMCS3\_S09 — D14 trial 2','Run TMCS2\_S18 — D14 trial 2'};colors=[0 0 0;8 100 207]/255;
fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1450 900]);lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
for k=1:2
 a=t(t.Group==groups{k},:);ax=nexttile(lay);hold(ax,'on');
 valid=isfinite(a.MotionHeightMM); z=nan(size(a.MotionHeightMM)); starts=find(diff([false;valid;false])==1); ends=find(diff([false;valid;false])==-1)-1;
 for j=1:numel(starts),ii=starts(j):ends(j);z(ii)=movmean(a.MotionHeightMM(ii),5);end
 plot(ax,a.ElapsedSeconds,z,'Color',colors(k,:),'LineWidth',1.2,'DisplayName','Motion-weighted height');
 yline(ax,0,'--','Color',[.4 .4 .4],'LineWidth',1.2,'DisplayName','Detected bar top');
 xlim(ax,[0 5.5]);ylim(ax,[-20 65]);grid(ax,'on');title(ax,names{k});xlabel(ax,'Time since start of tracked crossing (s)');ylabel(ax,{'Motion-weighted height','relative to bar (mm)'});if k==1,legend(ax,'Location','northeast');end
end
title(lay,{'Height of detected post-mouse motion over time','D14 trial 2; 5-frame moving mean; gaps indicate invalid measurements'});
base=fullfile(folder,'example-motion-weighted-height-by-time-D14-5frame');savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');
