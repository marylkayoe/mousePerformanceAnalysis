function [D,provenance]=tailCropGeometry(C,source,snapshot,savedFile,force)
% Reproduce only mask probabilities and post-mouse crop construction.
% Centroids, direction and traversal are reused; tracking is not repeated.
provenance=struct('savedWeightsFile',savedFile,'savedWeightsAvailable',isfile(savedFile), ...
 'mode','saved','savedComparison','not_available','snapshot',snapshot);
saved=[];
if isfile(savedFile)
 z=load(savedFile,'D');saved=z.D;
 assert(strcmp(saved.file,C.fileName)&&isequal(saved.originalFrames(:),C.originalFrames(:)),'Saved geometry belongs to another trial/traversal.');
 assert(isequal(saved.badFrames(:),C.tailBadFrames(:)),'Saved geometry mask differs.');
 assert(saved.height==C.decodedVideoSize(1)&&saved.barTop==C.barTopCoordOriginal&&saved.barWidth==C.barThickness,'Saved geometry dimensions differ.');
 if ~force,D=saved;return;end
end
provenance.mode='reconstructed_from_source_masks_and_saved_centroids';
% Fail closed if the frozen implementation differs from the supported rerun.
names={'getMeanFrame','trackMouseOnBeam','computeMouseProbabilityMatrix','getTailMotionMetrics','readBBVideoIntoMatrix','capturedTaraBeam'};
hashes={'7f0e10f42cbbe53a60c02b922c3d8c19002f3293a1d0fa9dc8eba87ebb084cd9', ...
 '4f718422ff0dee28a1d7ce32ab055fa4de5c9110d29ecbdabc9f9aff143f660e', ...
 '316c05dddf4bd08c3e8fd53fe04140f4e49cdfb6e6279089f4b28e318a0e1a27', ...
 'd209f85dbf612e32f49fd9a3963cac6a2d07aa99bfd347983e9fc9ed7133a6b7', ...
 'fcf880664a4bc32f9f4e02fb82b33ab9695eb8a7b06e855961e63f9e01a1da48', ...
 '9f36f370a840b57c8330cd42b371a09a26104ff9bd59e16d0ebe8754e65aa8b7'};
for j=1:numel(names)
 path=fullfile(snapshot,[names{j} '.m']);assert(isfile(path),'Missing frozen code: %s',path);
 assert(strcmp(hashFile(path),hashes{j}),'Unsupported frozen implementation: %s',path);
end
provenance.frozenFunctions=names;provenance.frozenSHA256=hashes;
provenance.maskContrastThreshold=.6;provenance.morphologicalCleanup=false;
provenance.noMouseProbabilityCutoff=.85;provenance.badColumnFractionThreshold=.1;
assert(numel(C.cropRange)==2&&all(isfinite(C.cropRange)));
rows=C.cropRange(1):C.cropRange(2);imWidth=C.decodedVideoSize(2);n=numel(C.originalFrames);
% Frozen getMeanFrame uses uint8(mean(all original frames in beam crop,3)).
% Integer sums here are exact in double; only one source frame resides in memory.
[v,isColor]=reader(source);sumFrame=zeros(numel(rows),imWidth);count=0;
while hasFrame(v)
 frame=grayFrame(readFrame(v),isColor);assert(isequal(size(frame),C.decodedVideoSize(1:2)),'Decoded source geometry changed.');
 sumFrame=sumFrame+double(frame(rows,:));count=count+1;
end
assert(count==C.decodedVideoSize(3),'Decoded frame count differs from frozen rerun.');
meanFrame=uint8(sumFrame/count);denominator=im2double(meanFrame)+eps;
provenance.backgroundFrameCount=count;
[v,isColor]=reader(source);prob=zeros(imWidth,n);k=0;
for original=1:C.originalFrames(end)
 frame=grayFrame(readFrame(v),isColor);
 if original<C.originalFrames(1),continue;end
 k=k+1;assert(original==C.originalFrames(k));
 mask=(im2double(frame(rows,:))+eps)./denominator < .6;
 prob(:,k)=sum(mask,1)'/numel(rows);
end
assert(k==n);
% Exactly preserve the frozen tail function's interpolation and crop policy.
x=C.mouseCentroids(:,1);originalMissing=~isfinite(x);
if any(isnan(C.mouseCentroids(:)))
 x(~isfinite(x))=NaN;
 x=fillmissing(x,'linear','MaxGap',11,'EndValues','none');x=round(x);
end
x=round(x);
assert(all(isfinite(x)),'Unresolved crop coordinates after original interpolation policy; refusing invented pixels.');
mouseLength=median(sum(prob>0,1),'omitnan');offsets=0:mouseLength+mouseLength*.25;
rawCols=x+(2*C.mouseEntersFromRight-1)*offsets;
badMask=rawCols<1|rawCols>imWidth;cols=min(max(rawCols,1),imWidth);
bad=mean(badMask,2)>.1;assert(isequal(bad,C.tailBadFrames(:)),'Reconstructed tail bad mask differs.');
np=zeros(n,numel(offsets));
for k=1:n,np(k,:)=1-prob(cols(k,:),k)';end
np(np<.85)=0;
D=struct('file',C.fileName,'height',C.decodedVideoSize(1),'width',numel(offsets),'nFrames',n, ...
 'originalFrames',C.originalFrames(:),'encodedTimes',C.timeSeconds(:), ...
 'barTop',C.barTopCoordOriginal,'barWidth',C.barThickness,'columns',cols, ...
 'noMouseProbability',np,'columnWeightSquared',np.^2,'badFrames',bad,'previousBadFrames',[true;bad(1:end-1)]);
provenance.mousePixelLength=mouseLength;provenance.originalMissingXFrames=sum(originalMissing);
provenance.interpolatedXFrames=sum(originalMissing&isfinite(x));
if ~isempty(saved)
 assert(isequal(D.columns,saved.columns),'Reconstructed columns differ from saved example.');
 assert(isequal(D.noMouseProbability,saved.noMouseProbability),'Reconstructed probabilities differ from saved example.');
 assert(isequal(D.columnWeightSquared,saved.columnWeightSquared),'Reconstructed squared weights differ.');
 provenance.savedComparison='exact columns, probabilities, squared weights and masks';
 if isfield(saved,'aboveContrib'),D.aboveContrib=saved.aboveContrib;end
end
end
function [v,isColor]=reader(source)
v=VideoReader(source);first=readFrame(v);isColor=size(first,3)==3;v.CurrentTime=0;
end
function g=grayFrame(frame,isColor)
if isColor,g=rgb2gray(frame);else,g=frame;end
end
function h=hashFile(path)
fid=fopen(path,'r');assert(fid>=0);clean=onCleanup(@()fclose(fid));bytes=fread(fid,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256');md.update(typecast(bytes,'int8'));
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
