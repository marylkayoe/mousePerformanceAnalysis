function rerunTaraBeamDataset(outputDir,indices)
% Serial, restartable extraction using a frozen additive-instrumentation copy.
M=jsondecode(fileread(fullfile(outputDir,'run_manifest.json')));
addpath(fullfile(outputDir,'code_snapshot'),'-begin'); set(groot,'defaultFigureVisible','off');
setenv('TARA_BEAM_OUTPUT',outputDir);
a=load('/Users/yoe/Downloads/BB_values_261105_2.mat'); refValues=a.values_261105_2;
a=load('/Users/yoe/Downloads/BB_fileNames_261105_2.mat'); refFiles=string(a.fileNames_261105_2);
a=load('/Users/yoe/Downloads/BB_fieldNames_261105_2.mat'); refFields=string(a.fieldsToExtract);
for j=indices
 info=M.files(j); base=fullfile(outputDir,'trials',info.file);
 if isfile([base '.status.json']), fprintf('SKIP %d %s\n',j,info.file); continue; end
 checkResources(); fprintf('START %d/%d %s\n',j,numel(M.files),info.file); tic
 logPath=fullfile(outputDir,'logs',[info.file '.log']); diary(logPath);
 checkpoint=[base '.checkpoint.mat']; setenv('TARA_BEAM_CHECKPOINT',checkpoint);
 % Audit one trial per group/day, determined by manifest order, not outcome.
 earlier=M.files(1:j-1); same=false;
 for e=1:numel(earlier), same=same||(strcmp(earlier(e).group,info.group)&&earlier(e).day==info.day); end
 setenv('TARA_BEAM_DEBUG',sprintf('%d',~same && ismember(info.day,[0 14])));
 C=struct; errorText='';
 try
  assert(isfile(info.sourcePath),'Source missing');
  R=capturedTaraBeam(M.sourceRoot,info.file,'LOCOTHRESHOLD',40,'SLIPTHRESHOLD',2.5, ...
   'MOUSESIZETHRESHOLD',2,'EXCLUDE_STOPPING_FRAMES',false,'MAKEPLOT',false,'SHOWVIDEOS',false);
  assert(isstruct(R)&&isfield(R,'capture'),'Top-level analysis returned no capture'); C=R.capture; clear R
 catch ME
  errorText=getReport(ME,'extended','hyperlinks','off'); disp(errorText);
  if isfile(checkpoint), S=load(checkpoint); C=S.C; clear S; end
 end
 status=struct('index',j,'file',info.file,'status','failed','stage','none','error',errorText,'elapsedSeconds',toc);
 try
  if ~isfield(C,'originalFrames'), error('No traversal available'); end
  C.identifiers=info; C.gitCommit=M.gitCommit; C.matlabVersion=version; C.analysisError=errorText;
  timing=jsondecode(fileread(fullfile(outputDir,'metadata',[info.file '.json'])));
  assert(isfield(timing,'timestampsSeconds'),'Encoded timing unavailable');
  allTimes=timing.timestampsSeconds(:); n=numel(C.originalFrames);
  assert(C.decodedVideoSize(3)==numel(allTimes),'Decoded/encoded frame counts differ');
  assert(n>0 && all(diff(C.originalFrames)==1) && C.originalFrames(1)>=1 && C.originalFrames(end)<=numel(allTimes));
  C.timeSeconds=allTimes(C.originalFrames); C.encodedFrameRate=1/median(diff(allTimes));
  C.frameRateMetadataMismatch=abs(C.videoReaderFrameRate-C.encodedFrameRate)>1e-6;
  C.encodedTiming=rmfield(timing,'timestampsSeconds');
  C.traversalFrames=(1:n)'; C.frameLengths=struct;
  names={'forwardSpeeds','stoppingFrames','movementTrace','tailMovementTrace','tailMovementTraceAboveBar','tailMovementTraceUnderBar','tailBadFrames','verticalMotionTrace'};
  assert(size(C.mouseCentroids,1)==n,'Centroid length mismatch');
  for k=1:numel(names)
   name=names{k}; if isfield(C,name), C.frameLengths.(name)=numel(C.(name)); assert(numel(C.(name))==n,['Length mismatch: ' name]); end
  end
  C.xOriginal=C.mouseCentroids(:,1); C.xEntryRight=C.xOriginal;
  if ~C.mouseEntersFromRight, C.xEntryRight=C.decodedVideoSize(2)+1-C.xOriginal; end
  C.xEntryRightFraction=(C.xEntryRight-1)/(C.decodedVideoSize(2)-1);
  C.yOriginal=C.decodedVideoSize(1)*ones(n,1); % overwritten with exact inverse crop transform
  C.yOriginal=(C.cropRange(2)-C.cropRange(1)+1)+1-C.barTopCoordAnalysis-C.mouseCentroids(:,2)+C.cropRange(1)-1;
  C.orientationFromMotion=NaN; valid=find(isfinite(C.xOriginal));
  if numel(valid)>=2, C.orientationFromMotion=sign(C.xOriginal(valid(end))-C.xOriginal(valid(1))); end
  C.entryDirectionConsistent=(C.mouseEntersFromRight && C.orientationFromMotion<0)||(~C.mouseEntersFromRight && C.orientationFromMotion>0);
  C.validation=validateEvents(C);
  if isfield(C,'rowMotion')
   P=C.rowMotion; assert(size(P.unweighted,2)==n && size(P.unweighted,1)==C.decodedVideoSize(1));
   P.originalFrames=C.originalFrames; P.timeSeconds=C.timeSeconds; P.fileName=info.file;
   C.rowMotionIndices=rmfield(P,{'unweighted','probabilityWeighted'});
   save([base '.profiles.mat'],'P','-v7');
   C=rmfield(C,'rowMotion'); clear P
  end
  C.nonfinite=struct;
  for k=1:numel(names), name=names{k}; if isfield(C,name), C.nonfinite.(name)=~isfinite(C.(name)); end; end
  C.nonfinite.mouseCentroids=~isfinite(C.mouseCentroids);
  [comparison,C.referenceSummaryMatch]=compareReference(C,refValues,refFiles,refFields);
  E=makeEvents(C); C.events=E;
  save([base '.mat'],'C','-v7'); writetable(comparison,[base '.comparison.csv']);
  writetable(E,[base '.events.csv']);
  F=makeTrace(C); writetable(F,[base '.trace.csv']);
  check=readtable([base '.trace.csv']); assert(height(check)==n && isequal(check.OriginalFrame,C.originalFrames));
  A=F{:,{'CentroidX','CentroidYBarRelative','ForwardSpeed','MovementTrace','TailTotal','TailAboveBar','TailBelowBar'}};
  B=check{:,{'CentroidX','CentroidYBarRelative','ForwardSpeed','MovementTrace','TailTotal','TailAboveBar','TailBelowBar'}};
  assert(isequal(isnan(A),isnan(B))&&isequal(isinf(A),isinf(B)));
  ok=isfinite(A);assert(all(abs(A(ok)-B(ok))<=1e-9*max(1,abs(A(ok)))));
  status.stage=C.stage; status.status='partial'; if strcmp(C.stage,'complete'),status.status='complete';end
  status.nFrames=n;status.nSlips=sum(E.Type=="slip");status.nStops=sum(E.Type=="stop");
  status.slipValidation=C.validation.slipValid;status.stopValidation=C.validation.stopValid;
  status.slipReferenceMatch=C.referenceSummaryMatch.slip;status.stopReferenceMatch=C.referenceSummaryMatch.stop;
  status.entryDirectionConsistent=C.entryDirectionConsistent;
  status.frameRateMetadataMismatch=C.frameRateMetadataMismatch;status.analysisFrameRate=C.analysisFrameRate;
  status.tailBadFrames=NaN;if isfield(C,'tailBadFrames'),status.tailBadFrames=sum(C.tailBadFrames);end
  status.profileReconstructionMatch=false;if isfield(C,'rowMotionIndices'),status.profileReconstructionMatch=all(C.rowMotionIndices.scalarReconstructionMatch);end
 catch ME
  additional=getReport(ME,'extended','hyperlinks','off');disp(additional);
  status.error=[errorText newline additional];
  if ~isempty(fieldnames(C)),save([base '.unaligned_or_failed.mat'],'C','-v7');end
 end
 status.elapsedSeconds=toc;
 fid=fopen([base '.status.json'],'w');fwrite(fid,jsonencode(status));fclose(fid);
 fprintf('DONE %d %s status=%s elapsed=%.1fs\n',j,info.file,status.status,status.elapsedSeconds);
 diary off;clear C E F A B check comparison;close all force
