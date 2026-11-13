function reweightTaraWholeTailProfiles
% Reweight compressed row profiles; never decode video or rerun tracking.
src='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
out='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110';
assert(~isfolder(out),'Choose a fresh output directory; refusing overwrite.');
mkdir(out);mkdir(fullfile(out,'trials'));mkdir(fullfile(out,'code'));
diary(fullfile(out,'run.log'));cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
copyfile([mfilename('fullpath') '.m'],fullfile(out,'code'));
manifest=readtable(fullfile(src,'trial_manifest.csv'),'TextType','string');
rows=struct([]);
for j=1:height(manifest)
 file=char(manifest.File(j));base=fullfile(src,'trials',file);
 row=struct('File',string(file),'Group',manifest.Group(j),'MouseID',manifest.MouseID(j), ...
 'CageID',manifest.CageID(j),'Day',manifest.Day(j),'Status',"failed",'Error',"", ...
 'Frames',NaN,'OldTotalMatch',false,'OldAboveMatch',false,'OldBelowMatch',false, ...
 'OldTotalMaxError',NaN,'OldAboveMaxError',NaN,'OldBelowMaxError',NaN, ...
 'TailBadFrames',NaN,'InvalidPairs',NaN,'NewScale',NaN,'NewNonfinite',NaN, ...
 'OldRawMeanValidPair',NaN,'NewRawMeanValidPair',NaN,'OldNormalizedMean',NaN,'NewNormalizedMean',NaN);
 try
  z=load([base '.mat'],'C');C=z.C;z=load([base '.profiles.mat'],'P');P=z.P;clear z
  Q=double(P.probabilityWeighted);[h,n]=size(Q);bad=C.tailBadFrames(:);
  assert(isequal(size(Q),[C.decodedVideoSize(1),numel(C.originalFrames)]));
  assert(isequal(P.originalFrames,C.originalFrames)&&isequal(P.timeSeconds,C.timeSeconds));
  assert(isequal(P.tailBadFrames,bad)&&isequal(P.rowNumbersOriginalVideo(:),(1:h)'));
  assert(P.barTopOriginal==C.barTopCoordOriginal && P.barWidth==C.barThickness);
  assert(all(isnan(Q(:,1)))&&all(diff(C.originalFrames)==1));
  regions={1:h,1:P.barTopOriginal,P.barTopOriginal+P.barWidth:h};
  targets={C.tailMovementTrace,C.tailMovementTraceAboveBar,C.tailMovementTraceUnderBar};
  match=false(1,3);err=nan(1,3);oldRaw=cell(1,3);oldRebuilt=cell(1,3);oldWeights=cell(1,3);
  for r=1:3
   rr=regions{r};v=(0:numel(rr)-1)'/(numel(rr)-1);maxAt=1;if r==3,maxAt=.5;end
   w=(min(v/maxAt,1)+eps).^3;w=w/max(w);oldWeights{r}=w;
   raw=sum(Q(rr,:).*w,1)';raw(1)=0;oldRaw{r}=raw;
   [~,pred]=normalizeLegacy(raw,bad);oldRebuilt{r}=pred;actual=targets{r}(:);
   finite=isfinite(pred)&isfinite(actual);
   sameNonfinite=(isnan(pred)&isnan(actual))|(isinf(pred)&pred==actual);
   match(r)=all(sameNonfinite|(finite&abs(pred-actual)<=1e-6+1e-6*abs(actual)));
   if any(finite),err(r)=max(abs(pred(finite)-actual(finite)));end
  end
  below=regions{3};depth=(0:numel(below)-1)'/(numel(below)-1);
  belowW=1+min(2*depth,1);
  newW=ones(h,1);newW(regions{2})=oldWeights{2};newW(below)=belowW;
  assert(newW(P.barTopOriginal)==1&&newW(below(1))==1&&newW(end)==2);
  assert(all(diff(newW)>=0)&&all(newW(below(depth>=.5))==2));
  newRaw=sum(Q.*newW,1)';newRaw(1)=0;
  % Independently decompose into above, beam-interior, corrected-below parts.
  beam=P.barTopOriginal+1:below(1)-1;
  parts=oldRaw{2}+sum(Q(beam,:),1)'+sum(Q(below,:).*belowW,1)';parts(1)=0;
  assert(all(abs(parts-newRaw)<=1e-8+1e-8*abs(newRaw)|isnan(parts)&isnan(newRaw)));
  [smoothed,newTrace,normalization]=normalizeLegacy(newRaw,bad);
  R=struct('fileName',file,'identifiers',C.identifiers,'sourceProfile',[base '.profiles.mat'], ...
   'sourceTrial',[base '.mat'],'parameters',C.parameters,'originalFrames',C.originalFrames, ...
   'timeSeconds',C.timeSeconds,'videoReaderFrameRate',C.videoReaderFrameRate, ...
   'encodedFrameRate',C.encodedFrameRate,'analysisFrameRate',C.analysisFrameRate, ...
   'barTopOriginal',P.barTopOriginal,'barWidth',P.barWidth,'rowNumbersOriginalVideo',P.rowNumbersOriginalVideo, ...
   'tailBadFrames',bad,'invalidFramePairMask',P.invalidFramePairMask, ...
   'belowRowNumbers',below(:),'oldWholeRowWeights',oldWeights{1},'newWholeRowWeights',newW,'newBelowRowWeights',belowW, ...
   'originalTotalTrace',C.tailMovementTrace,'originalAboveTrace',C.tailMovementTraceAboveBar, ...
   'originalBelowTrace',C.tailMovementTraceUnderBar,'reconstructedOriginalTraces',{oldRebuilt}, ...
   'oldWholeRaw',oldRaw{1},'newWholeRaw',newRaw,'newWholeSmoothed',smoothed, ...
   'newWholeTrace',newTrace,'normalization',normalization, ...
   'reconstructionMatch',match,'reconstructionMaxAbsoluteError',err, ...
   'absoluteTolerance',1e-6,'relativeTolerance',1e-6);
  R.weightDefinition='Whole range: original above-bar cubic ramp reaches 1 at bar top; beam-interior rows weight 1; below-bar w=1+min(2*d,1), d=(row-firstBelowRow)/(lastRow-firstBelowRow). First below-bar row is barTop+barWidth. Destination-frame no-mouse-probability-squared weights already in Q. Original total and separate above/below traces preserved.';
  R.firstFrameDefinition='Raw first frame is 0 to reproduce legacy convention, not observed no-motion; invalidFramePairMask remains true.';
  R.maskDefinition='Legacy normalization uses all raw samples before applying original tail bad mask. Separate invalid-pair mask is preserved, not newly applied to legacy-compatible trace.';
  F=table((1:n)',C.originalFrames(:),C.timeSeconds(:),bad,P.invalidFramePairMask(:), ...
   oldRaw{1},newRaw,smoothed,C.tailMovementTrace(:),newTrace,C.tailMovementTraceAboveBar(:), ...
   C.tailMovementTraceUnderBar(:),normalization.beforeNaNReplacement, ...
   'VariableNames',{'TraversalFrame','OriginalFrame','EncodedTimeSeconds','TailBadFrame','InvalidFramePair', ...
   'OldWholeRaw','NewWholeRaw','NewWholeSmoothed','OldWholeNormalized','NewWholeNormalized', ...
   'UnchangedAboveNormalized','UnchangedBelowNormalized','NewNormalizedBeforeLegacyNaNReplacement'});
  row.Frames=n;row.OldTotalMatch=match(1);row.OldAboveMatch=match(2);row.OldBelowMatch=match(3);
  row.OldTotalMaxError=err(1);row.OldAboveMaxError=err(2);row.OldBelowMaxError=err(3);
  row.TailBadFrames=sum(bad);row.InvalidPairs=sum(P.invalidFramePairMask);
  row.NewScale=normalization.scale;row.NewNonfinite=sum(~isfinite(newTrace));
  valid=~P.invalidFramePairMask(:);row.OldRawMeanValidPair=mean(oldRaw{1}(valid),'omitnan');
  row.NewRawMeanValidPair=mean(newRaw(valid),'omitnan');
  row.OldNormalizedMean=mean(C.tailMovementTrace,'omitnan');row.NewNormalizedMean=mean(newTrace,'omitnan');
  row.Status="complete";
  if ~all(match),row.Status="reconstruction_mismatch";end
  if ~isfinite(normalization.scale)||normalization.scale<=0,row.Status="normalization_failure";end
  R.status=row.Status;
  save(fullfile(out,'trials',[file '.mat']),'R','-v7');
  writetable(F,fullfile(out,'trials',[file '.csv']));
 catch e
  row.Error=string(getReport(e,'extended','hyperlinks','off'));
 end
 rows=[rows;row]; %#ok<AGROW>
 if mod(j,25)==0||j==height(manifest)
  writetable(struct2table(rows),fullfile(out,'comparison_by_file.csv'));
  fprintf('REWEIGHT %d/%d; last=%s\n',j,height(manifest),row.Status);
 end
 clear Q C P R F
end
environment=struct('MATLAB',version,'smoothFunction',which('smooth'),'sourceRoot',src,'outputRoot',out);
fid=fopen(fullfile(out,'environment.json'),'w');fwrite(fid,jsonencode(environment));fclose(fid);
end

function [smoothed,trace,N]=normalizeLegacy(raw,bad)
smoothed=smooth(raw,5);med=median(smoothed,'omitnan');scale=1.4826*median(abs(smoothed-med),'omitnan');
trace=(smoothed-med)/scale;
N=struct('median',med,'scale',scale,'beforeNaNReplacement',trace,'replacedNaNMask',isnan(trace));
trace(isnan(trace))=0;trace(bad)=NaN;
end
