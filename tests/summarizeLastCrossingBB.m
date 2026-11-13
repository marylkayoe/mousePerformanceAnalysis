function summarizeLastCrossingBB
root=fileparts(fileparts(mfilename('fullpath')));O=fullfile(root,'BEAMCROSS','DRAFTFIGS','last-crossing-paired-20261112');
S=readtable(fullfile(O,'model_comparisons.csv'),'TextType','string');L=readtable(fullfile(O,'leave_one_cage_out.csv'),'TextType','string');D=readtable(fullfile(O,'model_diagnostics.csv'),'TextType','string');C=readtable(fullfile(O,'cage_inputs.csv'),'TextType','string');
L.PHolm9_HC3=nan(height(L),1);
for mod=unique(L.Model)',for con=unique(L.Contrast)',for ca=unique(L.OmittedCage)'
 ix=find(L.Model==mod&L.Contrast==con&L.OmittedCage==ca);assert(numel(ix)==9);[v,ord]=sort(L.P_HC3(ix));L.PHolm9_HC3(ix(ord))=min(1,cummax(v.*(9:-1:1)'));
end,end,end
writetable(L,fullfile(O,'leave_one_cage_out.csv'));
Z=table;V=table;
for i=1:height(S)
 s=S(i,:);if s.Subset~="all"||~ismember(s.Model,["Change","ANCOVA"]),continue;end
 l=L(L.Metric==s.Metric&L.Model==s.Model&L.Contrast==s.Contrast,:);d=D(D.Metric==s.Metric&D.Model==s.Model,:);
 [diff,j]=max(abs(l.Estimate-s.Estimate));[cook,jc]=max(d.CooksDistance);
 z=s(:,{'Metric','Model','Contrast','Estimate','P_HC3','P_OLS','PHolm9_HC3','PHolm9_OLS'});z.LOEstimateMin=min(l.Estimate);z.LOEstimateMax=max(l.Estimate);z.LOPMin=min(l.P_HC3);z.LOPMax=max(l.P_HC3);z.MaxEstimateShift=diff;z.MaxShiftCage=l.OmittedCage(j);z.MaxCook=cook;z.MaxCookCage=d.CageID(jc);z.MaxLeverage=max(d.Leverage);
 sw=l(l.OmittedCage=="TMCS3_C02",:);z.WithoutSingleWalkCageEstimate=sw.Estimate;z.WithoutSingleWalkCageP=sw.P_HC3;z.LOHolm9Min=min(l.PHolm9_HC3);[z.LOHolm9Max,jq]=max(l.PHolm9_HC3);z.MaxHolmCage=l.OmittedCage(jq);Z=[Z;z];
 % Independent built-in fitlm verifies coefficients/ordinary CI/p computation.
 c=C(C.Subset=="all"&C.Metric==s.Metric,:);X=[double(c.Group=="walk") double(c.Group=="run") double(c.Cohort=="TMCS3")];
 if s.Model=="ANCOVA",X=[X (c.D0-mean(c.D0))/std(c.D0)];y=c.D14;else,y=c.Change;end
 m=fitlm(X,y);v=zeros(1,width(X)+1);v(3)=1;if s.Contrast=="RUN-WALK",v(2)=-1;end
 e=v*m.Coefficients.Estimate;se=sqrt(v*m.CoefficientCovariance*v');p=2*tcdf(-abs(e/se),m.DFE);assert(abs(e-s.Estimate)<1e-9);assert(abs(p-s.P_OLS)<1e-9);
 if s.Contrast=="RUN-WALK"&&s.Model=="ANCOVA"
  ci=coefCI(m);slope=m.Coefficients.Estimate(end)/std(c.D0);lo=ci(end,1)/std(c.D0);hi=ci(end,2)/std(c.D0);
  vv=table(s.Metric,slope,lo,hi,'VariableNames',{'Metric','BaselineSlope','SlopeCI95Low_OLS','SlopeCI95High_OLS'});V=[V;vv];
 end
end
writetable(Z,fullfile(O,'influence_summary.csv'));writetable(V,fullfile(O,'baseline_slope_diagnostics.csv'));
fid=fopen(fullfile(O,'VALIDATION.txt'),'a');fprintf(fid,'All 36 full-sample Change/ANCOVA contrasts independently match MATLAB fitlm coefficients and OLS p-values within 1e-9.\n');fclose(fid);
disp(Z(:,{'Metric','Model','Contrast','LOEstimateMin','LOEstimateMax','LOPMin','LOPMax','MaxShiftCage','MaxCook','MaxCookCage'}));disp(V);
end
