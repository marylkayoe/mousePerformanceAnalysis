function plotFirstLastSpeedCompact
% Presentation only: reproduce saved absolute changes, no inferential tests.
root=fileparts(fileparts(mfilename('fullpath')));O=fullfile(root,'BEAMCROSS','DRAFTFIGS','within-session-diagnostics-20261112');stem=string(fullfile(O,'first_to_last_locomoting_speed_D0_D14'));
% User-authorized presentation update of these SVG/PNG outputs.
P=readtable(fullfile(O,'mouse_first_last_changes.csv'),'TextType','string','ReadVariableNames',true,'Delimiter',',');P=P(P.Metric=="speed",:);
T=readtable(fullfile(O,'trial_values.csv'),'TextType','string','ReadVariableNames',true,'Delimiter',',');D=readtable(fullfile(O,'descriptive_changes.csv'),'TextType','string');
assert(height(P)==84&&all(isfinite(P.Delta)));assert(all(abs(P.Last-P.First-P.Delta)<1e-10));
for i=1:height(P)
 t=sortrows(T(T.MouseID==P.MouseID(i)&T.Day==P.Day(i),:),'TrialNumber');
 assert(P.FirstTrial(i)==min(t.TrialNumber)&&P.LastTrial(i)==max(t.TrialNumber));
 assert(P.FirstFile(i)==t.File(1)&&P.LastFile(i)==t.File(end));
 assert(abs(t.speed(end)-t.speed(1)-P.Delta(i))<1e-10);
end
groups=["sedentary","walk","run"];labs=["SED","WALK","RUN"];cols=["#232323","#008d3f","#0864cf"];expected=[-6.43 -7.06 -1.81;-28.87 -26.17 -1.21];N=[12 12 18];NC=[4 4 7];summary=table;
for di=1:2
 day=[0 14];day=day(di);p=P(P.Day==day,:);assert(height(p)==42&&numel(unique(p.CageID))==15);
 for gi=1:3
  q=p(p.Group==groups(gi),:);mu=mean(q.Delta);assert(height(q)==N(gi)&&numel(unique(q.CageID))==NC(gi));assert(abs(mu-expected(di,gi))<.005);
  ref=D(D.Subset=="all"&D.Period=="D"+day&D.Metric=="speed"&D.Group==groups(gi),:);assert(height(ref)==1&&abs(mu-ref.MouseMean)<1e-10);
  summary=[summary;table(day,groups(gi),height(q),numel(unique(q.CageID)),mu,'VariableNames',{'Day','Group','NMice','NCages','MeanChange_mm_s'})];
 end
end
s=P(P.MouseID=="TMCS2_S10"&P.Day==0,:);assert(height(s)==1&&s.FirstTrial==2&&s.LastTrial==3);
W=188;H=108;lo=-125;hi=100;top=28;bottom=94;Y=@(v)bottom-(v-lo)/(hi-lo)*(bottom-top);assert(all(P.Delta>lo&P.Delta<hi));
f=figure('Visible','off','Color','w','Units','points','Position',[30 30 W H],'Renderer','painters');ax=axes(f,'Position',[0 0 1 1],'XLim',[0 W],'YLim',[0 H],'YDir','reverse','Visible','off');hold(ax,'on');
fid=fopen(stem+'.svg','w');fprintf(fid,'<svg xmlns="http://www.w3.org/2000/svg" width="188pt" height="108pt" viewBox="0 0 188 108">\n<title>First-to-last change in locomoting speed</title>\n<desc>Absolute last minus first retained crossing speed, not necessarily original trials 1 and 3. 42 mice and 15 cages each day. Dots mice; diamonds cage means; bars equal-mouse group means. No statistical annotations.</desc>\n<rect width="188" height="108" fill="white"/>\n');
txt(W/2,8,'First-to-last change in locomoting speed',6.5,'middle',false);
for di=1:2
 day=[0 14];day=day(di);left=18+94*(di-1);right=left+70;
 txt((left+right)/2,19,"D"+day,6,'middle',false);
 seg(left,top,left,bottom,"#262626",.4);seg(left,Y(0),right,Y(0),"#bcbcbc",.35);
 for v=[-100 -50 0 50 100],seg(left,Y(v),left+1,Y(v),"#262626",.4);txt(left-2,Y(v)+1.6,string(v),5.2,'end',false);end
 for gi=1:3
  q=sortrows(P(P.Day==day&P.Group==groups(gi),:),'MouseID');cx=left+14+23*(gi-1);c=cols(gi);rgb=sscanf(char(extractAfter(c,1)),'%2x%2x%2x')'/255;
  for j=1:height(q)
   x=cx-4.7+9.4*(j-1)/(height(q)-1);y=Y(q.Delta(j));
   fprintf(fid,'<ellipse cx="%.5f" cy="%.5f" rx="1.14" ry="1.1" fill="%s" fill-opacity="0.4"/>\n',x,y,c);
   rectangle(ax,'Position',[x-1.14 y-1.1 2.28 2.2],'Curvature',[1 1],'FaceColor',.4*rgb+.6,'EdgeColor','none');
  end
  ca=unique(q.CageID);
  for j=1:numel(ca)
   x=cx-8;y=Y(mean(q.Delta(q.CageID==ca(j))));xx=[x-1.42 x x+1.42 x];yy=[y y-1.79 y y+1.79];
   fprintf(fid,'<polygon points="%.5f,%.5f %.5f,%.5f %.5f,%.5f %.5f,%.5f" fill="%s" stroke="#231f20" stroke-width="0.13"/>\n',[xx;yy],c);patch(ax,xx,yy,rgb,'EdgeColor',[35 31 32]/255,'LineWidth',.13);
  end
  y=Y(mean(q.Delta));seg(cx-5.34,y,cx+5.34,y,c,.92);txt(cx,bottom+8,labs(gi),5.2,'middle',false);
 end
