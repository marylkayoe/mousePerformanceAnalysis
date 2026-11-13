function scoreTailEventsPawConvention
D=fullfile(pwd,'BEAMCROSS/DRAFTFIGS');root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_MAD3p5_height7p5_results_20261112';out=fullfile(root,'paw_convention_scores');assert(~isfolder(out));mkdir(out);
m=readtable(fullfile(D,'tail-metrics/CDF-D14-and-change/trial-index.csv'),'TextType','string');cache=readtable(fullfile(D,'tail-metrics/CDF-D14-and-change/frame-values.csv'));
for stem=["D0_first" "D14_last"]
 c=readtable(fullfile(root,stem+'_peak_counts.csv'),'TextType','string');peaks=readtable(fullfile(root,stem+'_peak_events.csv'),'TextType','string');S=table();E=table();
 for i=1:height(c)
 file=c.File(i);ix=find(m.File==file);h=cache.MotionHeightMM(cache.TrialIndex==ix);t=readtable(fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109/trials',file+'.csv'));assert(numel(h)==height(t));x=t.NewBelowRaw;valid=~logical(t.TailBadFrame|t.InvalidFramePair)&isfinite(x)&isfinite(h);scale=c.RawMADScale(i);z=(x-median(x(valid)))/scale;z(z<0)=0;
 a=find(diff([false;valid;false])==1);b=find(diff([false;valid;false])==-1)-1;accepted=peaks.TraversalFrame(peaks.File==file);areas=[];covered=[];nComponents=0;
 for j=1:numel(a)
  mask=imclose(z(a(j):b(j))>3.5,ones(5,1));mask=bwareaopen(mask,5);cc=bwconncomp(mask);
  for k=1:cc.NumObjects
   f=cc.PixelIdxList{k}+a(j)-1;nComponents=nComponents+1;in=accepted(ismember(accepted,f));if isempty(in),continue;end
   score=sum(max(z(f)-3.5,0));areas(end+1)=score;covered=[covered;in(:)];
   E=[E;table(file,min(f),max(f),t.OriginalFrame(min(f)),t.OriginalFrame(max(f)),score,numel(f),numel(in),'VariableNames',{'File','StartTraversalFrame','EndTraversalFrame','StartOriginalFrame','EndOriginalFrame','EventScore','DurationFrames','AcceptedPeaksInComponent'})];
  end
 end
 total=sum(areas);av=mean(areas);if isempty(areas),av=NaN;end
 S=[S;table(file,total,av,numel(areas),numel(accepted),numel(unique(covered)),nComponents,'VariableNames',{'File','TotalEventScore','MeanEventScore','ScoredComponents','AcceptedPeaks','CoveredPeaks','AllMorphologyComponents'})];
 end
 writetable(S,fullfile(out,stem+'_scores.csv'));writetable(E,fullfile(out,stem+'_events.csv'));disp(S(:,2:6));
end
end
