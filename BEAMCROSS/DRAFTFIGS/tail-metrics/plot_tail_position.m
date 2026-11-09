folder=fileparts(mfilename('fullpath'));
t=readtable(fullfile(folder,'group-position-bin-summary.csv'),'TextType','string');
groups={'sedentary','walk','run'}; days=[0 14]; colors=[0 0 0;0 141 63;8 100 207]/255; totals=[12 12 18];
for spread={'sem','sd'}
 measure=spread{1}; labels=upper(measure);
 for view={'by-day','by-group'}
  mode=view{1};
  if strcmp(mode,'by-day'),fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1500 1000]);lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');count=2;
  else,fig=figure('Color','w','Visible','off','Units','pixels','Position',[80 80 1650 600]);lay=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');count=3;end
  for panel=1:count
   ax=nexttile(lay);hold(ax,'on');
   for curve=1:(5-count)
    if count==2,di=panel;gi=curve; c=colors(gi,:);display=sprintf('%s (n=%d)',groups{gi},totals(gi));
    else,di=curve;gi=panel;c=colors(gi,:);if di==1,c=.52*[1 1 1]+.48*c;end;display=sprintf('D%02d (n=%d)',days(di),totals(gi));end
    a=t(t.Day==days(di) & t.Group==groups{gi},:); x=5:10:695;mu=nan(size(x));band=mu;n=zeros(size(x));
    indices=a.Bin+1; mu(indices)=a.mean; band(indices)=a.(measure);n(indices)=a.nMice;
    dense=n>=ceil(totals(gi)/2)&isfinite(mu)&isfinite(band);starts=find(diff([false dense false])==1); ends=find(diff([false dense false])==-1)-1;
    for k=1:numel(starts),ii=starts(k):ends(k);if numel(ii)>=2,patch(ax,[x(ii) fliplr(x(ii))],[mu(ii)+band(ii) fliplr(mu(ii)-band(ii))],c,'FaceAlpha',.18,'EdgeColor','none','HandleVisibility','off');end;end
    main=mu;main(~dense)=NaN; sparse=mu;sparse(dense | n<2)=NaN;
    plot(ax,x,main,'Color',c,'LineWidth',2,'DisplayName',display);plot(ax,x,sparse,'--','Color',c,'LineWidth',1.5,'HandleVisibility','off');
   end
   xlim(ax,[0 700]);ylim(ax,[-1.5 4.5]);xticks(ax,0:100:700);grid(ax,'on');yline(ax,0,':','Color',[.5 .5 .5],'HandleVisibility','off');
   xlabel(ax,'Position between tape marks (mm; exit 0, entry 700)');ylabel(ax,'Above-bar tail-motion index (a.u.)');
   if count==2,title(ax,sprintf('D%02d',days(panel)));else,title(ax,groups{panel});end
   legend(ax,'Location','northeast');
  end
  title(lay,{sprintf('Above-bar tail motion by position: mean ± %s',labels),'10 mm bins; crossings averaged within mouse; dashed where < half of group contributes'});
  name=['tail-above-by-position-' mode '-' measure];savefig(fig,fullfile(folder,[name '.fig']));exportgraphics(fig,fullfile(folder,[name '.png']),'Resolution',160);print(fig,fullfile(folder,[name '.svg']),'-dsvg');close(fig);fprintf('Saved %s\n',name);
 end
end
