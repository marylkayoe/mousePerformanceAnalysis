folder=fileparts(mfilename('fullpath')); t=readtable(fullfile(folder,'example-motion-height-time-frames.csv'),'TextType','string');
a=t(t.Group=="run",:);v=a.MotionHeightMM;valid=isfinite(v);z=nan(size(v));starts=find(diff([false;valid;false])==1);ends=find(diff([false;valid;false])==-1)-1;
for k=1:numel(starts),ii=starts(k):ends(k);z(ii)=movmean(v(ii),5);end
f=figure('Visible','off','Color','white','Units','pixels','Position',[50 50 1040 280],'PaperPositionMode','auto');
ax=axes(f,'Units','pixels','Position',[90 52 900 175]);hold(ax,'on');plot(ax,a.ElapsedSeconds,z,'Color',[0.05 .35 .72],'LineWidth',1.4);yline(ax,0,'--','Color',[.5 .5 .5]);
xlim(ax,[0 4.25]);ylim(ax,[-20 65]);grid(ax,'on');ylabel(ax,{'Motion height','(mm from bar)'});xlabel(ax,'Time since start of crossing (s)');title(ax,'Height of detected image motion: 5-frame mean; red marker = current frame');
print(f,fullfile(folder,'run-motion-height-video-panel.png'),'-dpng','-r0');
