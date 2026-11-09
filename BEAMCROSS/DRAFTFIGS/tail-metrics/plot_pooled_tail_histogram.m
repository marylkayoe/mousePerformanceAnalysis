folder=fileparts(mfilename('fullpath')); t=readtable(fullfile(folder,'pooled-position-bin-summary.csv'));days=[0 14];cols=[.12 .39 .68;.82 .29 .17];
fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1450 850]);lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(lay);hold(ax,'on');
for d=1:2
 a=t(t.Day==days(d),:); x=5:10:695; mu=nan(size(x)); n=zeros(size(x)); mu(a.Bin+1)=a.mean;n(a.Bin+1)=a.nMice;
 bar(ax,x,mu,1,'FaceColor',cols(d,:),'FaceAlpha',.40,'EdgeColor','none','DisplayName',sprintf('D%d',days(d)));
end
xlim(ax,[0 700]); xticks(ax,0:100:700); grid(ax,'on');ax.GridAlpha=.15;ylabel(ax,'Mean above-bar tail-motion index (a.u.)');legend(ax,'Location','northeast'); yline(ax,0,':','HandleVisibility','off');
ax=nexttile(lay);hold(ax,'on');
for d=1:2
 a=t(t.Day==days(d),:);x=5:10:695;n=zeros(size(x));n(a.Bin+1)=a.nMice;
 stairs(ax,x,n,'Color',cols(d,:),'LineWidth',2,'DisplayName',sprintf('D%d',days(d)));
end
xlim(ax,[0 700]);ylim(ax,[0 44]);xticks(ax,0:100:700);yticks(ax,0:10:40);grid(ax,'on');ax.GridAlpha=.15;ylabel(ax,'Contributing mice'); xlabel(ax,'Position between tape marks (mm; exit 0, entry 700)');
title(lay,{'Pooled above-bar tail motion by position: D0 and D14','10 mm bins; mouse means pooled across groups; all bins with valid data; contributing mice shown below'});
base=fullfile(folder,'tail-above-pooled-days-histogram-10mm');savefig(fig,[base '.fig']);exportgraphics(fig,[base '.png'],'Resolution',160);print(fig,[base '.svg'],'-dsvg');
