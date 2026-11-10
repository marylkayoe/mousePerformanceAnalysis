function info = prepareTailMetricsTrial(name,out,opts)
%PREPARETAILMETRICSTRIAL Validated crop/column inputs for any retained Tara trial.
% Source/rerun data read in place. New out folder required. No tracking rerun.
% Missing probability weights are reconstructed from frozen mask/mean rules,
% saved centroids and traversal. Reconstruction is never assumed equivalent.
arguments
 name (1,:) char
 out (1,:) char
 opts.SourceRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved'
 opts.RerunRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106'
 opts.CorrectedRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109'
 opts.ExampleRoot (1,:) char = '/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_examples_L40_20261109'
 opts.ReconstructWeights (1,1) logical = false
end
[~,stem,ext]=fileparts(name);assert(strcmp(name,[stem ext])&&strcmpi(ext,'.mp4'),'Supply an original filename, not a path.');
assert(~isfolder(out)&&~isfile(out),'Output exists; choose a new folder.');mkdir(out);
diary(fullfile(out,'run.log'));cleanDiary=onCleanup(@()diary('off')); %#ok<NASGU>
writeJSON(fullfile(out,'preparation_status.json'),struct('status','started','fileName',name));
try
 info=prepare(name,out,opts);
catch e
 writeJSON(fullfile(out,'preparation_status.json'),struct('status','failed','fileName',name,'error',getReport(e,'extended','hyperlinks','off')));
 rethrow(e);
end
end
function info=prepare(name,out,opts)
source=fullfile(opts.SourceRoot,name);example=fullfile(opts.ExampleRoot,name);
base=fullfile(opts.RerunRoot,'trials',name);corrected=fullfile(opts.CorrectedRoot,'trials',[name '.mat']);
inputs={source,[base '.mat'],[base '.profiles.mat'],corrected};
for j=1:numel(inputs),assert(isfile(inputs{j}),'Missing required input: %s',inputs{j});end
z=load([base '.mat'],'C');C=z.C;z=load([base '.profiles.mat'],'P');P=z.P;
z=load(corrected,'R');R=z.R;clear z
assert(strcmp(C.fileName,name)&&strcmp(P.fileName,name)&&strcmp(R.fileName,name),'Trial identifiers differ.');
assert(strcmp(R.status,'complete')&&all(R.reconstructionMatch),'Corrected reference failed validation.');
assert(isequaln(P.timeSeconds(:),C.timeSeconds(:),R.timeSeconds(:)),'Timestamps differ.');
assert(isequal(P.invalidFramePairMask(:),R.invalidFramePairMask(:)),'Invalid-pair masks differ.');
assert(isequal(P.tailBadFrames(:),C.tailBadFrames(:),R.tailBadFrames(:)),'Tail masks differ.');
assert(isequal(C.parameters,R.parameters),'Reference parameters differ.');
assert(C.parameters.LOCOTHRESHOLD==40&&C.parameters.SLIPTHRESHOLD==2.5&&C.parameters.MOUSESIZETHRESHOLD==2,'Unsupported rerun parameters.');
assert(all(diff(C.originalFrames)==1),'Traversal is not contiguous.');
snapshot=fullfile(opts.RerunRoot,'code_snapshot');
[D,geometry]=tailCropGeometry(C,source,snapshot,fullfile(example,'weights_and_mapping.mat'),opts.ReconstructWeights);
save(fullfile(out,'crop_geometry.mat'),'D','geometry','-v7');
writeJSON(fullfile(out,'input_provenance.json'),struct('inputs',{inputs},'sha256',{cellfun(@fileHash,inputs,'UniformOutput',false)},'geometry',geometry,'parameters',C.parameters));
% Validate original normalized total/above/below traces against saved profiles.
regions={1:D.height,1:D.barTop,D.barTop+D.barWidth:D.height};
targets={C.tailMovementTrace,C.tailMovementTraceAboveBar,C.tailMovementTraceUnderBar};
traceMatch=false(1,3);traceError=nan(1,3);
for r=1:3
 rr=regions{r};d=(0:numel(rr)-1)'/(numel(rr)-1);m=1;if r==3,m=.5;end
 ww=(min(d/m,1)+eps).^3;ww=ww/max(ww);
 raw=sum(double(P.probabilityWeighted(rr,:)).*ww,1)';raw(1)=0;sm=smooth(raw,5);
 med=median(sm,'omitnan');sig=1.4826*median(abs(sm-med),'omitnan');pred=(sm-med)/sig;pred(isnan(pred))=0;pred(C.tailBadFrames)=NaN;
 a=targets{r}(:);finite=isfinite(pred)&isfinite(a);
 traceMatch(r)=all((isnan(a)&isnan(pred))|(a==pred)|(finite&abs(a-pred)<=1e-6+1e-6*abs(a)));
 if any(finite),traceError(r)=max(abs(a(finite)-pred(finite)));end