end
end

function checkResources()
[~,disk]=system('df -k /System/Volumes/Data');lines=splitlines(strtrim(disk)); parts=strsplit(strtrim(lines{end}));
assert(str2double(parts{4})/1024^2>=20,'Internal free space below 20 GiB');
[~,swap]=system('sysctl vm.swapusage');fprintf('%s',swap);
end

function V=validateEvents(C)
n=numel(C.originalFrames); stops=C.stoppingStartStops;
mask=false(n,1);valid=true;
for k=1:size(stops,1)
 a=stops(k,1);b=stops(k,2);valid=valid&&a>=1&&b<=n&&b>=a&&a==fix(a)&&b==fix(b);
 if valid,mask(a:b)=true;end
end
V=struct('stopValid',valid&&isequal(mask,logical(C.stoppingFrames(:))),'slipValid',false);
% Independent interval extraction from the preserved stop mask.
edges=diff([false;logical(C.stoppingFrames(:));false]);pairs=[find(edges==1),find(edges==-1)-1];
V.stopValid=V.stopValid&&isequal(pairs,stops);
if isfield(C,'movementTrace')
 starts=C.slipEventStarts(:);dur=C.slipEventDurations(:);mask=false(n,1);
 valid=all(isfinite(C.movementTrace));
 for k=1:numel(starts)
  a=starts(k);b=a+dur(k)-1;valid=valid&&a>=1&&b<=n&&b>=a&&a==fix(a)&&b==fix(b);
  if valid,mask(a:b)=true;end
 end
 expected=bwareaopen(imclose(C.movementTrace(:)>2.5,ones(5,1)),5);
 V.slipValid=valid&&isequal(mask,expected);
