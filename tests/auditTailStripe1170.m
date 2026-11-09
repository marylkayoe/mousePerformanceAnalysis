function auditTailStripe1170
% Read-only audit of source/results; new artifacts in a separate audit folder.
out='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_stripe_audit_S09_f1170_20261109';
name='TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4';
root='/Volumes/ShosaiData/DATA/Tara/RESULTS';
example=fullfile(root,'balance_beam_tail_examples_L40_20261109',name);
source=fullfile('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved',name);
z=load(fullfile(example,'weights_and_mapping.mat'));D=z.D;
z=load(fullfile(root,'balance_beam_events_traces_L40_20261106','trials',[name '.profiles.mat']));P=z.P;
z=load(fullfile(root,'balance_beam_events_traces_L40_20261106','trials',[name '.mat']));C=z.C;
k=find(C.originalFrames==1170);assert(k==512&&C.originalFrames(k-1)==1169);
v=VideoReader(source);first=readFrame(v);isColor=size(first,3)==3;v.CurrentTime=0;
G=cell(2,1);crops=cell(2,1);metrics=struct;
for f=1:1170
 frame=readFrame(v);
 if f>=1169
  q=f-1168;imwrite(frame,fullfile(out,sprintf('source_matlab_rgb_f%d.png',f)));
  if isColor,gray=rgb2gray(frame);else,gray=frame;end
  G{q}=gray;imwrite(gray,fullfile(out,sprintf('source_matlab_gray_f%d.png',f)));
  crops{q}=gray(:,D.columns(k-2+q,:));
  imwrite(crops{q},fullfile(out,sprintf('recrop_matlab_f%d.png',f)));
 end
end
lossless={imread(fullfile(example,'crop_f1170_previous.png')),imread(fullfile(example,'crop_f1170.png'))};
metrics.sourceRecropMatchesLossless=[isequal(crops{1},lossless{1}),isequal(crops{2},lossless{2})];
assert(all(metrics.sourceRecropMatchesLossless));
delta=abs(double(lossless{2})-double(lossless{1}))/255;
U=sum(delta,2);Q=sum(delta.*D.columnWeightSquared(k,:),2);
metrics.unweightedProfileMaxError=max(abs(U-double(P.unweighted(:,k))));
metrics.weightedProfileMaxError=max(abs(Q-double(P.probabilityWeighted(:,k))));
metrics.profileMatches=all(abs(Q-double(P.probabilityWeighted(:,k)))<=1e-6+1e-6*abs(Q));
assert(metrics.profileMatches);
metrics.tailBadFrames=C.tailBadFrames(k-1:k);metrics.invalidPairs=P.invalidFramePairMask(k-1:k);
metrics.originalFrames=C.originalFrames(k-1:k);metrics.debugFrames=[k-1;k];
metrics.savedTailTotal=C.tailMovementTrace(k-1:k);metrics.savedTailAbove=C.tailMovementTraceAboveBar(k-1:k);
metrics.savedTailBelow=C.tailMovementTraceUnderBar(k-1:k);
metrics.heightFromCleanPair=sum(Q.*P.rowHeightRelativeToBar)/sum(Q);
metrics.savedWeightedHeight=P.weightedPosition(k);
metrics.heightDifference=metrics.heightFromCleanPair-metrics.savedWeightedHeight;
metrics.savedUnweightedHeight=P.unweightedPosition(k);
metrics.unweightedHeightFromCleanPair=sum(U.*P.rowHeightRelativeToBar)/sum(U);
metrics.aboveRawFromCleanPair=sum(Q.*D.aboveRowWeight);
metrics.belowRawFromCleanPair=sum(Q.*D.belowRowWeight);
metrics.aboveRawFromSavedDebug=sum(D.aboveContrib(k,:));
metrics.belowRawFromSavedDebug=sum(D.belowContrib(k,:));
% Reconstruct entire original scalar traces from saved profiles for this trial.
regions={1:D.height,1:D.barTop,D.barTop+D.barWidth:D.height};
targets={C.tailMovementTrace,C.tailMovementTraceAboveBar,C.tailMovementTraceUnderBar};
metrics.traceReconstructionMatch=false(1,3);
for r=1:3
 rr=regions{r};d=(0:numel(rr)-1)'/(numel(rr)-1);m=1;if r==3,m=.5;end
 w=(min(d/m,1)+eps).^3;w=w/max(w);
 raw=sum(double(P.probabilityWeighted(rr,:)).*w,1)';raw(1)=0;s=smooth(raw,5);
 med=median(s,'omitnan');sigma=1.4826*median(abs(s-med),'omitnan');pred=(s-med)/sigma;
 pred(isnan(pred))=0;pred(C.tailBadFrames)=NaN;a=targets{r}(:);
 metrics.traceReconstructionMatch(r)=all((isnan(a)&isnan(pred))|(a==pred)|abs(a-pred)<=1e-6+1e-6*abs(a));
end
% Independent decoder of the existing crop movie.
v=VideoReader(fullfile(example,'post_mouse_crop.mp4'));
for j=1:k
 frame=readFrame(v);
 if j>=k-1,imwrite(frame,fullfile(out,sprintf('crop_movie_matlab_f%d.png',C.originalFrames(j))));end
end
% Minimal writer probes: same clean pixels, vary grayscale/RGB/width alignment.
for variant={'gray234','rgb234','gray240'}
 label=variant{1};w=VideoWriter(fullfile(out,['writer_probe_' label '.mp4']),'MPEG-4');
 w.FrameRate=30;w.Quality=100;open(w);
 for q=1:2
  img=lossless{q};
  if strcmp(label,'rgb234'),img=repmat(img,1,1,3);end
  if strcmp(label,'gray240'),img(:,end+1:240)=repmat(img(:,end),1,240-size(img,2));end
  writeVideo(w,img);
 end
 close(w);
end
fid=fopen(fullfile(out,'measurement_audit.json'),'w');fwrite(fid,jsonencode(metrics));fclose(fid);
copyfile([mfilename('fullpath') '.m'],out);
disp(metrics);
end
