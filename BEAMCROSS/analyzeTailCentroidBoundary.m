function analyzeTailCentroidBoundary(out,files,referenceRoot)
% Exploratory 2-D weight override; reuse retained centroids, never retrack.
root='/Volumes/ShosaiData/DATA/Tara/RESULTS';rerun=fullfile(root,'balance_beam_events_traces_L40_20261106');old=fullfile(root,'balance_beam_whole_tail_no_vertical_weight_20261113');sourceRoot='/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved';
if nargin<2,files=strings(0,1);end;if nargin>=3,old=referenceRoot;end
if ~isfolder(out),mkdir(out);end;diary(fullfile(out,'run.log'));clean=onCleanup(@()diary('off'));
movies=jsondecode(fileread(fullfile(root,'balance_beam_tail_minwidth15_smooth5_20261112/presentations_height_trail_right_20261113/manifest.json')));movieFiles=string({movies.file});
for factor=[2 3],d=fullfile(out,sprintf('factor%d',factor),'traces');if ~isfolder(d),mkdir(d);end,end
stems=["D0_first","D14_last"];if ~isempty(files),stems="example";end
for stem=stems
 if isempty(files),sel=readtable(fullfile(old,'per_crop_pixel/locomotion_scatters',stem+'_summary.csv'),'TextType','string');else,files=string(files);sel=table(files(:),'VariableNames',{'File'});end;S={table(),table()};E={table(),table()};fail=struct('file',{},'error',{});
 for j=1:height(sel)
 name=char(sel.File(j));fprintf('%s %d/%d %s\n',stem,j,height(sel),name);
 try
  c=load(fullfile(rerun,'trials',[name '.mat']),'C');C=c.C;p=load(fullfile(rerun,'trials',[name '.profiles.mat']),'P');P=p.P;ref=load(fullfile(old,'traces',[name '.mat']));
  assert(C.parameters.LOCOTHRESHOLD==40&&C.parameters.SLIPTHRESHOLD==2.5&&C.parameters.MOUSESIZETHRESHOLD==2);
  [D,geometry]=tailCropGeometry(C,fullfile(sourceRoot,name),fullfile(rerun,'code_snapshot'),fullfile(root,'balance_beam_tail_examples_L40_20261109',name,'weights_and_mapping.mat'),true);
  n=D.nFrames;h=D.height;w=D.width;np=D.noMouseProbability;
  for k=1:n,cc=bwconncomp(np(k,:)==0);for z=1:cc.NumObjects,f=cc.PixelIdxList{z};if f(1)>1&&numel(f)<=15,np(k,f)=1;end,end,end
  weights=np.^2;below=D.barTop+D.barWidth:h;bw=1+min(2*(0:numel(below)-1)'/(numel(below)-1),1);
  centroidHeight=C.mouseCentroids(:,2);centroidValid=isfinite(centroidHeight)&centroidHeight>0;
  boundaryRows=D.barTop-centroidHeight*[2 3];whole=zeros(n,2);rawHeight=nan(n,2);oldWhole=zeros(n,1);oldBelow=zeros(n,1);oldRawHeight=nan(n,1);maxError=0;
  isMovie=any(movieFiles==string(name));if isMovie,Q=zeros(n,h,2);A=zeros(n,w,2);BB=zeros(n,w);end
  aw=((0:D.barTop-1)'/(D.barTop-1)+eps).^3;aw=aw/max(aw);
  v=VideoReader(fullfile(sourceRoot,name));k=0;prev=[];
  for original=1:C.originalFrames(end)
   frame=readFrame(v);if original<C.originalFrames(1),continue;end;k=k+1;if size(frame,3)==3,frame=rgb2gray(frame);end;crop=frame(:,D.columns(k,:));
   if k>1
    delta=abs(double(crop)-double(prev))/255;q0=sum(delta.*D.columnWeightSquared(k,:),2);expected=double(P.probabilityWeighted(:,k));finite=isfinite(expected);assert(all(abs(q0(finite)-expected(finite))<=1e-6+1e-6*abs(expected(finite))));if any(finite),maxError=max(maxError,max(abs(q0(finite)-expected(finite))));end
    base=delta.*weights(k,:);q=sum(base,2);oldWhole(k)=sum(q);oldBelow(k)=bw'*q(below);if sum(q)>0,oldRawHeight(k)=(D.barTop-find(cumsum(q)>=sum(q)/2,1))*700/1201;end
    if isMovie,BB(k,:)=bw'*base(below,:);end
    for u=1:2
     pixel=base;if centroidValid(k),restore=(1:h)'<boundaryRows(k,u);pixel(restore,:)=delta(restore,:);else,pixel(:)=NaN;end
     q=sum(pixel,2);whole(k,u)=sum(q);if all(isfinite(q))&&sum(q)>0,rawHeight(k,u)=(D.barTop-find(cumsum(q)>=sum(q)/2,1))*700/1201;end
     if isMovie,Q(k,:,u)=q;A(k,:,u)=aw'*pixel(1:D.barTop,:);end
    end
   end
   prev=crop;
  end
  assert(k==n&&isequal(C.originalFrames(:),ref.originalFrames(:)));
  assert(all(abs(oldWhole-ref.wholeUnweighted)<=1e-7+1e-7*abs(ref.wholeUnweighted)));assert(all(abs(oldBelow-ref.x)<=1e-7+1e-7*abs(ref.x)));
  oldValid=~ref.invalid(:);oldHeight=localMean(oldRawHeight,oldValid);assert(isequal(isfinite(oldHeight),isfinite(ref.motionHeight)));assert(all(abs(oldHeight(oldValid)-ref.motionHeight(oldValid))<1e-8));
  for u=1:2
   factor=u+1;dest=fullfile(out,sprintf('factor%d',factor));wholeUnweighted=whole(:,u);invalid=ref.invalid(:)|~centroidValid;valid=~invalid&isfinite(wholeUnweighted)&isfinite(rawHeight(:,u));motionHeight=localMean(rawHeight(:,u),valid);invalid=~valid;
   % Below-bar detector amplitudes, boundaries, scores unchanged; only height gate differs.
   events=ref.events;if ~isempty(events),events.HeightAtPeakMM=motionHeight(events.PeakTraversalFrame);events.PassHeight=isfinite(events.HeightAtPeakMM)&events.HeightAtPeakMM<=7.5;end
   keep=valid&~logical(C.stoppingFrames(:))&isfinite(C.forwardSpeeds(:))&C.forwardSpeeds(:)>=40;
   baseKeep=oldValid&~logical(C.stoppingFrames(:))&isfinite(C.forwardSpeeds(:))&C.forwardSpeeds(:)>=40;
   count=0;score=0;if ~isempty(events),count=sum(events.PassHeight);score=sum(events.EventScore(events.PassHeight));end
   summary=table(string(name),mean(1000*wholeUnweighted(keep)/(h*w)),mean(motionHeight(valid)),count,score,sum(valid),sum(keep),sum(~centroidValid),maxError,mean(1000*ref.wholeUnweighted(baseKeep)/(h*w)),mean(ref.motionHeight(oldValid)),h,w,'VariableNames',{'File','LocomotingMean','MeanHeight','CountHeightFiltered','TotalScoreHeightFiltered','ValidFrames','LocomotionFrames','MissingCentroidFrames','MaxRowProfileError','BaselineLocomotingMean','BaselineMeanHeight','CropHeight','CropWidth'});
   originalFrames=C.originalFrames;parameters=C.parameters;normalized=ref.normalized;x=ref.x;smoothed=ref.smoothed;boundaryRow=boundaryRows(:,u);originalInvalid=ref.invalid;stoppingFrames=C.stoppingFrames;forwardSpeeds=C.forwardSpeeds;
   save(fullfile(dest,'traces',[name '.mat']),'summary','events','wholeUnweighted','motionHeight','invalid','originalInvalid','originalFrames','parameters','geometry','normalized','x','smoothed','boundaryRow','centroidHeight','stoppingFrames','forwardSpeeds','factor','-v7');
   if isMovie
    mi=find(movieFiles==string(name));folder=[movies(mi).file];group=extractBefore(string(folder),'_'); %#ok<NASGU>
    m=movies(mi);tag=regexp(name,'_D(\d\d)_','tokens','once');day="D"+string(str2double(tag{1}));ix=readtable('BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/trial-index.csv','TextType','string');g=ix.Group(ix.File==string(name));movieDir=fullfile(dest,char(g+"_"+day));if ~isfolder(movieDir),mkdir(movieDir);end
    writematrix(Q(:,:,u),fullfile(movieDir,'rows.csv'));writematrix(A(:,:,u),fullfile(movieDir,'above.csv'));writematrix(BB,fullfile(movieDir,'below.csv'));writematrix(boundaryRow,fullfile(movieDir,'boundary_rows.csv'));
   end
   S{u}=[S{u};summary];if ~isempty(events),E{u}=[E{u};events];end
  end
 catch ex
  fail(end+1)=struct('file',name,'error',getReport(ex,'extended','hyperlinks','off'));fprintf('FAILED %s\n',fail(end).error);
 end
 for u=1:2,d=fullfile(out,sprintf('factor%d',u+1));writetable(S{u},fullfile(d,stem+'_summary.csv'));if ~isempty(E{u}),writetable(E{u},fullfile(d,stem+'_events.csv'));end,end
 f=fopen(fullfile(out,stem+'_failures.json'),'w');fwrite(f,jsonencode(fail));fclose(f);
 end
end
end
function y=localMean(x,valid)
y=nan(size(x));a=find(diff([false;valid;false])==1);b=find(diff([false;valid;false])==-1)-1;
for j=1:numel(a),for k=a(j):b(j),y(k)=mean(x(max(a(j),k-2):min(b(j),k+2)));end,end
end
