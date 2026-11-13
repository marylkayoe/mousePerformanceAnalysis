function analyzeWithinSessionBB
% Exploratory paired, saved-measurement analysis. No tracking/event processing.
root=fileparts(fileparts(mfilename('fullpath'))); R=fullfile(root,'BEAMCROSS','DRAFTFIGS');
O=fullfile(R,'within-session-diagnostics-20261112'); if ~isfolder(O),mkdir(O);end
M=readtable(fullfile(R,'analysis-data','trial_manifest.csv'),'TextType','string');
opts=detectImportOptions(fullfile(root,'assets','Tara-BB-trial-data.csv'),'TextType','string');
opts.SelectedVariableNames={'fileName','meanSpeedLoco','nSlips','totalSlipMagnitude'};
A=readtable(fullfile(root,'assets','Tara-BB-trial-data.csv'),opts);
T=readtable(fullfile(R,'tail-metrics','whole-motion-reweighted','trial-values.csv'),'TextType','string');
M=M(ismember(M.Day,[0 14]),:); M=sortrows(M,{'MouseID','Day','TrialNumber'});
[ok,ia]=ismember(M.File,A.fileName);assert(all(ok));[ok,it]=ismember(M.File,T.file);assert(all(ok));
V=[A.meanSpeedLoco(ia)*700/1201 M.Frames./M.AnalysisFrameRate 100*M.CorrectStoppedFrames./M.Frames A.nSlips(ia) A.totalSlipMagnitude(ia) T.sumLegacy(it)./T.nLegacy(it)];
assert(all(M.NSlips==V(:,4)));assert(numel(unique(M.File))==height(M));
metrics=["speed","duration","stopped","slip_count","slip_score","tail_score"];
units=["mm/s","s","percentage points","count","a.u. x frames","a.u."];
Q=M(:,{'File','MouseID','CageID','Cohort','Group','Day','TrialNumber'});Q=[Q array2table(V,'VariableNames',cellstr(metrics))];writetable(Q,fullfile(O,'trial_values.csv'));
ids=unique(M.MouseID); P=table; inventory=table;
for i=1:numel(ids)
 for day=[0 14]
  ix=find(M.MouseID==ids(i)&M.Day==day); tr=M.TrialNumber(ix); assert(numel(unique(tr))==numel(tr));
  exact=isequal(tr(:)',[1 2 3]);
  z=table(ids(i),M.CageID(ix(1)),M.Cohort(ix(1)),M.Group(ix(1)),day,numel(ix),join(string(tr)',','),exact,M.File(ix(1)),M.File(ix(end)), 'VariableNames',{'MouseID','CageID','Cohort','Group','Day','NRetained','OriginalTrials','Exact123','FirstFile','LastFile'});
  inventory=[inventory;z];
  if numel(ix)<2,continue;end
  for k=1:6
   p=z(:,{'MouseID','CageID','Cohort','Group','Day','Exact123','FirstFile','LastFile'});p.Metric=metrics(k);p.FirstTrial=tr(1);p.LastTrial=tr(end);p.First=V(ix(1),k);p.Last=V(ix(end),k);p.Delta=p.Last-p.First;P=[P;p];
  end
 end
end
writetable(inventory,fullfile(O,'retained_trial_inventory.csv'));writetable(inventory(~inventory.Exact123,:),fullfile(O,'nonstandard_trials.csv'));writetable(P,fullfile(O,'mouse_first_last_changes.csv'));
D=table;
for i=1:numel(ids)
 for k=1:6
  a=P(P.MouseID==ids(i)&P.Metric==metrics(k)&P.Day==0,:);b=P(P.MouseID==ids(i)&P.Metric==metrics(k)&P.Day==14,:);
  if isempty(a)||isempty(b),continue;end
  z=a(:,{'MouseID','CageID','Cohort','Group','Metric'});z.D0=a.Delta;z.D14=b.Delta;z.Value=b.Delta-a.Delta;z.Exact123Both=a.Exact123&b.Exact123;D=[D;z];
 end
end
writetable(D,fullfile(O,'mouse_day_difference_in_changes.csv'));
% Independently compare each endpoint to the previously exported D14 table.
old=readtable(fullfile(R,'last-crossing-D14','last_crossing_values.csv'),'TextType','string');
err=[];
for k=1:6
 key=metrics(k);if key=="stopped",key="time_stopped";end
 a=old(old.metric==key,:);b=P(P.Day==14&P.Metric==metrics(k),:);
 [ok,ix]=ismember(a.file,b.LastFile);assert(all(ok));err=[err;abs(a.value-b.Last(ix))];
end
assert(max(err)<1e-9);assert(all(isfinite(V),'all'));assert(height(D)==42*6);
assert(all(abs(D.Value-(D.D14-D.D0))<1e-12));
% Cohort-specific descriptive means expose the weighting differences in earlier work.
cs=table;
for day=[0 14],for k=1:6,for co=["TMCS2","TMCS3"]
 a=P(P.Day==day&P.Metric==metrics(k)&P.Cohort==co,:);cids=unique(a.CageID);cv=arrayfun(@(j)mean(a.Delta(a.CageID==cids(j))),1:numel(cids));
 z=table(day,metrics(k),co,height(a),numel(cids),mean(a.Delta),mean(cv),'VariableNames',{'Day','Metric','Cohort','NMice','NCages','MouseMean','CageMean'});cs=[cs;z];
end,end,end
writetable(cs,fullfile(O,'cohort_descriptive_changes.csv'));
fid=fopen(fullfile(O,'VALIDATION.txt'),'w');fprintf(fid,'251 unique source filenames; 42 paired mice; 15 cages. All six scalar outcomes finite.\n252 D14 last-crossing values independently matched previous exported table: max error %.12g.\nSlip counts match validated manifest. Day difference identities verified.\n',max(err));fclose(fid);
S=table; C=table; desc=table;
for subset=["all","exact123"]
 for period=["D0","D14","D14minusD0"]
  for k=1:6
   if period=="D14minusD0",x=D(D.Metric==metrics(k),:); if subset=="exact123",x=x(x.Exact123Both,:);end
   else,day=str2double(extractAfter(period,1));x=P(P.Metric==metrics(k)&P.Day==day,:);if subset=="exact123",x=x(x.Exact123,:);end;x.Value=x.Delta;end
   x=x(isfinite(x.Value),:);
   for g=["sedentary","walk","run"]
    xx=x(x.Group==g,:);zz=table(subset,period,metrics(k),g,height(xx),numel(unique(xx.CageID)),mean(xx.Value),std(xx.Value),'VariableNames',{'Subset','Period','Metric','Group','NMice','NCages','MouseMean','MouseSD'});desc=[desc;zz];
   end
   ca=unique(x.CageID); y=zeros(numel(ca),1);co=strings(numel(ca),1);gr=co;
   for j=1:numel(ca),xx=x(x.CageID==ca(j),:);y(j)=mean(xx.Value);co(j)=xx.Cohort(1);gr(j)=xx.Group(1);end
   cc=table(repmat(subset,numel(ca),1),repmat(period,numel(ca),1),repmat(metrics(k),numel(ca),1),ca,co,gr,y,'VariableNames',{'Subset','Period','Metric','CageID','Cohort','Group','Value'});C=[C;cc];
   X=[ones(size(y)) double(gr=="walk") double(gr=="run") double(co=="TMCS3")];
   contrasts=[1 0 0 .5;1 1 0 .5;1 0 1 .5;0 -1 1 0;0 0 1 0];names=["SED","WALK","RUN","RUN-WALK","RUN-SED"];
   for j=1:5
    [est,se,lo,hi,p,df]=fitcontrast(X,y,contrasts(j,:));
    ep=NaN;ed=NaN;if j>=4,[ed,ep]=permcontrast(y,gr,co,names(j));end
    z=table(subset,period,metrics(k),names(j),height(x),numel(ca),est,se,lo,hi,p,df,ed,ep,'VariableNames',{'Subset','Period','Metric','Contrast','NMice','NCages','Estimate','SE_HC3','CI95Low','CI95High','P','DF','ExactEqualCohortEstimate','ExactPermutationP'});S=[S;z];
   end
   % Pooled baseline/session question: cohort-adjusted all-cage mean, no group assumption.
   [est,se,lo,hi,p,df]=fitcontrast([ones(size(y)) double(co=="TMCS3")],y,[1 .5]);
   z=table(subset,period,metrics(k),"POOLED",height(x),numel(ca),est,se,lo,hi,p,df,NaN,NaN,'VariableNames',S.Properties.VariableNames);S=[S;z];
  end
 end
end
S.PHolm6=nan(height(S),1);S.ExactPHolm6=nan(height(S),1);
for sub=unique(S.Subset)',for per=unique(S.Period)',for con=unique(S.Contrast)'
 ix=find(S.Subset==sub&S.Period==per&S.Contrast==con);S.PHolm6(ix)=holm(S.P(ix));S.ExactPHolm6(ix)=holm(S.ExactPermutationP(ix));
end,end,end
writetable(S,fullfile(O,'inference.csv'));writetable(C,fullfile(O,'cage_changes.csv'));writetable(desc,fullfile(O,'descriptive_changes.csv'));
% Display chosen for distinct behavioural domains, not p values.
sel=[1 4 6];labels=["Locomoting speed (mm/s)","Detected slips (count)","Tail-motion score (a.u.)"];groups=["sedentary","walk","run"];colors=[.14 .14 .14;0 .55 .25;.03 .39 .81];
f=figure('Visible','off','Color','w','Position',[50 50 1420 850]);tl=tiledlayout(3,6,'TileSpacing','compact','Padding','compact');
for kk=1:3
 k=sel(kk); lim=[min(V(:,k)) max(V(:,k))];pad=diff(lim)*.07;lim=lim+[-pad pad];
 for di=1:2,day=[0 14];day=day(di);
  for gi=1:3
   ax=nexttile;hold on;ix=find(M.Day==day&M.Group==groups(gi)); mids=unique(M.MouseID(ix));
   for mi=1:numel(mids),jj=ix(M.MouseID(ix)==mids(mi));plot(M.TrialNumber(jj),V(jj,k),'-o','Color',.73+.27*colors(gi,:),'MarkerSize',2,'LineWidth',.5);end
   trs=unique(M.TrialNumber(ix)); vv=arrayfun(@(t)mean(V(ix(M.TrialNumber(ix)==t),k),'omitnan'),trs);plot(trs,vv,'o','Color',colors(gi,:),'LineWidth',2,'MarkerFaceColor',colors(gi,:),'MarkerSize',5);
   for ti=1:numel(trs),text(trs(ti),lim(2)-.03*diff(lim),string(sum(M.TrialNumber(ix)==trs(ti))),'HorizontalAlignment','center','FontSize',8,'Color',colors(gi,:));end
   ylim(lim);xlim([.7 max(M.TrialNumber)+.3]);xticks(1:max(M.TrialNumber));box off;
   if kk==1,title(sprintf('D%d  %s (n=%d)',day,upper(groups(gi)),numel(mids)));end
   if gi==1,ylabel(labels(kk));end;if kk==3,xlabel('Original trial number');end
  end
 end
end
title(tl,'A  Within-session progression | thin lines: mice; large dots: available-mouse means','FontSize',15);subtitle(tl,'Top numbers = mice at each original trial. Mean dots are not connected because membership changes.');
exportgraphics(f,fullfile(O,'A_progression.png'),'Resolution',170);print(f,fullfile(O,'A_progression.svg'),'-dsvg');close(f);
f=figure('Visible','off','Color','w','Position',[50 50 1450 820]);tl=tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
cages=unique(D.CageID);xx=1:numel(cages);markers={'o','s','^','d','v','>','<','p','h','x','+','*','o','s','^'};
for kk=1:3
 z=D(D.Metric==metrics(sel(kk)),:);
 for panel=1:2
  ax=nexttile;hold on;yline(0,':','Color',[.5 .5 .5]);
  for j=1:numel(cages)
   a=z(z.CageID==cages(j),:);gi=find(groups==a.Group(1));offset=linspace(-.2,.2,height(a));
   for mi=1:height(a)
    xpos=j+offset(mi);
    if panel==1,plot([xpos-.06 xpos+.06],[a.D0(mi) a.D14(mi)],'-','Color',.6+.4*colors(gi,:));scatter(xpos-.06,a.D0(mi),20,colors(gi,:),'o');scatter(xpos+.06,a.D14(mi),20,colors(gi,:),'filled');
    else,scatter(xpos,a.Value(mi),22,colors(gi,:),'filled');end
   end
   if panel==2,plot(j,mean(a.Value),'kd','MarkerFaceColor',colors(gi,:),'MarkerSize',7);end
  end
  xlim([.4 numel(cages)+.6]);xticks(xx);xticklabels(erase(cages,'TMCS'));set(ax,'TickLabelInterpreter','none');xtickangle(55);box off;
  if panel==1,ylabel(labels(kk)+" change");else,ylabel("D14 change - D0 change");end
  if kk==1,if panel==1,title('Last - first: open D0; filled D14; paired by mouse');else,title('Difference in within-session changes; diamonds = cage means');end,end
 end
end
title(tl,'B  Mouse-paired changes, grouped by cage | SED black, WALK green, RUN blue','FontSize',15);subtitle(tl,'Cage labels: cohort / cage. Positive differences indicate a more positive last-minus-first change at D14.');
exportgraphics(f,fullfile(O,'B_changes.png'),'Resolution',170);print(f,fullfile(O,'B_changes.svg'),'-dsvg');close(f);
fid=fopen(fullfile(O,'RUN_SUMMARY.txt'),'w');fprintf(fid,'Trials %d; mice %d; cages %d; nonstandard mouse-days %d\n',height(M),numel(ids),numel(cages),sum(~inventory.Exact123));fclose(fid);
disp(inventory(~inventory.Exact123,{'MouseID','Day','OriginalTrials'}));disp(S(S.Subset=="all"&S.Contrast=="POOLED",{'Period','Metric','Estimate','CI95Low','CI95High','P','PHolm6'}));fprintf('OUTPUT %s\n',O);
end
function [e,se,lo,hi,p,df]=fitcontrast(X,y,c)
assert(rank(X)==size(X,2));B=(X'*X)\eye(size(X,2));b=X\y;r=y-X*b;h=sum((X*B).*X,2);assert(all(h<1-1e-9));cov=B*(X'*((r./(1-h)).^2.*X))*B;df=numel(y)-size(X,2);e=c*b;se=sqrt(c*cov*c');q=tinv(.975,df);lo=e-q*se;hi=e+q*se;p=2*tcdf(-abs(e/se),df);
end
function out=holm(p)
out=nan(size(p));ix=find(isfinite(p));[v,ord]=sort(p(ix));adj=min(1,cummax(v.*(numel(v):-1:1)'));out(ix(ord))=adj;
end
function [e,p]=permcontrast(y,g,co,name)
if name=="RUN-WALK",other="walk";else,other="sedentary";end
coh=unique(co);v=cell(2,1);obs=zeros(2,1);
for k=1:2
 ix=co==coh(k)&ismember(g,["run",other]);yy=y(ix);gg=g(ix);n=sum(gg=="run");obs(k)=mean(yy(gg=="run"))-mean(yy(gg==other));comb=nchoosek(1:numel(yy),n);v{k}=zeros(size(comb,1),1);
 for j=1:size(comb,1),sel=false(size(yy));sel(comb(j,:))=true;v{k}(j)=mean(yy(sel))-mean(yy(~sel));end
end
e=mean(obs);null=(v{1}+v{2}')/2;p=mean(abs(null(:))>=abs(e)-1e-10);
end
