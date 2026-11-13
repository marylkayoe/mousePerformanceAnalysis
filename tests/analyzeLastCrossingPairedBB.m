function analyzeLastCrossingPairedBB
% Saved scalar measurements only. Paired mice -> cage means -> cohort models.
root=fileparts(fileparts(mfilename('fullpath')));R=fullfile(root,'BEAMCROSS','DRAFTFIGS');O=fullfile(R,'last-crossing-paired-20261112');if ~isfolder(O),mkdir(O);end
M=readtable(fullfile(R,'analysis-data','trial_manifest.csv'),'TextType','string');M=sortrows(M(ismember(M.Day,[0 14]),:),{'MouseID','Day','TrialNumber'});
opts=detectImportOptions(fullfile(root,'assets','Tara-BB-trial-data.csv'),'TextType','string');opts.SelectedVariableNames={'fileName','meanSpeedLoco','meanPosturalHeight','nSlips','totalSlipMagnitude'};A=readtable(fullfile(root,'assets','Tara-BB-trial-data.csv'),opts);
H=readtable(fullfile(R,'tail-metrics','height-exploratory','trial-motion-height.csv'),'TextType','string');T=readtable(fullfile(R,'tail-metrics','whole-motion-reweighted','trial-values.csv'),'TextType','string');
[ok,ia]=ismember(M.File,A.fileName);assert(all(ok));[ok,ih]=ismember(M.File,H.file);assert(all(ok));[ok,it]=ismember(M.File,T.file);assert(all(ok));
ms=A.totalSlipMagnitude(ia)./A.nSlips(ia);ms(A.nSlips(ia)==0)=NaN;
V=[A.meanSpeedLoco(ia)*700/1201 M.Frames./M.AnalysisFrameRate 100*M.CorrectStoppedFrames./M.Frames A.meanPosturalHeight(ia)*700/1201 A.nSlips(ia) A.totalSlipMagnitude(ia) ms H.medianHeight(ih) T.sumLegacy(it)./T.nLegacy(it)];
keys=["speed","duration","time_stopped","posture","slip_count","slip_score","mean_slip","motion_height","tail_score"];
labels=["Locomoting speed","Crossing duration","Time stopped","Posture height","Slip count","Total slip score","Mean slip-event score","Motion height","Tail-motion score"];
units=["mm/s","s","percentage points","mm","count","a.u. x frames","a.u. x frames","mm","a.u."];
assert(all(V(:,5)==M.NSlips));ids=unique(M.MouseID);P=table;I=table;
for i=1:numel(ids)
 ix0=find(M.MouseID==ids(i)&M.Day==0);ix1=find(M.MouseID==ids(i)&M.Day==14);assert(~isempty(ix0)&&~isempty(ix1));a=ix0(end);b=ix1(end);
 assert(M.CageID(a)==M.CageID(b)&&M.Group(a)==M.Group(b)&&M.Cohort(a)==M.Cohort(b));
 exact=isequal(M.TrialNumber(ix0)',[1 2 3])&&isequal(M.TrialNumber(ix1)',[1 2 3]);
 z=table(ids(i),M.CageID(a),M.Cohort(a),M.Group(a),M.File(a),M.File(b),M.TrialNumber(a),M.TrialNumber(b),join(string(M.TrialNumber(ix0))',','),join(string(M.TrialNumber(ix1))',','),exact,'VariableNames',{'MouseID','CageID','Cohort','Group','D0File','D14File','D0Trial','D14Trial','D0RetainedTrials','D14RetainedTrials','Exact123Both'});I=[I;z];
 for k=1:9
  p=z;p.Metric=keys(k);p.D0=V(a,k);p.D14=V(b,k);p.Change=p.D14-p.D0;p.CompletePair=isfinite(p.D0)&isfinite(p.D14);P=[P;p];
 end
