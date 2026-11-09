function runEntranceDetectorAudit(first,last)
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
out='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_entry_review_20261107';
addpath(fullfile(root,'code_snapshot'));addpath(fullfile(out,'detector_instrumentation'),'-begin');
K=readtable(fullfile(out,'review_key.csv'),'TextType','string');files=unique(K.File,'stable');
dest=fullfile(out,'detector_stages');if ~exist(dest,'dir'),mkdir(dest);end
global ENTRANCE_DETECTOR_AUDIT;
for i=first:min(last,numel(files))
 name=char(files(i));statusFile=fullfile(dest,[name '.status.json']);
 if exist(statusFile,'file')
  prior=jsondecode(fileread(statusFile));
  if prior.success,fprintf('SKIP %d %s\n',i,name);continue;end
  movefile(statusFile,[statusFile '.failed_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
 end
 S=load(fullfile(root,'trials',[name '.mat']),'C');C=S.C;
 fprintf('START AUDIT %d/%d %s\n',i,numel(files),name);t=tic;
 try
  ENTRANCE_DETECTOR_AUDIT=[];
  R=auditEntranceSingleFile(fileparts(C.sourcePath),name,'LOCOTHRESHOLD',40,'SLIPTHRESHOLD',2.5,'MOUSESIZETHRESHOLD',2,'EXCLUDE_STOPPING_FRAMES',false,'MAKEPLOT',false,'SHOWVIDEOS',false);
  D=ENTRANCE_DETECTOR_AUDIT;
  assert(isequaln(R.auditForwardSpeeds,C.forwardSpeeds),'Speed mismatch');
  assert(isequaln(R.auditCentroids,C.mouseCentroids),'Centroid mismatch');
  assert(isequal(R.auditMouseFrames(:),C.originalFrames(:)),'Original frame mismatch');
  assert(isequaln(R.auditMovement(:),C.movementTrace(:)),'Movement mismatch');
  assert(isequal(R.auditStarts(:),C.slipEventStarts(:))&&isequal(R.auditDurations(:),C.slipEventDurations(:)),'Event mismatch');
  D.File=name;D.originalFrames=C.originalFrames;D.timeSeconds=C.timeSeconds;D.parameters=C.parameters;
  T=table(C.originalFrames(:),C.timeSeconds(:),C.xEntryRightFraction(:),C.forwardSpeeds(:),C.stoppingFrames(:),D.rawUnweighted(:),D.rawWeighted(:),D.speedMultiplier(:),D.speedAdjusted(:),D.smoothed(:),D.normalizedBeforeClamp(:),D.finalTrace(:),...
   'VariableNames',{'OriginalFrame','TimeSeconds','XEntryRightFraction','ForwardSpeed','StopMask','RawUnweighted','RawWeighted','SpeedMultiplier','SpeedAdjusted','Smoothed','NormalizedBeforeClamp','FinalTrace'});
  writetable(T,fullfile(dest,[name '.csv']));save(fullfile(dest,[name '.mat']),'D','-v7');
  status=struct('File',name,'success',true,'exactTraceSpeedCentroidFrameEventMatch',true,'baselineMedian',D.baselineMedian,'baselineSigma',D.baselineSigma,'baselineFiniteNonStopCount',D.baselineFiniteNonStopCount,'smoothFactor',D.smoothFactor,'elapsedSeconds',toc(t));
 catch ME
  status=struct('File',name,'success',false,'error',getReport(ME,'extended','hyperlinks','off'));
 end
 fid=fopen(statusFile,'w');fprintf(fid,'%s',jsonencode(status));fclose(fid);
 fprintf('DONE AUDIT %d success=%d elapsed=%.1f\n',i,status.success,toc(t));
 clear R C S D T;ENTRANCE_DETECTOR_AUDIT=[];
end
end
