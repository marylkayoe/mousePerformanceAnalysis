function verifyCandidateBeamTraces(outputDir)
% Recheck saved products and compare every available reference field.
timing=jsondecode(fileread(fullfile(outputDir,'encoded_timing_validation.json')));
P=load(fullfile(outputDir,'provenance.mat')); files=P.files; refFields=P.refFields;
a=load('/Users/yoe/Downloads/BB_values_261105_2.mat'); values=a.values_261105_2;
a=load('/Users/yoe/Downloads/BB_fileNames_261105_2.mat'); names=string(a.fileNames_261105_2);
comparison=table('Size',[0 7],'VariableTypes',{'string','string','double','double','double','logical','string'}, ...
 'VariableNames',{'File','Field','Regenerated','Reference','Difference','Match','Note'});
for j=1:numel(files)
 path=fullfile(outputDir,[char(files(j)) '.mat']); if ~isfile(path), continue; end
 S=load(path); C=S.C; R=C.summary;
 t=timing(find(strcmp({timing.file},char(files(j))),1));
 assert(C.decodedVideoSize(3)==t.timestampCount && C.lastOriginalFrame<=t.timestampCount);
 fprintf('Frame-rate precision check: %.17g (difference from 160 = %.17g)\n',C.frameRate,C.frameRate-160);
 assert(t.maxDeviationFrom160fpsSeconds==0);
 C.videoReaderFrameRate=C.frameRate; C.encodedFrameRate=160;
 C.frameRateMetadataMismatch=abs(C.frameRate-160)>1e-9;
 C.videoReaderDerivedTimeSeconds=(C.originalFrames-1)/C.frameRate;
 C.timeSeconds=(C.originalFrames-1)/C.encodedFrameRate;
 C.encodedTimingValidation=t;
 C.nonfinite.forwardSpeeds=~isfinite(C.forwardSpeeds);
 C.nonfinite.mouseCentroids=~isfinite(C.mouseCentroids);
 C.nonfinite.movementTrace=~isfinite(C.movementTrace);
 C.nonfinite.tailMovementTraceAboveBar=~isfinite(C.tailMovementTraceAboveBar);
 C.internalParameters=struct('USEMORPHOCLEAN',false,'UNDERBARWINDOW',1.5,'mouseContrastThreshold',0.6, ...
 'underBarSmoothFactor',10,'tailSmoothFactor',5,'tailNoMouseProbCutoff',0.85,'tailBadFrameFracThreshold',0.1, ...
 'speedWindowFrames',max(1,floor(C.analysisFrameRate/10)),'barAdjustValue',3,'slipSizeFactor',5);
 save(path,'C','-v7');
 Q=readtable(fullfile(outputDir,[char(files(j)) '.csv']));
 assert(height(Q)==numel(C.originalFrames)); assert(isequal(Q.OriginalFrame,C.originalFrames));
 Q.TimeSeconds=C.timeSeconds; Q.FrameRate(:)=C.encodedFrameRate;
 Q.VideoReaderFrameRate=repmat(C.videoReaderFrameRate,height(Q),1);
 writetable(Q,fullfile(outputDir,[char(files(j)) '.csv']));
 Q=readtable(fullfile(outputDir,[char(files(j)) '.csv']));
 assert(all(abs(Q.TimeSeconds-(Q.OriginalFrame-1)/C.encodedFrameRate)<1e-10));
 A=[C.forwardSpeeds(:),C.mouseCentroids(:,2),C.movementTrace(:),C.tailMovementTraceAboveBar(:)]; B=Q{:,5:8};
 assert(isequal(isnan(A),isnan(B))&&isequal(isinf(A),isinf(B)));
 mask=isfinite(A); assert(all(abs(A(mask)-B(mask))<=1e-10*max(1,abs(A(mask)))));
 idx=find(names==files(j)); assert(numel(idx)==1,'Reference missing or ambiguous');
 referenceRow=values(idx,:); save(fullfile(outputDir,[char(files(j)) '.reference.mat']),'referenceRow','refFields');
 for q=1:numel(refFields)
  field=char(refFields(q)); ref=values{idx,q}; note="scalar";
  if strcmp(field,'tailMovementTrace')
   value=C.tailMovementTrace; note="captured T.tailMovementTrace; array comparison";
  elseif strcmp(field,'stoppingDurationsTotal') && ~isfield(R,field) && isfield(R,'stoppingDurationTotal')
   value=R.stoppingDurationTotal; note="mapped singular stoppingDurationTotal (pipeline branch naming inconsistency)";
  elseif isfield(R,field), value=R.(field);
  else
   comparison(end+1,:)={files(j),string(field),NaN,NaN,NaN,false,"unavailable field"}; continue
  end
  if ~isnumeric(value)||~isnumeric(ref)
   comparison(end+1,:)={files(j),string(field),NaN,NaN,NaN,isequaln(value,ref),"nonnumeric exact comparison"}; continue
  end
  equal=isequal(size(value),size(ref));
  if equal
   equal=all((isnan(value(:))&isnan(ref(:))) | (value(:)==ref(:)) | ...
    (isfinite(value(:))&isfinite(ref(:))&abs(value(:)-ref(:))<=1e-8+1e-6*abs(ref(:))));
  end
  if isscalar(value)&&isscalar(ref)
   comparison(end+1,:)={files(j),string(field),value,ref,value-ref,equal,note};
  else
   comparison(end+1,:)={files(j),string(field),NaN,NaN,NaN,equal,string(sprintf('array sizes regenerated=%s reference=%s; values retained in MAT',mat2str(size(value)),mat2str(size(ref))))};
  end
 end
 fprintf('VERIFIED %s %d frames fps=%.12g analysisfps=%g\n',files(j),height(Q),C.frameRate,C.analysisFrameRate);
end
writetable(comparison,fullfile(outputDir,'summary_comparison.csv'));
status=readtable(fullfile(outputDir,'status.csv'),'TextType','string');
save(fullfile(outputDir,'comparison.mat'),'comparison','status');
disp(groupsummary(comparison,'Field','sum','Match'));
fprintf('VERIFIED_TOTAL %d; comparison matches %d/%d\n',sum(status.Status=="saved"),sum(comparison.Match),height(comparison));
end