end
assert(numel(unique([I.D0File;I.D14File]))==84);
writetable(I,fullfile(O,'selected_crossings.csv'));writetable(P,fullfile(O,'mouse_values.csv'));writetable(P(~P.CompletePair,:),fullfile(O,'missing_pairs.csv'));
% Verify all nine D14 outcomes against prior export; never regenerate that figure.
old=readtable(fullfile(R,'last-crossing-D14','last_crossing_values.csv'),'TextType','string');maxerr=0;
for k=1:9
 a=old(old.metric==keys(k),:);b=P(P.Metric==keys(k),:);[ok,ix]=ismember(a.file,b.D14File);assert(all(ok));assert(isequal(isfinite(a.value),isfinite(b.D14(ix))));err=abs(a.value-b.D14(ix));maxerr=max(maxerr,max(err,[],'omitnan'));
end
assert(maxerr<1e-9);assert(height(I)==42&&numel(unique(I.CageID))==15);assert(sum(I.Exact123Both)==21);
S=table;C=table;G=table;L=table;D=table;CO=table;PC=table;
for subset=["all","exact123both"]
 for k=1:9
  p=P(P.Metric==keys(k),:);if subset=="exact123both",p=p(p.Exact123Both,:);end
  % Keep separate available-case endpoint summaries and matched-pair summaries.
  for pop=["available","paired"]
   q=p;if pop=="paired",q=q(q.CompletePair,:);end
   for g=["sedentary","walk","run"]
    qq=q(q.Group==g,:);
    for field=["D0","D14","Change"]
     v=qq.(field);ok=isfinite(v);zz=table(subset,keys(k),g,pop,field,sum(ok),numel(unique(qq.CageID(ok))),mean(v(ok)),std(v(ok)),'VariableNames',{'Subset','Metric','Group','Population','Period','NMice','NCages','Mean','SD'});G=[G;zz];
    end
   end
  end
  p=p(p.CompletePair,:);ca=unique(p.CageID);n=numel(ca);a=zeros(n,1);b=a;nm=a;gr=strings(n,1);co=gr;
  for j=1:n,q=p(p.CageID==ca(j),:);a(j)=mean(q.D0);b(j)=mean(q.D14);gr(j)=q.Group(1);co(j)=q.Cohort(1);nm(j)=height(q);end
  c=table(repmat(subset,n,1),repmat(keys(k),n,1),ca,co,gr,nm,a,b,b-a,'VariableNames',{'Subset','Metric','CageID','Cohort','Group','NMice','D0','D14','Change'});C=[C;c];
  X=[ones(n,1) double(gr=="walk") double(gr=="run") double(co=="TMCS3")];
  if subset=="all",models=["D0","D14","Change","ANCOVA"];else,models="Change";end
  for model=models
   if model=="ANCOVA",Z=[X (a-mean(a))/std(a)];y=b;else,Z=X;y=c.(model);end
   f=fitmodel(Z,y);
   for ci=1:2
    cons=["RUN-WALK","RUN-SED"];v=zeros(1,size(Z,2));v(3)=1;if ci==1,v(2)=-1;end
    [e,lo,hi,pv,loc,hic,pvc]=contrast(f,v);
    z=table(subset,keys(k),model,cons(ci),height(p),n,f.df,e,lo,hi,pv,loc,hic,pvc,'VariableNames',{'Subset','Metric','Model','Contrast','NMice','NCages','DF','Estimate','CI95Low_HC3','CI95High_HC3','P_HC3','CI95Low_OLS','CI95High_OLS','P_OLS'});S=[S;z];
    if model=="Change"
     [ep,pp]=permcontrast(y,gr,co,cons(ci));zz=table(subset,keys(k),cons(ci),ep,pp,'VariableNames',{'Subset','Metric','Contrast','EqualCohortEstimate','P'});PC=[PC;zz];
    end
    if subset=="all"&&ismember(model,["Change","ANCOVA"])
     for j=1:n
      keep=true(n,1);keep(j)=false;fl=fitmodel(Z(keep,:),y(keep));[el,ll,hl,pl]=contrast(fl,v);
      zz=table(keys(k),model,cons(ci),ca(j),el,ll,hl,pl,'VariableNames',{'Metric','Model','Contrast','OmittedCage','Estimate','CI95Low_HC3','CI95High_HC3','P_HC3'});L=[L;zz];
     end
    end
   end
   if subset=="all"&&ismember(model,["Change","ANCOVA"])
    for j=1:n
     zz=table(keys(k),model,ca(j),co(j),gr(j),f.h(j),f.cook(j),f.r(j),'VariableNames',{'Metric','Model','CageID','Cohort','Group','Leverage','CooksDistance','Residual'});D=[D;zz];
    end
   end
  end
  if subset=="all"
   % Descriptive cohort-specific cage contrasts; sparse cells cannot support robust per-cohort ANCOVA.
   for cohort=["TMCS2","TMCS3"],for ci=1:2
    cons=["RUN-WALK","RUN-SED"];if ci==1,other="walk";else,other="sedentary";end
    ir=co==cohort&gr=="run";io=co==cohort&gr==other;
    zz=table(keys(k),cohort,cons(ci),sum(ir),sum(io),mean(a(ir))-mean(a(io)),mean(b(ir))-mean(b(io)),mean(b(ir)-a(ir))-mean(b(io)-a(io)),'VariableNames',{'Metric','Cohort','Contrast','RunCages','ComparatorCages','D0','D14','Change'});CO=[CO;zz];
   end,end
  end
 end
