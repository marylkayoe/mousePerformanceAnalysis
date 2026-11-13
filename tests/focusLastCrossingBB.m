function focusLastCrossingBB
% User-selected four domains after exploratory inspection; no new tests.
root=fileparts(fileparts(mfilename('fullpath')));O=fullfile(root,'BEAMCROSS','DRAFTFIGS','last-crossing-paired-20261112');
keys=["speed","time_stopped","slip_count","tail_score"];labels=["Locomoting speed","Time stopped","Detected slip count","Corrected whole-tail motion score"];units=["mm/s","%","count","a.u."];
S=readtable(fullfile(O,'model_comparisons.csv'),'TextType','string');S=S(ismember(S.Metric,keys),:);S.PHolm4_HC3=nan(height(S),1);S.PHolm4_OLS=S.PHolm4_HC3;
for sub=unique(S.Subset)',for mod=unique(S.Model)',for con=unique(S.Contrast)'
 ix=find(S.Subset==sub&S.Model==mod&S.Contrast==con);if isempty(ix),continue;end;assert(numel(ix)==4);S.PHolm4_HC3(ix)=holm4(S.P_HC3(ix));S.PHolm4_OLS(ix)=holm4(S.P_OLS(ix));
end,end,end
writetable(S,fullfile(O,'FOUR_OUTCOMES_model_comparisons.csv'));
PC=readtable(fullfile(O,'paired_change_permutation.csv'),'TextType','string');PC=PC(ismember(PC.Metric,keys),:);PC.PHolm4=nan(height(PC),1);
for sub=unique(PC.Subset)',for con=unique(PC.Contrast)',ix=find(PC.Subset==sub&PC.Contrast==con);PC.PHolm4(ix)=holm4(PC.P(ix));end,end
writetable(PC,fullfile(O,'FOUR_OUTCOMES_change_permutation.csv'));
E=readtable(fullfile(O,'existing_D14_permutation_with_Holm9.csv'),'TextType','string');E=E(ismember(E.metric,keys),:);E.PHolm4=nan(height(E),1);
for con=unique(E.pair)',ix=find(E.pair==con);E.PHolm4(ix)=holm4(E.p_raw(ix));end
writetable(E,fullfile(O,'FOUR_OUTCOMES_existing_D14_permutation.csv'));
L=readtable(fullfile(O,'leave_one_cage_out.csv'),'TextType','string');L=L(ismember(L.Metric,keys),:);L.PHolm4_HC3=nan(height(L),1);
for mod=unique(L.Model)',for con=unique(L.Contrast)',for ca=unique(L.OmittedCage)'
 ix=find(L.Model==mod&L.Contrast==con&L.OmittedCage==ca);L.PHolm4_HC3(ix)=holm4(L.P_HC3(ix));
