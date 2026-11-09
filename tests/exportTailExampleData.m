function exportTailExampleData(T,C)
% Additive export of original tail debug quantities, no analysis arithmetic changes.
out=getenv('TARA_TAIL_EXAMPLE_OUTPUT');root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
S=load(fullfile(root,'trials',[C.fileName '.mat']),'C');old=S.C;
assert(isequaln(C.mouseCentroids,old.mouseCentroids)&&isequaln(C.forwardSpeeds,old.forwardSpeeds));
assert(isequal(C.originalFrames,old.originalFrames)&&isequaln(C.movementTrace,old.movementTrace));
assert(isequaln(T.tailMovementTrace(:),old.tailMovementTrace(:)));
assert(isequaln(T.tailMovementTraceAboveBar(:),old.tailMovementTraceAboveBar(:)));
assert(isequaln(T.tailMovementTraceUnderBar(:),old.tailMovementTraceUnderBar(:)));
assert(isequal(T.badFrames(:),old.tailBadFrames(:)));
dest=fullfile(out,C.fileName);if ~exist(dest,'dir'),mkdir(dest);end
V=T.postMouseVideoMatrix;[h,w,n]=size(V);bar=C.barTopCoordOriginal;bw=C.barThickness;
delta=abs(diff(im2double(V),1,3));above=1:bar;below=bar+bw:h;
aw=((0:numel(above)-1)'/(numel(above)-1)+eps).^3;aw=aw/max(aw);
bwgt=(min(2*(0:numel(below)-1)'/(numel(below)-1),1)+eps).^3;bwgt=bwgt/max(bwgt);
tw=((0:h-1)'/(h-1)+eps).^3;tw=tw/max(tw);
q=T.croppedNoMouseProbValues.^2;
ac=reshape(aw'*reshape(delta(above,:,:),numel(above),[]),w,n-1).*q(:,2:end);
bc=reshape(bwgt'*reshape(delta(below,:,:),numel(below),[]),w,n-1).*q(:,2:end);
gradient=ones(h,1);gradient(1:bar)=linspace(0,1,bar)';nb=h-(bar+bw)+1;gradient(bar+bw:end)=1+(1:nb)'/nb;
rows=reshape(sum(delta,2),h,n-1).*gradient;
D=struct('file',C.fileName,'group',old.identifiers.group,'height',h,'width',w,'nFrames',n,...
 'originalFrames',C.originalFrames(:),'encodedTimes',old.timeSeconds(:),'barTop',bar,'barWidth',C.barThickness,...
 'badFrames',T.badFrames(:),'previousBadFrames',[true;T.badFrames(1:end-1)],'columns',T.cols,...
 'noMouseProbability',T.croppedNoMouseProbValues','columnWeightSquared',q',...
 'aboveContrib',[zeros(1,w);ac'],'belowContrib',[zeros(1,w);bc'],'rowMotion',[zeros(1,h);rows'],...
 'totalRowWeight',tw,'aboveRowWeight',[aw;zeros(h-numel(above),1)],'belowRowWeight',[zeros(bar+bw-1,1);bwgt],...
 'tailTotal',T.tailMovementTrace(:),'tailAbove',T.tailMovementTraceAboveBar(:),'tailBelow',T.tailMovementTraceUnderBar(:),...
 'videoReaderFrameRate',old.videoReaderFrameRate,'analysisFrameRate',old.analysisFrameRate,...
 'playbackFrameRate',30,'exactValidatedMatch',true,'parameters',old.parameters);
clear delta ac bc rows;
save(fullfile(dest,'weights_and_mapping.mat'),'D','-v7');
fid=fopen(fullfile(dest,'weights_and_mapping.json'),'w');fprintf(fid,'%s',jsonencode(D));fclose(fid);
F=table((1:n)',C.originalFrames(:),old.timeSeconds(:),T.badFrames(:),D.previousBadFrames,...
 T.tailMovementTrace(:),T.tailMovementTraceAboveBar(:),T.tailMovementTraceUnderBar(:),...
 'VariableNames',{'DebugFrame','OriginalFrame','EncodedTimeSeconds','TailBadFrame','PreviousTailBadFrame','TailTotal','TailAbove','TailBelow'});
writetable(F,fullfile(dest,'frame_mapping.csv'));
writer=VideoWriter(fullfile(dest,'post_mouse_crop.mp4'),'MPEG-4');writer.FrameRate=30;writer.Quality=100;open(writer);
for k=1:n
 img=V(:,:,k);if mod(w,2),img(:,end+1)=img(:,end);end
 writeVideo(writer,img);
end
close(writer);
preview=jsondecode(fileread(fullfile(out,[char(old.identifiers.group) '_preview_frames.json'])));
for original=preview(:)'
 k=find(C.originalFrames==original);assert(numel(k)==1&&k>1&&~T.badFrames(k)&&~T.badFrames(k-1));
 imwrite(V(:,:,k),fullfile(dest,sprintf('crop_f%d.png',original)));
 imwrite(V(:,:,k-1),fullfile(dest,sprintf('crop_f%d_previous.png',original)));
end
fprintf('TAIL EXAMPLE VERIFIED %s frames=%d width=%d bad=%d\n',C.fileName,n,w,sum(T.badFrames));
end