end
txt(18,24,'mm/s',5.2,'middle',false);
fprintf(fid,'</svg>\n');fclose(fid);
set(f,'PaperUnits','points','PaperSize',[W H],'PaperPosition',[0 0 W H]);print(f,stem+'.png','-dpng','-r600');close(f);
% Ensure SVG text stays editable (not converted to paths or rasterized).
svg=fileread(stem+'.svg');assert(numel(strfind(svg,'<text '))==20);assert(~contains(svg,'<image'));
if ~isfile(stem+'_validation.csv'),writetable(summary,stem+'_validation.csv');end
if ~isfile(stem+'_source.csv'),writetable(P,stem+'_source.csv');end
fid=fopen(stem+'.md','w');fprintf(fid,'# First-to-last locomoting speed, D0 and D14\n\nCaption: First-to-last change in locomoting speed at D0 and D14. First and last denote the first and last retained crossings for each mouse/day, not necessarily original trials 1 and 3. Dots are mice, diamonds are cage means, and short bars are equal-mouse group means.\n\nPresentation only, no new inferential analysis. Absolute last minus first retained crossing speed in mm/s. All 42 mice/15 cages per day, including TMCS2_S10 original D0 trials 2 and 3. First/last original numbers and full filenames preserved in source CSV. Checked every change against saved trial_values.csv and mouse_first_last_changes.csv; all six group means match descriptive_changes.csv within 1e-10 and supplied rounded targets within 0.005.\n\nSVG: 188 x 108 pt (66.32 x 38.10 mm), Arial 5.2 pt tick/group/unit labels, 6 pt day headings and 6.5 pt shared title. Native compact D0 comparison styling: mouse ellipses 1.14 x 1.10 pt at 40%% opacity; cage diamonds 1.42 x 1.79 pt; group bars 10.68 x 0.92 pt; colours #232323/#008d3f/#0864cf. Both days y limits -125 to +100 mm/s. No connecting lines, p-values, legend or significance brackets. All 20 text elements are editable SVG text; no embedded raster. PNG is 600 dpi.\n\nReproduce tests/plotFirstLastSpeedCompact.m with MATLAB R2024b; updates this SVG/PNG only as authorized. Other figures and BBfigure.ai are untouched. Files requested in repository figure-workflow directory; no bulk scratch or canonical measurement changes.\n');fclose(fid);disp(summary);
 function seg(x,y,xx,yy,c,w)
  fprintf(fid,'<path d="M%.5f %.5f L%.5f %.5f" stroke="%s" stroke-width="%.3f" fill="none"/>\n',x,y,xx,yy,c,w);rgb=sscanf(char(extractAfter(c,1)),'%2x%2x%2x')'/255;plot(ax,[x xx],[y yy],'Color',rgb,'LineWidth',w);
 end
 function txt(x,y,s,size,anchor,rot)
  if rot,transform=sprintf(' transform="rotate(-90 %.5f %.5f)"',x,y);rotation=90;else,transform='';rotation=0;end
  fprintf(fid,'<text x="%.5f" y="%.5f" font-family="ArialMT, Arial" font-size="%.2f" text-anchor="%s" fill="#232323"%s>%s</text>\n',x,y,size,anchor,transform,s);
  aligns=struct('middle','center','end','right','start','left');text(ax,x,y,s,'FontName','Arial','FontUnits','points','FontSize',size,'HorizontalAlignment',aligns.(anchor),'VerticalAlignment','baseline','Rotation',rotation,'Color',[35 35 35]/255,'Interpreter','none');
 end
end
