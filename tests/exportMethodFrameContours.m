function exportMethodFrameContours
repo=fileparts(fileparts(mfilename('fullpath')));out=fullfile(repo,'BEAMCROSS','DRAFTFIGS','figMaterials');
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4';
z=load(fullfile(root,'trials',[name '.checkpoint.mat']),'C');C=z.C;
z=load(fullfile(root,'trials',[name '.profiles.mat']),'P');P=z.P;
k=514;assert(C.originalFrames(k)==1369);h=C.decodedVideoSize(1);w=C.decodedVideoSize(2);rr=C.cropRange(1):C.cropRange(2);
v=VideoReader(C.sourcePath);total=zeros(numel(rr),w);count=0;
while hasFrame(v),g=readFrame(v);if size(g,3)==3,g=rgb2gray(g);end;total=total+double(g(rr,:));count=count+1;end
assert(count==C.decodedVideoSize(3));meanFrame=uint8(total/count);den=im2double(meanFrame)+eps;
v.CurrentTime=0;n=numel(C.originalFrames);lengths=zeros(n,1);j=0;
for original=1:C.originalFrames(end)
 g=readFrame(v);if size(g,3)==3,g=rgb2gray(g);end
 if original<C.originalFrames(1),continue;end
 j=j+1;mask=(im2double(g(rr,:))+eps)./den<.6;prob=sum(mask,1)/numel(rr);lengths(j)=sum(prob>0);
 if j==k,p=prob;target=g;targetMask=mask;end
 if j==k-1,previous=g;end
end
mouseLength=median(lengths);offsets=0:mouseLength*1.25;
x=round(C.mouseCentroids(:,1));cols=x(k)+(2*C.mouseEntersFromRight-1)*offsets;prevCols=x(k-1)+(2*C.mouseEntersFromRight-1)*offsets;
assert(all(cols>=1 & cols<=w)&&all(prevCols>=1 & prevCols<=w));np=1-p(cols);np(np<.85)=0;
delta=abs(im2double(target(:,cols))-im2double(previous(:,prevCols)));
row=sum(delta.*np.^2,2);saved=double(P.probabilityWeighted(:,k));err=max(abs(row-saved));assert(all(abs(row-saved)<=1e-6+1e-6*abs(saved)),'Row profile reconstruction mismatch');
props=regionprops(targetMask,'Area','Centroid');[~,ix]=max([props.Area]);xy=props(ix).Centroid;xy(2)=xy(2)+rr(1)-1;
yOriginal=numel(rr)+1-C.barTopCoordAnalysis-C.mouseCentroids(k,2)+rr(1)-1;
assert(max(abs(xy-[C.mouseCentroids(k,1),yOriginal]))<1e-8);
a=round(C.barTopCoordAnalysis+C.barThickness/2)+3;b=round(C.barTopCoordAnalysis+C.barThickness*1.5)+3;
a=max(1,min(numel(rr),a));b=max(a,min(numel(rr),b));sr=rr(a:b);
rw=1./(1+exp(-20*((0:numel(sr)-1)'/(numel(sr)-1)-.2)));rw=rw/max(rw);
S=zeros(h,w);S(sr,:)=rw.*p.^2;
T=zeros(h,w);above=1:C.barTopCoordOriginal;below=C.barTopCoordOriginal+C.barThickness:h;
aw=((0:numel(above)-1)'/(numel(above)-1)+eps).^3;aw=aw/max(aw);
bw=1+min(2*(0:numel(below)-1)'/(numel(below)-1),1);
T(above,cols)=aw.*np.^2;T(below,cols)=bw.*np.^2;
D=struct('originalFrame',1369,'traversalFrame',k,'mouseProbability',p,'tailNoMouseProbability',np,'tailColumns',cols,'slipRows',sr,'barTop',C.barTopCoordOriginal,'barThickness',C.barThickness,'centroidOriginal',xy,'rowProfileMaxError',err,'tailBadFrame',C.tailBadFrames(k),'slipPeakWeight',max(S(:)),'tailPeakWeight',max(T(:)),'contourLevels',[.25 .5 .75],'slipContours',{paths(S/max(S(:)))},'tailContours',{paths(T/max(T(:)))});
fid=fopen(fullfile(out,'TMCS2_S18_D0_T2_f514_weights.json'),'w');fwrite(fid,jsonencode(D));fclose(fid);
fprintf('Validated row profile error %.9g, centroid exact; slip rows %d:%d tail columns %d:%d\n',err,sr(1),sr(end),cols(1),cols(end));
end
function result=paths(Z)
% Padded zero field closes contours at the actual crop boundaries.
z=zeros(size(Z)+2);z(2:end-1,2:end-1)=Z;
c=contourc(0:size(Z,2)+1,0:size(Z,1)+1,z,[.25 .5 .75]);i=1;result={};
while i<size(c,2),n=c(2,i);result{end+1}=struct('level',c(1,i),'xy',c(:,i+1:i+n)');i=i+n+1;end
end
