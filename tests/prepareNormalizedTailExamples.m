function prepareNormalizedTailExamples(root,selectionFile)
addpath('BEAMCROSS');
if nargin<1,root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_normalized_tail_examples_20261112';end
if nargin<2,selectionFile='BEAMCROSS/DRAFTFIGS/slip-movie-example-review/normalized_example_selection.json';end
if ~isfolder(root),mkdir(root);end
sel=jsondecode(fileread(selectionFile));
idx=readtable('BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/trial-index.csv','TextType','string');
cache=readtable('BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/frame-values.csv');
for j=1:numel(sel)
 s=sel(j);out=fullfile(root,[s.group '_' s.day]);
 if isfile(fullfile(out,'marked_inputs','metadata.json')),fprintf('Reuse %s\n',out);continue;end
 fprintf('PREPARE %d/6 %s\n',j,s.file);
 prepareTailMetricsTrial(s.file,out,ReconstructWeights=true);
 z=load(fullfile(out,'column_contributions.mat'),'E');E=z.E;
 z=load(fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials',[s.file '.profiles.mat']),'P');P=z.P;
 assert(isequal(E.originalFrames(:),P.originalFrames(:))&&all(E.rowProfileMatches(:))&&all(E.newBelowMatches(:)));
 work=fullfile(out,'marked_inputs');mkdir(work);
 writematrix(double(P.probabilityWeighted)',fullfile(work,'rows.csv'));
 writematrix(double(E.aboveContributions),fullfile(work,'above.csv'));
 writematrix(double(E.newBelowContributions),fullfile(work,'below.csv'));
 i=find(idx.File==string(s.file));assert(isscalar(i));fps=idx.AnalysisFrameRate(i);
 h=cache.MotionHeightMM(cache.TrialIndex==i);
 t=readtable(fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109/trials',[s.file '.csv']));
 assert(height(t)==E.nFrames&&numel(h)==E.nFrames&&isequal(t.OriginalFrame(:),E.originalFrames(:)));
 x=t.NewBelowRaw;valid=~logical(t.TailBadFrame|t.InvalidFramePair)&isfinite(x)&isfinite(h);
 v=x(valid);scale=1.4826*median(abs(v-median(v)));
 a=find(diff([false;valid;false])==1);b=find(diff([false;valid;false])==-1)-1;
 events=zeros(0,6);count=NaN;
 if isfinite(scale)&&scale>0
  count=0;
  for k=1:numel(a)
   if b(k)-a(k)<2,continue;end
   [pk,loc,~,pr]=findpeaks(x(a(k):b(k)),'MinPeakProminence',5*scale,'MinPeakDistance',min(max(1,round(.1*fps)),b(k)-a(k)-1e-6));
   loc=loc+a(k)-1;count=count+numel(loc);
   events=[events;loc(:),t.OriginalFrame(loc), (loc(:)-1)/fps,pk(:),pr(:),h(loc)]; %#ok<AGROW>
  end
 end
 writetable(array2table(events,'VariableNames',{'TraversalFrame','OriginalFrame','TimeSeconds','RawAmplitude','RawProminence','HeightMM'}),fullfile(out,'tail_slip_events.csv'));
 writetable(table(t.OriginalFrame,h,valid,t.TailBadFrame,t.InvalidFramePair,'VariableNames',{'OriginalFrame','MotionHeightMM','PeakJointValid','TailBadFrame','InvalidFramePair'}),fullfile(work,'masks_height.csv'));
 meta=struct('sourceFilename',s.file,'group',s.group,'day',s.day,'mouse',s.mouse,'width',E.width,'height',E.height,'nFrames',E.nFrames,'barTop',E.barTopOriginal,'barWidth',E.barWidth,'originalFrames',double(E.originalFrames(:))','invalid',logical(E.invalidFramePairMask(:))','mmPerPixel',700/1201,'fps',30,'scaleBarMM',20,'displayScale',2,'peakCount',count,'peakMADScale',scale,'peakProminenceThreshold',5*scale);
 f=fopen(fullfile(work,'metadata.json'),'w');fwrite(f,jsonencode(meta));fclose(f);
 fprintf('DONE %d frames %d peaks\n',E.nFrames,count);clear E P z
end
end