end
S.PHolm9_HC3=nan(height(S),1);S.PHolm9_OLS=nan(height(S),1);
for sub=unique(S.Subset)',for mod=unique(S.Model)',for con=unique(S.Contrast)'
 ix=find(S.Subset==sub&S.Model==mod&S.Contrast==con);if isempty(ix),continue;end;assert(numel(ix)==9);S.PHolm9_HC3(ix)=holm(S.P_HC3(ix));S.PHolm9_OLS(ix)=holm(S.P_OLS(ix));
end,end,end
PC.PHolm9=nan(height(PC),1);for sub=unique(PC.Subset)',for con=unique(PC.Contrast)',ix=find(PC.Subset==sub&PC.Contrast==con);PC.PHolm9(ix)=holm(PC.P(ix));end,end
% Original endpoint inference is retained, with nine-outcome correction added only here.
E=readtable(fullfile(R,'last-crossing-D14','statistics.csv'),'TextType','string');E=E(ismember(E.pair,["run minus walk","run minus sedentary"]),:);E.PHolm9=nan(height(E),1);
for con=unique(E.pair)',ix=find(E.pair==con);E.PHolm9(ix)=holm(E.p_raw(ix));end
writetable(S,fullfile(O,'model_comparisons.csv'));writetable(PC,fullfile(O,'paired_change_permutation.csv'));writetable(E,fullfile(O,'existing_D14_permutation_with_Holm9.csv'));writetable(C,fullfile(O,'cage_inputs.csv'));writetable(G,fullfile(O,'group_summary.csv'));writetable(L,fullfile(O,'leave_one_cage_out.csv'));writetable(D,fullfile(O,'model_diagnostics.csv'));writetable(CO,fullfile(O,'cohort_contrasts.csv'));
% Small comparison tables for all outcomes and separate five remaining outcomes.
fid=fopen(fullfile(O,'NUMERICAL_TABLES.md'),'w');fprintf(fid,'# Last-crossing numerical tables\n\nEqual-mouse matched-pair means. Full sample; missing pairs excluded only for their metric. Changes are D14 minus D0.\n\n|Outcome (unit)|SED D0 / D14 / change (n)|WALK D0 / D14 / change (n)|RUN D0 / D14 / change (n)|\n|---|---:|---:|---:|\n');
for k=1:9
 fprintf(fid,'|%s (%s)|',labels(k),units(k));for g=["sedentary","walk","run"],q=P(P.Metric==keys(k)&P.Group==g&P.CompletePair,:);fprintf(fid,'%.3g / %.3g / %+.3g (%d)|',mean(q.D0),mean(q.D14),mean(q.Change),height(q));end;fprintf(fid,'\n');
