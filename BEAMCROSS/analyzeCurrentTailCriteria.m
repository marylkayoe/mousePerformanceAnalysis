function analyzeCurrentTailCriteria(out,files)
% Stream source crops; preserve original pipeline/results; no bulk video exports.
root='/Volumes/ShosaiData/DATA/Tara/RESULTS';if nargin<1,out=fullfile(root,'balance_beam_tail_current_criteria_scatters_20261112');end;if nargin<2,files=strings(0,1);end;if ~isfolder(out),mkdir(out);end
traceDir=fullfile(out,'traces');if ~isfolder(traceDir),mkdir(traceDir);end
diary(fullfile(out,'run.log'));cleanup=onCleanup(@()diary('off'));
old=fullfile(root,'balance_beam_tail_MAD3p5_height7p5_results_20261112','normalized_amplitude');rerun=fullfile(root,'balance_beam_events_traces_L40_20261106');sourceRoot='/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved';
idx=readtable('BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/trial-index.csv','TextType','string');cache=readtable('BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/frame-values.csv');
stems=["D0_first" "D14_last"];if ~isempty(files),stems="example";end
for stem=stems
 if isempty(files),sel=readtable(fullfile(old,stem+'_summary.csv'),'TextType','string');else,sel=table(string(files(:)),'VariableNames',{'File'});end;S=table();E=table();fail=struct('file',{},'error',{});
 for j=1:height(sel)
  name=char(sel.File(j));dest=fullfile(traceDir,[name '.mat']);fprintf('%s %d/%d %s\n',stem,j,height(sel),name);
  try
   if isfile(dest),z=load(dest,'summary','events');summary=z.summary;events=z.events;else
    z=load(fullfile(rerun,'trials',[name '.mat']),'C');C=z.C;z=load(fullfile(rerun,'trials',[name '.profiles.mat']),'P');P=z.P;z=load(fullfile(root,'balance_beam_tail_reweight_L40_halfdepth_20261109','trials',[name '.mat']),'R');R=z.R;
    assert(C.parameters.LOCOTHRESHOLD==40&&C.parameters.SLIPTHRESHOLD==2.5&&C.parameters.MOUSESIZETHRESHOLD==2);assert(isequal(C.originalFrames(:),P.originalFrames(:),R.originalFrames(:)));
    source=fullfile(sourceRoot,name);[D,geometry]=tailCropGeometry(C,source,fullfile(rerun,'code_snapshot'),fullfile(root,'balance_beam_tail_examples_L40_20261109',name,'weights_and_mapping.mat'),true);
    n=D.nFrames;h=D.height;np=D.noMouseProbability;changed=0;
    for k=1:n
     cc=bwconncomp(np(k,:)==0);
     for c=1:cc.NumObjects
      f=cc.PixelIdxList{c};if f(1)>1&&numel(f)<=15,np(k,f)=1;changed=changed+numel(f);end
     end
    end
    weights=np.^2;below=D.barTop+D.barWidth:h;bw=1+min(2*(0:numel(below)-1)'/(numel(below)-1),1);assert(isequal(bw,R.newBelowRowWeights));wholeUnweighted=zeros(n,1);x=zeros(n,1);heightRaw=nan(n,1);oldHeight=nan(n,1);oldx=zeros(n,1);err=0;
    v=VideoReader(source);frame=readFrame(v);isColor=size(frame,3)==3;v.CurrentTime=0;k=0;prev=[];
    for original=1:C.originalFrames(end)
     frame=readFrame(v);if original<C.originalFrames(1),continue;end
     k=k+1;if isColor,frame=rgb2gray(frame);end;crop=frame(:,D.columns(k,:));
     if k>1
      delta=abs(double(crop)-double(prev))/255;q0=sum(delta.*D.columnWeightSquared(k,:),2);q=sum(delta.*weights(k,:),2);ref=double(P.probabilityWeighted(:,k));finite=isfinite(ref);assert(all(abs(q0(finite)-ref(finite))<=1e-6+1e-6*abs(ref(finite))),'Row-profile mismatch');if any(finite),err=max(err,max(abs(q0(finite)-ref(finite))));end
      oldx(k)=bw'*q0(below);x(k)=bw'*q(below);wholeUnweighted(k)=sum(q);
      if all(finite)&&sum(q0)>0,oldHeight(k)=(D.barTop-find(cumsum(q0)>=sum(q0)/2,1))*700/1201;end
      if all(finite)&&sum(q)>0,heightRaw(k)=(D.barTop-find(cumsum(q)>=sum(q)/2,1))*700/1201;end
     end
     prev=crop;
    end
    assert(k==n);finite=isfinite(R.newBelowRaw);assert(all(abs(oldx(finite)-R.newBelowRaw(finite))<=1e-5+1e-6*abs(R.newBelowRaw(finite))));
    valid=~logical(P.tailBadFrames(:)|P.invalidFramePairMask(:))&isfinite(heightRaw)&isfinite(x);oldValid=~logical(P.tailBadFrames(:)|P.invalidFramePairMask(:))&isfinite(oldHeight);oldHeight=localMean(oldHeight,oldValid);ii=find(idx.File==string(name));savedHeight=cache.MotionHeightMM(cache.TrialIndex==ii);assert(numel(savedHeight)==n&&isequal(isfinite(oldHeight),isfinite(savedHeight)));assert(all(abs(oldHeight(oldValid)-savedHeight(oldValid))<1e-8));
    motionHeight=localMean(heightRaw,valid);smoothed=localMean(x,valid);baseline=median(smoothed(valid));madScale=1.4826*median(abs(smoothed(valid)-baseline));assert(isfinite(madScale)&&madScale>0);normalized=max((smoothed-baseline)/madScale,0);events=table();starts=find(diff([false;valid;false])==1);ends=find(diff([false;valid;false])==-1)-1;
    for a=1:numel(starts)
     mask=bwareaopen(imclose(normalized(starts(a):ends(a))>3.5,ones(5,1)),5);cc=bwconncomp(mask);
     for c=1:cc.NumObjects
      f=cc.PixelIdxList{c}+starts(a)-1;[pk,at]=max(normalized(f));q=f(at);pass=motionHeight(q)<=7.5;score=sum(max(normalized(f)-3.5,0));events=[events;table(string(name),min(f),max(f),C.originalFrames(min(f)),C.originalFrames(max(f)),q,C.originalFrames(q),pk,motionHeight(q),pass,score,numel(f),'VariableNames',{'File','StartTraversalFrame','EndTraversalFrame','StartOriginalFrame','EndOriginalFrame','PeakTraversalFrame','PeakOriginalFrame','NormalizedPeak','HeightAtPeakMM','PassHeight','EventScore','DurationFrames'})];
     end
    end
    count=0;total=0;if ~isempty(events),count=sum(events.PassHeight);total=sum(events.EventScore(events.PassHeight));end
    summary=table(string(name),count,total,baseline,madScale,sum(valid),changed,err,'VariableNames',{'File','CountHeightFiltered','TotalScoreHeightFiltered','BaselineMedian','MADScale','JointValidFrames','RestoredColumnFrames','MaxRowProfileError'});
    originalFrames=C.originalFrames;parameters=C.parameters;invalid=~valid;save(dest,'summary','events','wholeUnweighted','x','smoothed','normalized','motionHeight','originalFrames','invalid','parameters','geometry','-v7');
   end
   S=[S;summary];if ~isempty(events),E=[E;events];end
  catch ex
   fail(end+1)=struct('file',name,'error',getReport(ex,'extended','hyperlinks','off'));fprintf('FAILED %s\n%s\n',name,fail(end).error);
  end
  writetable(S,fullfile(out,stem+'_summary.csv'));if ~isempty(E),writetable(E,fullfile(out,stem+'_events.csv'));end
  f=fopen(fullfile(out,stem+'_failures.json'),'w');fwrite(f,jsonencode(fail));fclose(f);
 end
end
end
function y=localMean(x,valid)
y=nan(size(x));a=find(diff([false;valid;false])==1);b=find(diff([false;valid;false])==-1)-1;
for j=1:numel(a),for k=a(j):b(j),y(k)=mean(x(max(a(j),k-2):min(b(j),k+2)));end,end
end