end,end,end
writetable(L,fullfile(O,'FOUR_OUTCOMES_leave_one_cage_out.csv'));
P=readtable(fullfile(O,'mouse_values.csv'),'TextType','string');I=readtable(fullfile(O,'selected_crossings.csv'),'TextType','string','ReadVariableNames',true,'Delimiter',',');assert(numel(unique([I.D0File;I.D14File]))==84);
groups=["sedentary","walk","run"];colors=[.14 .14 .14;0 .55 .25;.03 .39 .81];cages=strings(0,1);cg=[];
for gi=1:3,ca=unique(I.CageID(I.Group==groups(gi)));cages=[cages;ca];cg=[cg;repmat(gi,numel(ca),1)];end
for panel=["A","B"]
 f=figure('Visible','off','Color','w','Position',[40 40 1450 820]);tl=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
 for k=1:4
  q=P(P.Metric==keys(k),:);ax=nexttile;hold on;if panel=="B",yline(0,':','Color',[.5 .5 .5]);end
  for j=1:numel(cages)
   a=q(q.CageID==cages(j),:);col=colors(cg(j),:);off=linspace(-.22,.22,height(a));
   if panel=="A"
    for mi=1:height(a),x=j+off(mi);plot([x-.07 x+.07],[a.D0(mi) a.D14(mi)],'-','Color',.6+.4*col,'LineWidth',.7);scatter(x-.07,a.D0(mi),22,col,'o');scatter(x+.07,a.D14(mi),22,col,'filled');end
   else
    scatter(j+off,a.Change,25,col,'filled','MarkerFaceAlpha',.5);plot(j,mean(a.Change),'kd','MarkerFaceColor',col,'MarkerSize',7);
   end
  end
  for gi=1:3
   js=find(cg==gi);a=q(q.Group==groups(gi),:);span=[js(1)-.35 js(end)+.35];
   if panel=="A",plot(span,repmat(mean(a.D0),1,2),'--','Color',colors(gi,:),'LineWidth',1.3);plot(span,repmat(mean(a.D14),1,2),'-','Color',colors(gi,:),'LineWidth',1.8);
   else,plot(span,repmat(mean(a.Change),1,2),'-','Color',colors(gi,:),'LineWidth',2);end
  end
  xlim([.4 numel(cages)+.6]);xticks(1:numel(cages));xticklabels(erase(cages,'TMCS'));set(ax,'TickLabelInterpreter','none');xtickangle(50);title(labels(k));
  if panel=="A",ylabel(labels(k)+" ("+units(k)+")");else,ylabel(labels(k)+" change ("+replace(units(k),'%','percentage points')+")");end;box off;
  yy=ylim;ylim(yy+[-1 1]*.025*diff(yy));title(ax,labels(k));
 end
 if panel=="A"
  title(tl,'A  Last retained crossing: paired D0 and D14','FontSize',17);subtitle(tl,'Open D0 / filled D14; lines pair mice. Group means: dashed D0 / solid D14. SED black; WALK green; RUN blue. Cage labels = cohort_cage.','Interpreter','none');
 else
  title(tl,'B  D14 - D0 last-crossing change','FontSize',17);subtitle(tl,'Dots: paired mice. Diamonds: cage means. Bars: equal-mouse group means. SED black; WALK green; RUN blue. Cage labels = cohort_cage.','Interpreter','none');
 end
 exportgraphics(f,fullfile(O,panel+'_four_selected_outcomes.png'),'Resolution',170);print(f,fullfile(O,panel+'_four_selected_outcomes.svg'),'-dsvg');close(f);
end
fid=fopen(fullfile(O,'FOUR_OUTCOMES_TABLES.md'),'w');fprintf(fid,'# Four selected outcomes\n\nSelected after exploratory inspection of nine outcomes. Estimates and pointwise 95%% HC3 CIs with raw p-values; q4 is a four-outcome Holm sensitivity within each contrast/model/subset, not correction for the full exploratory selection history. All nine original results remain in NUMERICAL_TABLES.md and model_comparisons.csv.\n');
for sub=unique(S.Subset)',for mod=unique(S.Model)'
 if ~any(S.Subset==sub&S.Model==mod),continue;end
 fprintf(fid,'\n## %s: %s\n\n|Outcome|RUN–WALK estimate [CI]; raw p / q4|RUN–SED estimate [CI]; raw p / q4|\n|---|---:|---:|\n',sub,mod);
 for k=1:4,fprintf(fid,'|%s|',labels(k));for con=["RUN-WALK","RUN-SED"],s=S(S.Subset==sub&S.Model==mod&S.Metric==keys(k)&S.Contrast==con,:);fprintf(fid,'%.3g [%.3g, %.3g]; %.4g / %.4g|',s.Estimate,s.CI95Low_HC3,s.CI95High_HC3,s.P_HC3,s.PHolm4_HC3);end;fprintf(fid,'\n');end
end,end
fclose(fid);disp(S(:,{'Subset','Metric','Model','Contrast','P_HC3','PHolm4_HC3'}));
end
function a=holm4(p)
assert(numel(p)==4&&all(isfinite(p)));[v,ord]=sort(p);a=zeros(size(p));a(ord)=min(1,cummax(v.*(4:-1:1)'));
end