end
for mod=["D0","D14","Change","ANCOVA"]
 fprintf(fid,'\n## %s — full sample, cohort-adjusted cage model\n\nHC3 pointwise 95%% CI; p is raw, q is Holm-nine.\n\n|Outcome|RUN–WALK estimate [CI]; p / q|RUN–SED estimate [CI]; p / q|\n|---|---:|---:|\n',mod);
 for k=1:9,fprintf(fid,'|%s|',labels(k));for con=["RUN-WALK","RUN-SED"],q=S(S.Subset=="all"&S.Metric==keys(k)&S.Model==mod&S.Contrast==con,:);fprintf(fid,'%.3g [%.3g, %.3g]; %.4g / %.4g|',q.Estimate,q.CI95Low_HC3,q.CI95High_HC3,q.P_HC3,q.PHolm9_HC3);end;fprintf(fid,'\n');end
end
fclose(fid);
% Figure A: cage positions explicitly identify every mouse's cage/cohort.
sel=[1 2 3 5];groups=["sedentary","walk","run"];colors=[.14 .14 .14;0 .55 .25;.03 .39 .81];cageorder=strings(0,1);cg=[];
for gi=1:3,ca=unique(I.CageID(I.Group==groups(gi)));cageorder=[cageorder;ca];cg=[cg;repmat(gi,numel(ca),1)];end
f=figure('Visible','off','Color','w','Position',[40 40 1450 820]);tl=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for ki=1:4
 k=sel(ki);q=P(P.Metric==keys(k),:);ax=nexttile;hold on;
 for j=1:numel(cageorder)
  a=q(q.CageID==cageorder(j),:);col=colors(cg(j),:);off=linspace(-.22,.22,height(a));
  for mi=1:height(a),x=j+off(mi);plot([x-.07 x+.07],[a.D0(mi) a.D14(mi)],'-','Color',.6+.4*col,'LineWidth',.7);scatter(x-.07,a.D0(mi),22,col,'o');scatter(x+.07,a.D14(mi),22,col,'filled');end
 end
 for gi=1:3
  js=find(cg==gi);a=q(q.Group==groups(gi),:);plot([js(1)-.35 js(end)+.35],[mean(a.D0) mean(a.D0)],'--','Color',colors(gi,:),'LineWidth',1.3);plot([js(1)-.35 js(end)+.35],[mean(a.D14) mean(a.D14)],'-','Color',colors(gi,:),'LineWidth',1.8);
 end
 xlim([.4 numel(cageorder)+.6]);xticks(1:numel(cageorder));xticklabels(erase(cageorder,'TMCS'));set(ax,'TickLabelInterpreter','none');xtickangle(50);ylabel(labels(k)+" ("+replace(units(k),'percentage points','%')+")");title(labels(k));box off;
end
title(tl,'A  Last retained crossing: paired D0 and D14','FontSize',17);subtitle(tl,'Open D0 / filled D14; lines pair mice. Group means: dashed D0 / solid D14. SED black; WALK green; RUN blue. Cage labels = cohort_cage.','Interpreter','none');
exportgraphics(f,fullfile(O,'A_paired_last_crossings.png'),'Resolution',170);print(f,fullfile(O,'A_paired_last_crossings.svg'),'-dsvg');close(f);
f=figure('Visible','off','Color','w','Position',[40 40 1400 820]);tl=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
for ki=1:4
 k=sel(ki);q=P(P.Metric==keys(k),:);ax=nexttile;hold on;yline(0,':','Color',[.5 .5 .5]);
 for j=1:numel(cageorder)
  a=q(q.CageID==cageorder(j),:);col=colors(cg(j),:);off=linspace(-.22,.22,height(a));scatter(j+off,a.Change,25,col,'filled','MarkerFaceAlpha',.5);plot(j,mean(a.Change),'kd','MarkerFaceColor',col,'MarkerSize',7);
 end
 for gi=1:3,js=find(cg==gi);a=q(q.Group==groups(gi),:);plot([js(1)-.35 js(end)+.35],[mean(a.Change) mean(a.Change)],'-','Color',colors(gi,:),'LineWidth',2);end
 xlim([.4 numel(cageorder)+.6]);xticks(1:numel(cageorder));xticklabels(erase(cageorder,'TMCS'));set(ax,'TickLabelInterpreter','none');xtickangle(50);ylabel("Change ("+units(k)+")");title(labels(k));box off;
