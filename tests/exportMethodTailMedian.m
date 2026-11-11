root=fileparts(fileparts(mfilename('fullpath')));name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4';base=fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials',name);z=load([base '.profiles.mat'],'P');P=z.P;Q=double(P.probabilityWeighted);n=size(Q,2);raw=nan(n,1);invalid=P.invalidFramePairMask(:)|P.tailBadFrames(:);
for k=1:n
 v=Q(:,k);if invalid(k)||any(~isfinite(v)|v<0)||sum(v)<=0,invalid(k)=true;continue;end
 row=find(cumsum(v)>=sum(v)/2,1);raw(k)=(P.barTopOriginal-row)*700/1201;
end
smoothed=nan(n,1);
for k=1:n
 if ~isfinite(raw(k)),continue;end
 lo=k;while lo>max(1,k-2)&&isfinite(raw(lo-1)),lo=lo-1;end
 hi=k;while hi<min(n,k+2)&&isfinite(raw(hi+1)),hi=hi+1;end
 smoothed(k)=mean(raw(lo:hi));
end
T=table((1:n)',P.originalFrames(:),P.timeSeconds(:),P.tailBadFrames(:),P.invalidFramePairMask(:),invalid,raw,smoothed,'VariableNames',{'TraversalFrame','OriginalFrame','TimeSeconds','TailBadFrame','InvalidFramePair','HeightInvalid','MedianHeightMM','MedianHeight5FrameMM'});
writetable(T,fullfile(root,'BEAMCROSS/DRAFTFIGS/figMaterials/TMCS2_S18_D0_T2_tail_median_source.csv'));
fprintf('Frames %d; valid median %d; bar top %g\n',n,sum(isfinite(raw)),P.barTopOriginal);
