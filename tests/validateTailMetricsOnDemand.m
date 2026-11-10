function validateTailMetricsOnDemand
% Positive two-trial and negative input/overwrite/identity validation.
addpath('BEAMCROSS');
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_debug_ondemand_20261109';
rerun='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
corrected='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109';
folders={'runner','sedentary_trial1'};results=struct([]);
for j=1:2
 folder=fullfile(root,folders{j});z=load(fullfile(folder,'column_contributions.mat'),'E');E=z.E;
 z=load(fullfile(rerun,'trials',[E.fileName '.profiles.mat']),'P');P=z.P;
 t=validateTailMetricsPreparation(folder,rerun,corrected);
 fid=fopen(fullfile(folder,'decoded_contribution_trace_validation.json'),'w');fwrite(fid,jsonencode(t));fclose(fid);
 Q=double(P.probabilityWeighted);n=E.nFrames;raw=nan(n,1);valid=false(n,1);
 for k=1:n
  vals=[Q(:,k);E.aboveContributions(k,:)';E.newBelowContributions(k,:)'];
  if P.invalidFramePairMask(k)||any(~isfinite(vals)|vals<0)||sum(Q(:,k))<=0,continue;end
  valid(k)=true;rr=find(cumsum(Q(:,k))>=sum(Q(:,k))/2,1,'first');raw(k)=(E.barTopOriginal-rr)*(700/1201);
 end
 sm=nan(n,1);
 for k=find(valid)'
  lo=k;while lo>max(1,k-2)&&isfinite(raw(lo-1)),lo=lo-1;end
  hi=k;while hi<min(n,k+2)&&isfinite(raw(hi+1)),hi=hi+1;end
  sm(k)=mean(raw(lo:hi));
 end
 m=readtable(fullfile(folder,'render_inputs','motion_height.csv'));
 assert(isequal(m.OriginalFrame,E.originalFrames(:)));
 assert(isequal(logical(m.InvalidOrUnusable),~valid));
 assert(all((isnan(raw)&isnan(m.WeightedMedianMM))|abs(raw-m.WeightedMedianMM)<1e-10));
 assert(all((isnan(sm)&isnan(m.WeightedMedianSmoothed5MM))|abs(sm-m.WeightedMedianSmoothed5MM)<1e-10));
 row=struct('fileName',E.fileName,'frames',n,'validMedianFrames',sum(valid),'medianMatches',true, ...
  'normalizedTraces',t,'firstOriginalFrame',E.originalFrames(1),'lastOriginalFrame',E.originalFrames(end));
 if j==1
  prior=load('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_running_column_export_L40_halfdepth_20261109/column_contributions.mat','E');
  assert(isequaln(E.aboveContributions,prior.E.aboveContributions)&&isequaln(E.newBelowContributions,prior.E.newBelowContributions));
  assert(isequal(E.cropColumnCoordinates,prior.E.cropColumnCoordinates)&&isequal(E.destinationColumnWeightSquared,prior.E.destinationColumnWeightSquared));
 end
 results=[results;row]; %#ok<AGROW>
end
% Expected failures stay explicit and must not create/overwrite a valid movie.
blockedOverwrite=false;
try,prepareTailMetricsTrial(results(1).fileName,fullfile(root,'runner'));catch e,blockedOverwrite=contains(e.message,'Output exists');end
assert(blockedOverwrite);
missing=false;
try,prepareTailMetricsTrial('missing_original_trial.mp4',fullfile(root,'expected_missing_input'));catch e,missing=contains(e.message,'Missing required input');end
assert(missing);
mismatch=false;
try
 createTailMetricsDebugVideo(fullfile(root,'runner'),fullfile(rerun,'trials',[results(2).fileName '.profiles.mat']),fullfile(root,'wrong_trial_should_not_exist.mp4'));
catch e,mismatch=contains(e.message,'Profile filename does not match');end
assert(mismatch&&~isfile(fullfile(root,'wrong_trial_should_not_exist.mp4')));
report=struct('trials',results,'runnerExactPriorExportMatch',true,'overwriteRefused',blockedOverwrite, ...
 'missingInputRefused',missing,'mismatchedTrialRefused',mismatch,'medianUsesAllRows',true,'medianSmoothingFrames',5,'scaleBarMM',20);
fid=fopen(fullfile(root,'workflow_validation.json'),'w');fwrite(fid,jsonencode(report));fclose(fid);
disp(report);
end
