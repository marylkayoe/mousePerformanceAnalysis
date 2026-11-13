function countBelowBarMotionEpisodes
repo=bbtail.repositoryRoot();out=fullfile(repo,'BEAMCROSS','DRAFTFIGS','tail-metrics','below-bar-episodes');if ~isfolder(out),mkdir(out);end
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';m=readtable(fullfile(repo,'BEAMCROSS','DRAFTFIGS','analysis-data','trial_manifest.csv'),'TextType','string');E=table();S=table();
for ii=1:height(m)
 file=m.File(ii);z=load(fullfile(root,'trials',file+'.profiles.mat'),'P');P=z.P;Q=double(P.probabilityWeighted);n=size(Q,2);f=readtable(fullfile(root,'trials',file+'.trace.csv'),'TextType','string');assert(height(f)==n && isequal(f.OriginalFrame,P.originalFrames(:)));assert(isequal(logical(f.TailBadFrame),logical(P.tailBadFrames(:))));assert(n==m.Frames(ii));fps=m.AnalysisFrameRate(ii);
 raw=nan(n,1);invalid=logical(P.invalidFramePairMask(:))|logical(P.tailBadFrames(:));
 for k=1:n
  v=Q(:,k);if invalid(k)||any(~isfinite(v)|v<0)||sum(v)<=0,continue;end
  row=find(cumsum(v)>=sum(v)/2,1);raw(k)=(P.barTopOriginal-row)*700/1201;
 end
 sm=nan(n,1);
 % Match the validated exporter exactly, including arithmetic near zero.
 for k=1:n
  if ~isfinite(raw(k)),continue;end
  lo=k;while lo>max(1,k-2)&&isfinite(raw(lo-1)),lo=lo-1;end
  hi=k;while hi<min(n,k+2)&&isfinite(raw(hi+1)),hi=hi+1;end
  sm(k)=mean(raw(lo:hi));
 end
 below=isfinite(sm)&sm<0;starts=find(diff([false;below;false])==1);ends=find(diff([false;below;false])==-1)-1;observed=0;complete=0;
 for j=1:numel(starts)
  a=starts(j);b=ends(j);left=a==1||~isfinite(sm(max(1,a-1)));right=b==n||~isfinite(sm(min(n,b+1)));observed=observed+~left;complete=complete+(~left&&~right);
  if a==1,lc="traversal_start";elseif left,lc="invalid_gap";else,lc="observed_downcrossing";end
  if b==n,rc="traversal_end";elseif right,rc="invalid_gap";else,rc="observed_return";end
  row=table(file,m.MouseID(ii),m.Cohort(ii),m.CageID(ii),m.Group(ii),m.Day(ii),m.TrialNumber(ii),j,a,b,f.OriginalFrame(a),f.OriginalFrame(b),f.TimeSeconds(a),f.TimeSeconds(b),fps,b-a+1,(b-a+1)/fps,sm(a),min(sm(a:b)),left,right,lc,rc,...
   'VariableNames',{'File','MouseID','Cohort','CageID','Group','Day','TrialNumber','Segment','StartTraversalFrame','EndTraversalFrame','StartOriginalFrame','EndOriginalFrame','StartEncodedTimeSeconds','EndEncodedTimeSeconds','AnalysisFrameRate','ObservedFrames','ObservedDurationSeconds','StartHeightMM','MinimumHeightMM','LeftCensored','RightCensored','StartStatus','EndStatus'});E=[E;row]; %#ok<AGROW>
 end
 nv=sum(isfinite(sm));nb=sum(below);percent=NaN;if nv>0,percent=100*nb/nv;end
 row=table(file,m.MouseID(ii),m.Cohort(ii),m.CageID(ii),m.Group(ii),m.Day(ii),m.TrialNumber(ii),n,fps,nv,n-nv,nb,nb/fps,percent,numel(starts),observed,complete,median(sm,'omitnan'),mean(sm,'omitnan'),...
 'VariableNames',{'File','MouseID','Cohort','CageID','Group','Day','TrialNumber','Frames','AnalysisFrameRate','ValidHeightFrames','MissingHeightFrames','BelowZeroFrames','BelowZeroSeconds','PercentValidTimeBelowZero','ObservedNegativeSegments','ObservedDowncrossings','CompleteEpisodes','MedianHeightMM','MeanHeightMM'});S=[S;row]; %#ok<AGROW>
 assert(sum(ends-starts+1)==nb);assert(all(~isfinite(sm(invalid))));
 if mod(ii,25)==0,fprintf('Processed %d/%d; segments %d\n',ii,height(m),height(E));end
end
writetable(E,fullfile(out,'episodes.csv'));writetable(S,fullfile(out,'trial_summary.csv'));fprintf('DONE: %d trials, %d observed negative segments\n',height(S),height(E));
end
