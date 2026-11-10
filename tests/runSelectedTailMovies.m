function runSelectedTailMovies
% Serial, source-regenerated selected crossings; errors remain explicit.
addpath('BEAMCROSS');
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109';
rerun='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
M=jsondecode(fileread(fullfile(root,'selection_manifest.json')));rows=struct([]);
for j=1:numel(M.trials)
 t=M.trials(j);out=fullfile(root,t.folder);
 row=struct('File',string(t.file),'Group',string(t.group),'Day',t.day,'Role',string(t.role), ...
 'Status',"failed",'Error',"",'Folder',string(t.folder),'Frames',NaN,'ValidMedianFrames',NaN, ...
 'TailBadFrames',NaN,'InvalidPairs',NaN,'MissingCentroidFrames',NaN);
 fprintf('BEGIN SELECTED %d/%d %s\n',j,numel(M.trials),t.file);
 try
  info=createTailMetricsDebugForTrial(t.file,out,ReconstructWeights=true);
  z=load(fullfile(rerun,'trials',[t.file '.mat']),'C');C=z.C;
  z=load(fullfile(rerun,'trials',[t.file '.profiles.mat']),'P');P=z.P;
  z=load(fullfile(out,'column_contributions.mat'),'E');E=z.E;
  F=table(C.originalFrames(:),C.timeSeconds(:),C.mouseCentroids(:,1),C.mouseCentroids(:,2), ...
   C.forwardSpeeds(:),C.stoppingFrames(:),C.xEntryRightFraction(:),P.invalidFramePairMask(:), ...
   P.originalTrackingXMissing(:),mean(E.cropColumnCoordinates==C.decodedVideoSize(2)|E.cropColumnCoordinates==1,2), ...
   'VariableNames',{'OriginalFrame','EncodedTimeSeconds','CentroidX','PostureHeight','ForwardSpeed', ...
   'StoppingFrame','CameraFieldEntryRightFraction','InvalidFramePair','MissingOriginalX','EdgeColumnFraction'});
  writetable(F,fullfile(out,'tracking_review.csv'));
  H=readtable(fullfile(out,'render_inputs','motion_height.csv'));
  row.Frames=E.nFrames;row.ValidMedianFrames=sum(~logical(H.InvalidOrUnusable));
  row.TailBadFrames=sum(E.tailBadFrames);row.InvalidPairs=sum(E.invalidFramePairMask);
  row.MissingCentroidFrames=sum(any(~isfinite(C.mouseCentroids),2));row.Status=string(info.status);
 catch e
  row.Error=string(getReport(e,'extended','hyperlinks','off'));fprintf('FAILED %s: %s\n',t.file,e.message);
 end
 rows=[rows;row]; %#ok<AGROW>
 writetable(struct2table(rows),fullfile(root,'batch_status.csv'));
 fprintf('END SELECTED %d/%d %s\n',j,numel(M.trials),row.Status);
 clear C P E F H info
end
end
