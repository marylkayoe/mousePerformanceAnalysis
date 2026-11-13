function countD0FirstBelowBarPeaks(day,selection)
% Defaults preserve original D0-first workflow; also supports D14-last.
if nargin<1,day=0;end
if nargin<2,selection="first";end
assert(ismember(day,[0 14])&&ismember(string(selection),["first","last"]));
repo=bbtail.repositoryRoot();D=fullfile(repo,'BEAMCROSS/DRAFTFIGS');out=fullfile(D,'tail-metrics/below-bar-episodes/peak-pilot-strict');sel=readtable(fullfile(D,'D0-first-trial-panels/trial_values.csv'),'TextType','string');m=readtable(fullfile(D,'tail-metrics/CDF-D14-and-change/trial-index.csv'),'TextType','string');cache=readtable(fullfile(D,'tail-metrics/CDF-D14-and-change/frame-values.csv'));S=table();E=table();
if day~=0||string(selection)~="first"
 mm=m(m.Day==day,:);ids=unique(mm.MouseID,'stable');names=strings(numel(ids),1);
 for k=1:numel(ids)
  ix=find(mm.MouseID==ids(k));if string(selection)=="last",[~,j]=max(mm.TrialNumber(ix));else,[~,j]=min(mm.TrialNumber(ix));end
  names(k)=mm.File(ix(j));
 end
 sel=table(names,'VariableNames',{'file'});
end
stem=sprintf('D%d_%s',day,selection);
for ii=1:height(sel)
 file=sel.file(ii);i=find(m.File==file);assert(isscalar(i)&&m.Day(i)==day);fps=m.AnalysisFrameRate(i);t=readtable(fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109/trials',file+'.csv'));h=cache.MotionHeightMM(cache.TrialIndex==i);assert(height(t)==numel(h)&&t.OriginalFrame(1)==m.FirstOriginalFrame(i)&&t.OriginalFrame(end)==m.LastOriginalFrame(i)&&all(diff(t.OriginalFrame)==1));x=t.NewBelowRaw;valid=~logical(t.TailBadFrame|t.InvalidFramePair)&isfinite(x)&isfinite(h);v=x(valid);scale=1.4826*median(abs(v-median(v)));a=find(diff([false;valid;false])==1);b=find(diff([false;valid;false])==-1)-1;count=NaN;
 if isfinite(scale)&&scale>0
  count=0;
  for j=1:numel(a)
   if b(j)-a(j)<2,continue;end
   [p,l,~,pr]=findpeaks(x(a(j):b(j)),'MinPeakProminence',5*scale,'MinPeakDistance',min(max(1,round(.1*fps)),b(j)-a(j)-1e-6));l=l+a(j)-1;count=count+numel(l);
   for k=1:numel(l)
    rec=table(file,l(k),t.OriginalFrame(l(k)),(l(k)-1)/fps,p(k),pr(k),h(l(k)),'VariableNames',{'File','TraversalFrame','OriginalFrame','TimeSeconds','RawAmplitude','RawProminence','HeightMM'});E=[E;rec];
   end
  end
 end
 rec=table(file,count,scale,5*scale,sum(valid),sum(valid)/fps,height(t),'VariableNames',{'File','PeakCount','RawMADScale','RawProminenceThreshold','JointValidFrames','JointValidSeconds','Frames'});S=[S;rec];
end
assert(height(S)==42);writetable(S,fullfile(out,[stem '_peak_counts.csv']));writetable(E,fullfile(out,[stem '_peak_events.csv']));fprintf('Done: %d selected trials, %d peaks\n',height(S),height(E));
end