end
end

function [T,matches]=compareReference(C,values,files,fields)
T=table('Size',[0 7],'VariableTypes',{'string','string','double','double','double','logical','string'}, ...
 'VariableNames',{'File','Field','Regenerated','Reference','Difference','Match','Note'});
idx=find(files==string(C.fileName)); matches=struct('slip',false,'stop',false);
if numel(idx)~=1,T(end+1,:)={string(C.fileName),"ALL",NaN,NaN,NaN,false,"reference filename missing or ambiguous"};return;end
R=C.summary;
for q=1:numel(fields)
 f=char(fields(q));ref=values{idx,q};note="";
 if strcmp(f,'tailMovementTrace')
  if ~isfield(C,'tailMovementTrace'),continue;end;v=C.tailMovementTrace;
 elseif strcmp(f,'stoppingDurationsTotal')
  if isfield(R,f),v=R.(f);elseif isfield(R,'stoppingDurationTotal'),v=R.stoppingDurationTotal;note="pipeline singular-field alias; may contain traversal length, not actual stop frames";else,v=NaN;end
 elseif isfield(R,f),v=R.(f);
 else,T(end+1,:)={string(C.fileName),string(f),NaN,NaN,NaN,false,"unavailable"};continue;
 end
 same=isequal(size(v),size(ref));
 if same&&isnumeric(v)&&isnumeric(ref)
  same=all((isnan(v(:))&isnan(ref(:)))|(v(:)==ref(:))|(isfinite(v(:))&isfinite(ref(:))&abs(v(:)-ref(:))<=1e-8+1e-6*abs(ref(:))));
 elseif same,same=isequaln(v,ref);end
 if isnumeric(v)&&isnumeric(ref)&&isscalar(v)&&isscalar(ref)
  T(end+1,:)={string(C.fileName),string(f),v,ref,v-ref,same,note};
 else
  T(end+1,:)={string(C.fileName),string(f),NaN,NaN,NaN,same,string(sprintf('sizes regenerated=%s reference=%s',mat2str(size(v)),mat2str(size(ref))))};
 end
