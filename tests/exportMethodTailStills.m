function exportMethodTailStills
repo=fileparts(fileparts(mfilename('fullpath')));out=fullfile(repo,'BEAMCROSS','DRAFTFIGS','figMaterials');
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4';
z=load(fullfile(root,'trials',[name '.checkpoint.mat']),'C');C=z.C;
z=load(fullfile(root,'trials',[name '.profiles.mat']),'P');P=z.P;
k=514;targets=[331 784 813];selected=unique([targets-8 targets-1 targets targets+1 targets+8]);capture=cell(numel(C.originalFrames),1);probs=capture;h=C.decodedVideoSize(1);w=C.decodedVideoSize(2);rr=C.cropRange(1):C.cropRange(2);
v=VideoReader(C.sourcePath);total=zeros(numel(rr),w);count=0;
while hasFrame(v),g=readFrame(v);if size(g,3)==3,g=rgb2gray(g);end;total=total+double(g(rr,:));count=count+1;end
assert(count==C.decodedVideoSize(3));meanFrame=uint8(total/count);den=im2double(meanFrame)+eps;
v.CurrentTime=0;n=numel(C.originalFrames);lengths=zeros(n,1);j=0;
for original=1:C.originalFrames(end)
 g=readFrame(v);if size(g,3)==3,g=rgb2gray(g);end
 if original<C.originalFrames(1),continue;end
 j=j+1;mask=(im2double(g(rr,:))+eps)./den<.6;prob=sum(mask,1)/numel(rr);lengths(j)=sum(prob>0);
 if any(selected==j)||any(selected-1==j),capture{j}=g;probs{j}=prob;end
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

folder=fullfile(out,'tail_motion_example_stills');if ~isfolder(folder),mkdir(folder);end
records={};
for k=selected
 cols=x(k)+(2*C.mouseEntersFromRight-1)*offsets;pc=x(k-1)+(2*C.mouseEntersFromRight-1)*offsets;
 assert(all(cols>=1&cols<=w)&&all(pc>=1&pc<=w));np=1-probs{k}(cols);np(np<.85)=0;
 crop=capture{k}(:,cols);prev=capture{k-1}(:,pc);row=sum(abs(im2double(crop)-im2double(prev)).*np.^2,2);saved=double(P.probabilityWeighted(:,k));err=max(abs(row-saved));assert(all(abs(row-saved)<=1e-6+1e-6*abs(saved)));
 file=sprintf('crop_traversal_%04d_original_%04d.png',k,C.originalFrames(k));imwrite(crop,fullfile(folder,file));
 records{end+1}=struct('file',file,'traversalFrame',k,'originalFrame',C.originalFrames(k),'timeSinceTraversalStart',(k-1)/C.analysisFrameRate,'tailBad',C.tailBadFrames(k),'invalidPair',P.invalidFramePairMask(k),'columns',cols,'barTop',C.barTopCoordOriginal,'maxProfileError',err);
end
fid=fopen(fullfile(folder,'crop_validation.json'),'w');fwrite(fid,jsonencode(records));fclose(fid);disp('Saved validated source-decoded crops');
end