end
title(tl,'B  D14 - D0 last-crossing change','FontSize',17);subtitle(tl,'Dots: paired mice. Diamonds: cage means. Horizontal bars: equal-mouse group means. SED black; WALK green; RUN blue.','Interpreter','none');
exportgraphics(f,fullfile(O,'B_last_crossing_changes.png'),'Resolution',170);print(f,fullfile(O,'B_last_crossing_changes.svg'),'-dsvg');close(f);
fid=fopen(fullfile(O,'VALIDATION.txt'),'w');fprintf(fid,'42 paired mouse identities; 15 cages; 21 exact123-both mice.\nAll 378 D14 source rows match old export, including missingness; max finite error %.12g.\nSlip counts verified against manifest. Unique selected filenames and unchanged mouse/cage/cohort/group mapping checked.\n',maxerr);fclose(fid);
summarizeLastCrossingBB;
focusLastCrossingBB;
disp(S(S.Subset=="all"&ismember(S.Model,["Change","ANCOVA"]),{'Metric','Model','Contrast','Estimate','CI95Low_HC3','CI95High_HC3','P_HC3','PHolm9_HC3'}));fprintf('OUTPUT %s\n',O);
end
function f=fitmodel(X,y)
assert(rank(X)==size(X,2));n=numel(y);p=size(X,2);B=(X'*X)\eye(p);f.b=X\y;f.r=y-X*f.b;f.df=n-p;f.h=sum((X*B).*X,2);sse=sum(f.r.^2);f.ols=B*sse/f.df;
if any(f.h>1-1e-10),f.hc3=nan(p);else,f.hc3=B*(X'*((f.r./(1-f.h)).^2.*X))*B;end
f.cook=f.r.^2/(p*sse/f.df).*f.h./(1-f.h).^2;
end
function [e,lo,hi,p,loc,hic,pc]=contrast(f,c)
e=c*f.b;se=sqrt(max(0,c*f.hc3*c'));if any(isnan(f.hc3),'all'),se=NaN;end;q=tinv(.975,f.df);lo=e-q*se;hi=e+q*se;p=2*tcdf(-abs(e/se),f.df);sec=sqrt(c*f.ols*c');loc=e-q*sec;hic=e+q*sec;pc=2*tcdf(-abs(e/sec),f.df);
end
function out=holm(p)
out=nan(size(p));ix=find(isfinite(p));[v,ord]=sort(p(ix));out(ix(ord))=min(1,cummax(v.*(numel(v):-1:1)'));
end
function [e,p]=permcontrast(y,g,co,name)
% Same enumeration/statistic as existing cage_tests.py and analyzeWithinSessionBB.m.
if name=="RUN-WALK",other="walk";else,other="sedentary";end
v=cell(2,1);obs=zeros(2,1);coh=["TMCS2","TMCS3"];
for k=1:2
 ix=co==coh(k)&ismember(g,["run",other]);yy=y(ix);gg=g(ix);n=sum(gg=="run");assert(n>0&&n<numel(yy));obs(k)=mean(yy(gg=="run"))-mean(yy(gg==other));comb=nchoosek(1:numel(yy),n);v{k}=zeros(size(comb,1),1);
 for j=1:size(comb,1),sel=false(size(yy));sel(comb(j,:))=true;v{k}(j)=mean(yy(sel))-mean(yy(~sel));end
end
e=mean(obs);null=(v{1}+v{2}')/2;p=mean(abs(null(:))>=abs(e)-1e-10);
end
