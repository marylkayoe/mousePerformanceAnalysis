function info=createTailMetricsDebugForTrial(name,out,opts)
%CREATETAILMETRICSDEBUGFORTRIAL Prepare and render one retained original trial.
% All outputs, including rendering inputs, stay in the new requested folder.
arguments
 name (1,:) char
 out (1,:) char
 opts.SourceRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved'
 opts.RerunRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106'
 opts.CorrectedRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109'
 opts.ExampleRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_examples_L40_20261109'
 opts.ReconstructWeights (1,1) logical = false
 opts.MillimetersPerPixel (1,1) double {mustBePositive,mustBeFinite} = 700/1201
end
assert(~isfolder(out)&&~isfile(out),'Output exists; choose a fresh folder.');
try
 prep=prepareTailMetricsTrial(name,out,SourceRoot=opts.SourceRoot,RerunRoot=opts.RerunRoot, ...
  CorrectedRoot=opts.CorrectedRoot,ExampleRoot=opts.ExampleRoot,ReconstructWeights=opts.ReconstructWeights);
 movie=fullfile(out,[name '.tail_metrics_debug.mp4']);
 render=createTailMetricsDebugVideo(out,fullfile(opts.RerunRoot,'trials',[name '.profiles.mat']),movie, ...
  MillimetersPerPixel=opts.MillimetersPerPixel,ScaleBarMM=20,WorkFolder=fullfile(out,'render_inputs'));
 info=struct('status','complete','preparation',prep,'render',render, ...
  'medianDefinition','Full probability-weighted row profile, weighted median, centered five-frame mean within contiguous valid segments; no 5 mm blanking.', ...
  'calibrationNote','Default 700/1201 mm/pixel is the inherited approximate calibration, not a per-trial physical calibration.');
catch e
 if isfolder(out),saveStatus(out,struct('status','failed','fileName',name,'error',getReport(e,'extended','hyperlinks','off')));end
 rethrow(e);
end
saveStatus(out,info);
end
function saveStatus(out,value)
fid=fopen(fullfile(out,'workflow_status.json'),'w');assert(fid>=0);clean=onCleanup(@()fclose(fid));fwrite(fid,jsonencode(value));
end