end
assert(all(traceMatch),'Saved original traces fail profile reconstruction.');
writeJSON(fullfile(out,'original_trace_validation.json'),struct('match',traceMatch,'maxAbsoluteError',traceError,'absoluteTolerance',1e-6,'relativeTolerance',1e-6));
n=D.nFrames;h=D.height;w=D.width;
assert(isequal(D.originalFrames,C.originalFrames(:))&&isequal(D.encodedTimes,C.timeSeconds(:)));
assert(isequal(P.originalFrames,C.originalFrames)&&isequal(R.originalFrames,C.originalFrames));
assert(isequal(D.badFrames,C.tailBadFrames(:))&&isequal(P.tailBadFrames,D.badFrames));
assert(isequal(size(D.columns),[n,w])&&isequal(size(D.columnWeightSquared),[n,w]));
assert(isequal(D.columnWeightSquared,D.noMouseProbability.^2));
above=1:D.barTop;below=D.barTop+D.barWidth:h;
aw=((0:numel(above)-1)'/(numel(above)-1)+eps).^3;aw=aw/max(aw);
bw=1+min(2*(0:numel(below)-1)'/(numel(below)-1),1);
assert(isequal(bw,R.newBelowRowWeights));
% Stream raw grayscale frames directly to FFmpeg; no temporary full video matrix.
args={'/opt/homebrew/bin/ffmpeg','-v','error','-nostdin','-f','rawvideo','-pixel_format','gray', ...
 '-video_size',sprintf('%dx%d',w,h),'-framerate','30','-i','pipe:0', ...
 '-map','0:v:0','-c:v','ffv1','-level','3','-pix_fmt','gray','-threads','2',fullfile(out,'post_mouse_crop_lossless.mkv'), ...
 '-map','0:v:0','-vf','pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0:color=black', ...
 '-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-threads','2',fullfile(out,'post_mouse_crop_clean.mp4')};
builder=java.lang.ProcessBuilder(args);builder.redirectError(java.io.File(fullfile(out,'ffmpeg.log')));
process=builder.start();stream=process.getOutputStream();cleanupStream=onCleanup(@()stream.close()); %#ok<NASGU>
v=VideoReader(source);first=readFrame(v);isColor=size(first,3)==3;v.CurrentTime=0;
A=zeros(n,w);B=zeros(n,w);hashes=cell(n,1);profileError=zeros(n,1);profileMatch=true(n,1);
aboveMatch=true(n,1);aboveError=zeros(n,1);hasAboveReference=isfield(D,'aboveContrib');sampleMatch=true;sampleReferenceCount=0;sampleFrames=C.originalFrames(unique(round(linspace(1,n,5))));
k=0;prev=[];
for original=1:C.originalFrames(end)
 frame=readFrame(v);if original<C.originalFrames(1),continue;end
 k=k+1;assert(original==C.originalFrames(k));
 if isColor,gray=rgb2gray(frame);else,gray=frame;end
 assert(isequal(size(gray),[h,C.decodedVideoSize(2)]));
 crop=gray(:,D.columns(k,:));assert(isequal(size(crop),[h,w]));
 if k>1
  delta=abs(im2double(crop)-im2double(prev));
  A(k,:)=(aw'*delta(above,:)).*D.columnWeightSquared(k,:);
  B(k,:)=(bw'*delta(below,:)).*D.columnWeightSquared(k,:);
  q=sum(delta.*D.columnWeightSquared(k,:),2);saved=double(P.probabilityWeighted(:,k));
  profileError(k)=max(abs(q-saved));profileMatch(k)=all(abs(q-saved)<=1e-6+1e-6*abs(saved));
  if hasAboveReference
   aboveError(k)=max(abs(A(k,:)-D.aboveContrib(k,:)));
   aboveMatch(k)=all(abs(A(k,:)-D.aboveContrib(k,:))<=1e-8+1e-6*abs(D.aboveContrib(k,:)));
  end
 end
 if ismember(original,sampleFrames)
  sampleFile=fullfile(example,sprintf('crop_f%d.png',original));
  if isfile(sampleFile),originalPNG=imread(sampleFile);sampleReferenceCount=sampleReferenceCount+1;sampleMatch=sampleMatch&&isequal(crop,originalPNG);assert(sampleMatch);end
  imwrite(crop,fullfile(out,sprintf('crop_f%d.png',original)));
 end
 % Row-major bytes for FFmpeg and independent decoded-video SHA-256 verification.
 bytes=reshape(crop',[],1);md=java.security.MessageDigest.getInstance('SHA-256');md.update(typecast(bytes,'int8'));
 digest=typecast(md.digest(),'uint8');hashes{k}=lower(reshape(dec2hex(digest,2)',1,[]));
 stream.write(typecast(bytes,'int8'),0,numel(bytes));prev=crop;
 if mod(k,100)==0,fprintf('EXPORTED %d/%d\n',k,n);end
end
assert(k==n);stream.close();exitCode=process.waitFor();assert(exitCode==0,'FFmpeg failed');
newBelowSum=sum(B,2);reference=R.newBelowRaw(:);err=abs(newBelowSum-reference);
match=(isnan(newBelowSum)&isnan(reference))|(newBelowSum==reference)| ...
 (isfinite(newBelowSum)&isfinite(reference)&err<=1e-6+1e-6*abs(reference));
E=struct('fileName',name,'sourceVideo',source,'identifiers',C.identifiers,'parameters',C.parameters, ...
 'aboveContributions',A,'newBelowContributions',B,'matrixOrientation','frame x crop column', ...
 'cropColumnCoordinates',D.columns,'noMouseProbability',D.noMouseProbability,'destinationColumnWeightSquared',D.columnWeightSquared, ...
 'aboveRowNumbers',above(:),'aboveRowWeights',aw,'belowRowNumbers',below(:),'newBelowRowWeights',bw, ...
 'width',w,'height',h,'nFrames',n,'originalFrames',C.originalFrames(:),'timeSeconds',C.timeSeconds(:), ...
 'videoReaderFrameRate',C.videoReaderFrameRate,'encodedFrameRate',C.encodedFrameRate,'analysisFrameRate',C.analysisFrameRate, ...
 'playbackFrameRate',30,'barTopOriginal',D.barTop,'barWidth',D.barWidth, ...
 'tailBadFrames',D.badFrames,'previousTailBadFrames',D.previousBadFrames, ...
 'invalidFramePairMask',P.invalidFramePairMask,'originalTrackingXMissing',P.originalTrackingXMissing, ...
 'newBelowRawReference',reference,'newBelowColumnSum',newBelowSum, ...
 'newBelowMatches',match,'newBelowAbsoluteError',err,'absoluteTolerance',1e-6,'relativeTolerance',1e-6, ...
 'rowProfileMatches',profileMatch,'rowProfileMaxErrors',profileError,'aboveContributionMatches',aboveMatch, ...
 'aboveContributionMaxErrors',aboveError);
E.originalTraceReconstructionMatch=traceMatch;E.originalTraceReconstructionMaxError=traceError;
E.viewingVideoWidth=w+mod(w,2);E.viewingVideoHeight=h+mod(h,2);
E.viewingPaddingDefinition='Viewing H.264 only: pad at right/bottom to even dimensions; no scaling. Lossless crop, contributions and debug renderer retain exact original crop dimensions.';
E.aboveContributionReferenceAvailable=hasAboveReference;
if ~hasAboveReference,E.aboveContributionMatches=[];E.aboveContributionMaxErrors=[];end
E.definition='Contrib(k,x)=sum_r(abs(crop_k-crop_(k-1))/255 * verticalWeight(r)) * croppedNoMouseProbValues(x,k)^2; original 0.85 cutoff retained. Raw, before smoothing/MAD normalization. First row zero is legacy no-predecessor placeholder; bad/invalid rows preserved, not masked.';
save(fullfile(out,'column_contributions.mat'),'E','-v7');
writematrix(A,fullfile(out,'above_contributions_frame_by_column.csv'));
writematrix(B,fullfile(out,'new_below_contributions_frame_by_column.csv'));
writematrix(D.columns,fullfile(out,'source_columns_frame_by_column.csv'));
writematrix(D.columnWeightSquared,fullfile(out,'destination_probability_squared_frame_by_column.csv'));
F=table((1:n)',C.originalFrames(:),C.timeSeconds(:),D.badFrames,D.previousBadFrames,P.invalidFramePairMask(:), ...
 P.originalTrackingXMissing(:),sum(A,2),newBelowSum,reference,err,match,string(hashes), ...
 'VariableNames',{'ExportFrame','OriginalFrame','EncodedTimeSeconds','TailBadFrame','PreviousTailBadFrame', ...
 'InvalidFramePair','OriginalTrackingXMissing','AboveColumnSum','NewBelowColumnSum','NewBelowRawReference', ...
 'NewBelowAbsoluteError','NewBelowMatches','LosslessGrayFrameSHA256'});
writetable(F,fullfile(out,'frame_mapping.csv'));
validation=struct('frames',n,'width',w,'height',h,'firstOriginalFrame',C.originalFrames(1), ...
 'lastOriginalFrame',C.originalFrames(end),'belowMatches',all(match),'belowMaxAbsoluteError',max(err), ...
 'absoluteTolerance',1e-6,'relativeTolerance',1e-6,'rowProfilesMatch',all(profileMatch), ...
 'rowProfileMaxError',max(profileError),'aboveContributionsMatch',all(aboveMatch),'aboveMaxError',max(aboveError), ...
 'losslessSamplePNGsMatch',sampleMatch,'tailBadFrames',sum(D.badFrames),'invalidPairs',sum(P.invalidFramePairMask), ...
 'videoReaderFrameRate',C.videoReaderFrameRate,'encodedFrameRate',C.encodedFrameRate,'analysisFrameRate',C.analysisFrameRate, ...
 'playbackFrameRate',30,'MATLAB',version);
fid=fopen(fullfile(out,'numerical_validation.json'),'w');fwrite(fid,jsonencode(validation));fclose(fid);
copyfile(fullfile(fileparts(mfilename('fullpath')),'prepareTailMetricsTrial.m'),out);
assert(all(match)&&all(profileMatch)&&all(aboveMatch),'Export failed numerical validation; retained for inspection');
validation.abovePerColumnReferenceAvailable=hasAboveReference;
validation.viewingVideoWidth=w+mod(w,2);validation.viewingVideoHeight=h+mod(h,2);
validation.losslessSampleReferenceCount=sampleReferenceCount;
if ~hasAboveReference,validation.aboveContributionsMatch=[];validation.aboveMaxError=[];end
if sampleReferenceCount==0,validation.losslessSamplePNGsMatch=[];end
validation.geometry=geometry;
writeJSON(fullfile(out,'numerical_validation.json'),validation);
assert(all(traceMatch),'Original scalar traces do not reconstruct');
helper=fullfile(fileparts(mfilename('fullpath')),'private','validateTailCropVideo.py');
[status,log]=system(sprintf('python3 %s %s',quote(helper),quote(out)));
assert(status==0,'Decoded-video validation failed: %s',log);
traceValidation=validateTailMetricsPreparation(out,opts.RerunRoot,opts.CorrectedRoot);
writeJSON(fullfile(out,'decoded_contribution_trace_validation.json'),traceValidation);
info=validation; info.outputFolder=out;info.fileName=name;info.status='complete';
writeJSON(fullfile(out,'preparation_status.json'),info);
disp(info);
end

function writeJSON(path,value)
fid=fopen(path,'w');assert(fid>=0);clean=onCleanup(@()fclose(fid));fwrite(fid,jsonencode(value));
end
function h=fileHash(path)
fid=fopen(path,'r');assert(fid>=0);clean=onCleanup(@()fclose(fid));md=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid),bytes=fread(fid,1048576,'*uint8');md.update(typecast(bytes,'int8'));end
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
function s=quote(s)
s=['''' strrep(s,'''','''"''"''') ''''];
end