end
slipFields=["nSlips","slipEventDurations","totalSlipMagnitude"];
stopFields=["nStops","stoppingDurations","meanSpeedLoco"];
sel=ismember(T.Field,slipFields);matches.slip=sum(sel)==numel(slipFields)&&all(T.Match(sel));
sel=ismember(T.Field,stopFields);matches.stop=sum(sel)==numel(stopFields)&&all(T.Match(sel));
end

function E=makeEvents(C)
E=table('Size',[0 24],'VariableTypes',[repmat({'string'},1,7),repmat({'double'},1,14),{'logical','logical','logical'}], ...
 'VariableNames',{'File','Cohort','MouseID','CageID','Group','Type','Stage','Day','TrialNumber','EventNumber', ...
 'StartTraversalFrame','EndTraversalFrame','DurationFrames','MidpointTraversalFrame','SampledMidpointTraversalFrame', ...
 'StartOriginalFrame','EndOriginalFrame','MidpointOriginalFrame','SampledMidpointOriginalFrame','CentroidX','XEntryRightFraction', ...
 'PositionFinite','AlgorithmValidated','ReferenceSummaryMatched'});
for type=["slip","stop"]
 if type=="slip"
  if ~isfield(C,'slipEventStarts'),continue;end
  starts=C.slipEventStarts(:);ends=starts+C.slipEventDurations(:)-1;
  validated=C.validation.slipValid;matched=C.referenceSummaryMatch.slip;
 else
  starts=C.stoppingStartStops(:,1);ends=C.stoppingStartStops(:,2);
  validated=C.validation.stopValid;matched=C.referenceSummaryMatch.stop;
 end
 for k=1:numel(starts)
  a=starts(k);b=ends(k);mid=(a+b)/2;sample=floor(mid);
  x=NaN;xf=NaN;if sample>=1&&sample<=numel(C.originalFrames),x=C.xOriginal(sample);xf=C.xEntryRightFraction(sample);end
  z=C.identifiers;
  E(end+1,:)={string(z.file),string(z.cohort),string(z.mouseID),string(z.cageID),string(z.group),type,string(C.stage), ...
   z.day,z.trialNumber,k,a,b,b-a+1,mid,sample,C.firstOriginalFrame+a-1,C.firstOriginalFrame+b-1, ...
   C.firstOriginalFrame+mid-1,C.firstOriginalFrame+sample-1,x,xf,isfinite(x),validated,matched};
 end
end
end

function F=makeTrace(C)
n=numel(C.originalFrames);z=C.identifiers;
F=table(repmat(string(z.file),n,1),C.traversalFrames,C.originalFrames,C.timeSeconds,C.mouseCentroids(:,1), ...
 C.mouseCentroids(:,2),C.yOriginal,C.xEntryRightFraction,C.forwardSpeeds(:),logical(C.stoppingFrames(:)), ...
 'VariableNames',{'File','TraversalFrame','OriginalFrame','TimeSeconds','CentroidX','CentroidYBarRelative','CentroidYOriginal','XEntryRightFraction','ForwardSpeed','StopMask'});
fields={'movementTrace','tailMovementTrace','tailMovementTraceAboveBar','tailMovementTraceUnderBar','tailBadFrames','verticalMotionTrace'};
cols={'MovementTrace','TailTotal','TailAboveBar','TailBelowBar','TailBadFrame','ExistingVerticalMotionTrace'};
for k=1:numel(fields)
 if isfield(C,fields{k}),F.(cols{k})=double(C.(fields{k})(:));else,F.(cols{k})=nan(n,1);end
end
fields={'weightedPosition','unweightedPosition','weightedBelowBarFraction','unweightedBelowBarFraction','invalidFramePairMask','weightedTotal','unweightedTotal'};
cols={'MotionHeightWeighted','MotionHeightUnweighted','BelowBarFractionWeighted','BelowBarFractionUnweighted','RowProfileInvalidPair','RowMotionTotalWeighted','RowMotionTotalUnweighted'};
for k=1:numel(fields)
 if isfield(C,'rowMotionIndices'),F.(cols{k})=double(C.rowMotionIndices.(fields{k})(:));else,F.(cols{k})=nan(n,1);end
end
end
