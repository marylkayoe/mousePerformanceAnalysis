function exportUnderbarMotionColumns(name,out)
% Streaming reconstruction of frozen L40 underbar column contributions.
% No tracking rerun. Fresh external output; normalized scalar must validate.
arguments
 name (1,:) char
 out (1,:) char
end
assert(~isfolder(out),'Choose fresh output');mkdir(out);
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';source=fullfile('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved',name);z=load(fullfile(root,'trials',[name '.mat']),'C');C=z.C;
% Fail closed if frozen implementation changes.
assert(strcmp(localHash(fullfile(root,'code_snapshot','getMeanFrame.m')),'7f0e10f42cbbe53a60c02b922c3d8c19002f3293a1d0fa9dc8eba87ebb084cd9'),'Unsupported snapshot: getMeanFrame');
assert(strcmp(localHash(fullfile(root,'code_snapshot','trackMouseOnBeam.m')),'4f718422ff0dee28a1d7ce32ab055fa4de5c9110d29ecbdabc9f9aff143f660e'),'Unsupported snapshot: trackMouseOnBeam');
assert(strcmp(localHash(fullfile(root,'code_snapshot','computeMouseProbabilityMatrix.m')),'316c05dddf4bd08c3e8fd53fe04140f4e49cdfb6e6279089f4b28e318a0e1a27'),'Unsupported snapshot: computeMouseProbabilityMatrix');
assert(strcmp(localHash(fullfile(root,'code_snapshot','detectSlips.m')),'6eb000c56b1af9256ca4b5262a782263b94d46a54344b80085a272f333c09835'),'Unsupported snapshot: detectSlips');
assert(strcmp(localHash(fullfile(root,'code_snapshot','computeWeightedMovementTrace.m')),'5ad283c60acd9e54f4296f47246bc23a313d6504091e510713eaa5036405d800'),'Unsupported snapshot: computeWeightedMovementTrace');
assert(strcmp(localHash(fullfile(root,'code_snapshot','capturedTaraBeam.m')),'9f36f370a840b57c8330cd42b371a09a26104ff9bd59e16d0ebe8754e65aa8b7'),'Unsupported snapshot: capturedTaraBeam');
assert(C.parameters.LOCOTHRESHOLD==40&&C.parameters.SLIPTHRESHOLD==2.5&&C.parameters.MOUSESIZETHRESHOLD==2);assert(all(diff(C.originalFrames)==1));
rows=C.cropRange(1):C.cropRange(2);h=numel(rows);w=C.decodedVideoSize(2);n=numel(C.originalFrames);v=VideoReader(source);acc=zeros(h,w);count=0;
while hasFrame(v)
 g=readFrame(v);if size(g,3)==3,g=rgb2gray(g);end
 acc=acc+double(g(rows,:));count=count+1;
end
assert(count==C.decodedVideoSize(3));bg=uint8(acc/count);den=im2double(bg)+eps;
a=max(1,min(h,round(C.barTopCoordAnalysis+C.barThickness/2)+3));b=max(a,min(h,round(C.barTopCoordAnalysis+C.barThickness*1.5)+3));
d=(0:b-a)'/(b-a);weights=1./(1+exp(-20*(d-.2)));weights=weights/max(weights);
columns=zeros(n,w);probs=zeros(n,w);v=VideoReader(source);k=0;prev=[];
for f=1:C.originalFrames(end)
 g=readFrame(v);if f<C.originalFrames(1),continue;end
 if size(g,3)==3,g=rgb2gray(g);end
 k=k+1;assert(f==C.originalFrames(k));enh=(im2double(g(rows,:))+eps)./den;prob=sum(enh<.6,1)/h;probs(k,:)=prob;
 if k>1,columns(k,:)=(weights'*abs(enh(a:b,:)-prev)).*prob.^2;end
 prev=enh(a:b,:);
end
assert(k==n);raw=sum(columns,2);speed=C.forwardSpeeds(:);logs=log1p(speed);logs(logs<0)=eps;adjusted=raw.*(160./logs);
% Frozen rerun retains stops; match nonfinite propagation, smoothing and clamp.
sm=smooth(adjusted,10);stop=logical(C.stoppingFrames(:));finite=isfinite(sm);baseline=sm(finite&~stop);med=median(baseline);sig=1.4826*median(abs(baseline-med));tol=1e-12*max(1,max(abs(sm(finite)),[],'omitnan'));
if isempty(baseline)||~isfinite(sig)||sig<=tol,baseline=sm(finite);med=median(baseline);sig=1.4826*median(abs(baseline-med));end
assert(~isempty(baseline)&&isfinite(sig)&&sig>tol);pred=(sm-med)/sig;pred(pred<0)=0;pred(isnan(pred))=0;ref=C.movementTrace(:);match=(isnan(pred)&isnan(ref))|(pred==ref)|(isfinite(pred)&isfinite(ref)&abs(pred-ref)<=1e-6+1e-6*abs(ref));
validation=struct('allFramesMatch',all(match),'maxAbsoluteError',max(abs(pred(isfinite(pred)&isfinite(ref))-ref(isfinite(pred)&isfinite(ref)))),'frames',n,'firstOriginalFrame',C.originalFrames(1),'lastOriginalFrame',C.originalFrames(end),'absoluteTolerance',1e-6,'relativeTolerance',1e-6);
fid=fopen(fullfile(out,'validation.json'),'w');fwrite(fid,jsonencode(validation));fclose(fid);assert(all(match),'Scalar reconstruction failed; refusing movie inputs');
writematrix(columns,fullfile(out,'raw_columns.csv'));writematrix(probs,fullfile(out,'mouse_column_probability.csv'));
trace=readtable(fullfile(root,'trials',[name '.trace.csv']));assert(isequal(trace.OriginalFrame,C.originalFrames(:)));F=table((1:n)',C.originalFrames(:),C.timeSeconds(:),raw,adjusted,sm,pred,ref,trace.CentroidX,trace.CentroidYOriginal,stop,~isfinite(raw)|~isfinite(adjusted),'VariableNames',{'TraversalFrame','OriginalFrame','EncodedTimeSeconds','RawSum','SpeedAdjusted','Smoothed','ReconstructedMovementTrace','SavedMovementTrace','CentroidX','CentroidYOriginal','StopMask','NumericalInvalid'});F.NoPreviousFrame=false(n,1);F.NoPreviousFrame(1)=true;writetable(F,fullfile(out,'frame_mapping.csv'));
meta=struct('file',name,'sourceVideo',source,'width',w,'height',C.decodedVideoSize(1),'nFrames',n,'originalFrameRate',C.videoReaderFrameRate,'analysisFrameRate',C.analysisFrameRate,'playbackFrameRate',30,'underbarFirstOriginalRow',rows(a),'underbarLastOriginalRow',rows(b),'barTopOriginal',C.barTopCoordOriginal,'barThickness',C.barThickness,'parameters',C.parameters,'rawColumnMaximum',max(columns(:)),'definition','sum rows(abs(diff(background-ratio-image))*sigmoidDistanceWeight) * destinationMouseProbability^2; no per-column speed scaling, temporal smoothing or MAD normalization');
fid=fopen(fullfile(out,'metadata.json'),'w');fwrite(fid,jsonencode(meta));fclose(fid);save(fullfile(out,'columns.mat'),'columns','probs','weights','meta','validation','-v7');disp(validation);
end

function h=localHash(path)
fid=fopen(path,'r');assert(fid>=0);c=onCleanup(@()fclose(fid));bytes=fread(fid,Inf,'*uint8');md=java.security.MessageDigest.getInstance('SHA-256');md.update(typecast(bytes,'int8'));h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
