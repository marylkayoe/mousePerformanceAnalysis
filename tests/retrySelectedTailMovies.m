function retrySelectedTailMovies
% Retry failed preparations into new folders; retain initial failure records.
addpath('BEAMCROSS');root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109';
rerun='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
S=readtable(fullfile(root,'batch_status.csv'),'TextType','string');S=S(S.Status~="complete",:);
for j=1:height(S)
 name=char(S.File(j));folder=[char(S.Folder(j)) '_retry_even_view'];out=fullfile(root,folder);
 fprintf('RETRY %d/%d %s\n',j,height(S),name);
 try
  info=createTailMetricsDebugForTrial(name,out,ReconstructWeights=true);
  z=load(fullfile(rerun,'trials',[name '.mat']),'C');C=z.C;
  z=load(fullfile(rerun,'trials',[name '.profiles.mat']),'P');P=z.P;
  z=load(fullfile(out,'column_contributions.mat'),'E');E=z.E;
  F=table(C.originalFrames(:),C.timeSeconds(:),C.mouseCentroids(:,1),C.mouseCentroids(:,2), ...
   C.forwardSpeeds(:),C.stoppingFrames(:),C.xEntryRightFraction(:),P.invalidFramePairMask(:), ...
   P.originalTrackingXMissing(:),mean(E.cropColumnCoordinates==C.decodedVideoSize(2)|E.cropColumnCoordinates==1,2), ...
   'VariableNames',{'OriginalFrame','EncodedTimeSeconds','CentroidX','PostureHeight','ForwardSpeed', ...
   'StoppingFrame','CameraFieldEntryRightFraction','InvalidFramePair','MissingOriginalX','EdgeColumnFraction'});
  writetable(F,fullfile(out,'tracking_review.csv'));H=readtable(fullfile(out,'render_inputs','motion_height.csv'));
  S.Status(j)=string(info.status);S.Error(j)="Initial H.264 odd-width failure resolved: only viewing copy padded to even dimensions. Lossless crop unchanged.";
  S.Folder(j)=string(folder);S.Frames(j)=E.nFrames;S.ValidMedianFrames(j)=sum(~logical(H.InvalidOrUnusable));
  S.TailBadFrames(j)=sum(E.tailBadFrames);S.InvalidPairs(j)=sum(E.invalidFramePairMask);
  S.MissingCentroidFrames(j)=sum(any(~isfinite(C.mouseCentroids),2));
 catch e
  S.Status(j)="failed";S.Error(j)=string(getReport(e,'extended','hyperlinks','off'));fprintf('RETRY FAILED: %s\n',e.message);
 end
 writetable(S(1:j,:),fullfile(root,'retry_batch_status.csv'));
end
end
