function exportD0TailSpatialProfiles
repo=fileparts(fileparts(mfilename('fullpath')));out=fullfile(repo,'BEAMCROSS/DRAFTFIGS/tail-metrics/D0-spatial-motion-and-height');root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';newroot='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110';m=readtable(fullfile(repo,'BEAMCROSS/DRAFTFIGS/analysis-data/trial_manifest.csv'),'TextType','string');m=m(m.Day==0,:);binTable=table();qc=table();
for ii=1:height(m)
 name=m.File(ii);z=load(fullfile(root,'trials',name+'.profiles.mat'),'P');P=z.P;Q=double(P.probabilityWeighted);n=size(Q,2);t=readtable(fullfile(root,'trials',name+'.trace.csv'),'TextType','string');s=readtable(fullfile(newroot,'trials',name+'.csv'),'TextType','string');assert(height(t)==n&&height(s)==n);assert(isequal(t.OriginalFrame,s.OriginalFrame)&&isequal(t.OriginalFrame,P.originalFrames(:)));assert(isequal(s.TailBadFrame,double(P.tailBadFrames(:))));assert(all(abs(s.EncodedTimeSeconds-P.timeSeconds(:))<1e-9));raw=nan(n,1);invalid=P.invalidFramePairMask(:)|P.tailBadFrames(:);
for k=1:n
 v=Q(:,k);if invalid(k)||any(~isfinite(v)|v<0)||sum(v)<=0,continue;end
 row=find(cumsum(v)>=sum(v)/2,1);raw(k)=(P.barTopOriginal-row)*700/1201;
end
sm=nan(n,1);for k=1:n
 if ~isfinite(raw(k)),continue;end
 lo=k;while lo>max(1,k-2)&&isfinite(raw(lo-1)),lo=lo-1;end
 hi=k;while hi<min(n,k+2)&&isfinite(raw(hi+1)),hi=hi+1;end
 sm(k)=mean(raw(lo:hi));
end
pos=700-(t.XEntryRightFraction*1279-42)*700/1201;score=s.NewWholeNormalized;score(invalid)=NaN;within=isfinite(pos)&pos>=0&pos<=700;bin=min(floor(pos/10),69);
for b=0:69
 use=within&bin==b;hv=sm(use&isfinite(sm));sv=score(use&isfinite(score));if isempty(hv)&&isempty(sv),continue;end
 rec=table(name,m.MouseID(ii),m.Cohort(ii),m.CageID(ii),m.Group(ii),b,10*b+5,numel(hv),mean(hv),numel(sv),mean(sv),'VariableNames',{'File','MouseID','Cohort','CageID','Group','Bin','DistanceFromEntryMM','HeightFrames','HeightMean','ScoreFrames','ScoreMean'});binTable=[binTable;rec];
end
rec=table(name,n,sum(invalid),sum(isfinite(sm)),sum(isfinite(score)),sum(within),'VariableNames',{'File','Frames','InvalidPairsOrTailBad','ValidHeight','ValidScore','WithinTapeFrames'});qc=[qc;rec];
if mod(ii,20)==0,fprintf('Processed %d/%d trials\n',ii,height(m));end
end
writetable(binTable,fullfile(out,'trial-position-bins.csv'));writetable(qc,fullfile(out,'trial-validation.csv'));fprintf('Completed %d D0 trials\n',height(m));
end
