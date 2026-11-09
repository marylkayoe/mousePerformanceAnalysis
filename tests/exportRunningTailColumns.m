function exportRunningTailColumns
% Reuse validated crop coordinates and probability weights; no tracking.
root='/Volumes/ShosaiData/DATA/Tara/RESULTS';
out=fullfile(root,'balance_beam_running_column_export_L40_halfdepth_20261109');
assert(~isfolder(out),'Refusing to overwrite an existing export');mkdir(out);
diary(fullfile(out,'run.log'));cleanupDiary=onCleanup(@()diary('off')); %#ok<NASGU>
name='TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4';
source=fullfile('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved',name);
example=fullfile(root,'balance_beam_tail_examples_L40_20261109',name);
base=fullfile(root,'balance_beam_events_traces_L40_20261106','trials',name);
z=load(fullfile(example,'weights_and_mapping.mat'),'D');D=z.D;
z=load([base '.mat'],'C');C=z.C;z=load([base '.profiles.mat'],'P');P=z.P;
z=load(fullfile(root,'balance_beam_tail_reweight_L40_halfdepth_20261109','trials',[name '.mat']),'R');R=z.R;clear z
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
 '-map','0:v:0','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-threads','2',fullfile(out,'post_mouse_crop_clean.mp4')};
builder=java.lang.ProcessBuilder(args);builder.redirectError(java.io.File(fullfile(out,'ffmpeg.log')));
process=builder.start();stream=process.getOutputStream();cleanupStream=onCleanup(@()stream.close()); %#ok<NASGU>
v=VideoReader(source);first=readFrame(v);isColor=size(first,3)==3;v.CurrentTime=0;
A=zeros(n,w);B=zeros(n,w);hashes=cell(n,1);profileError=zeros(n,1);profileMatch=true(n,1);
aboveMatch=true(n,1);aboveError=zeros(n,1);sampleMatch=true;sampleFrames=[854,967,1033,1103,1216];
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
  aboveError(k)=max(abs(A(k,:)-D.aboveContrib(k,:)));
  aboveMatch(k)=all(abs(A(k,:)-D.aboveContrib(k,:))<=1e-8+1e-6*abs(D.aboveContrib(k,:)));
 end
 if ismember(original,sampleFrames)
  originalPNG=imread(fullfile(example,sprintf('crop_f%d.png',original)));
  sampleMatch=sampleMatch&&isequal(crop,originalPNG);assert(sampleMatch);
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
copyfile([mfilename('fullpath') '.m'],out);
assert(all(match)&&all(profileMatch)&&all(aboveMatch),'Export failed numerical validation; retained for inspection');
disp(validation);
end
