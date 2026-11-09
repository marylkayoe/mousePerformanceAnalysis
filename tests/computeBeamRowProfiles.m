function P=computeBeamRowProfiles(T,centroids,barTop,barWidth)
% Additive diagnostic. Never modifies T or an existing scalar motion measure.
V=T.postMouseVideoMatrix; W=T.croppedNoMouseProbValues;
[h,~,n]=size(V); assert(size(W,2)==n && size(centroids,1)==n);
U=nan(h,n); Q=nan(h,n);
prev=im2double(V(:,:,1));
for k=2:n
 current=im2double(V(:,:,k)); D=abs(current-prev);
 U(:,k)=sum(D,2); Q(:,k)=sum(D.*(double(W(:,k)').^2),2);
 prev=current;
end
bad=T.badFrames(:); missingX=~isfinite(centroids(:,1));
invalid=[true; bad(2:end)|bad(1:end-1)|missingX(2:end)|missingX(1:end-1)];
height=(barTop-(1:h))'; below=(1:h)'>=barTop+barWidth;
P=struct; P.rowNumbersOriginalVideo=(1:h)'; P.rowHeightRelativeToBar=height;
P.barTopOriginal=barTop; P.barWidth=barWidth; P.tailBadFrames=bad;
P.invalidFramePairMask=invalid; P.originalTrackingXMissing=missingX;
[P.unweightedPosition,P.unweightedBelowBarFraction,P.unweightedTotal,P.unweightedNoMotion]=indices(U,height,below,invalid);
[P.weightedPosition,P.weightedBelowBarFraction,P.weightedTotal,P.weightedNoMotion]=indices(Q,height,below,invalid);
P.unweighted=single(U); P.probabilityWeighted=single(Q);
P.weightsDescription='sum_x(abs(I_k-I_(k-1)).*croppedNoMouseProbValues(:,k).^2); probability cutoff 0.85 already applied; no vertical weighting or smoothing in profiles/indices; uint8 pixels scaled by 1/255';
P.indexDescription='sum_r((barTop-r)*motion_r)/sum_r(motion_r); positive above bar; below fraction uses r>=barTop+barWidth; no-motion, first, invalid pair or missing original X -> NaN';
P.storageClass='single compressed MAT-v7 profiles; indices computed in double';
regions={1:h,1:barTop,barTop+barWidth:h}; powers=[1 1 .5];
targets={T.tailMovementTrace,T.tailMovementTraceAboveBar,T.tailMovementTraceUnderBar};
P.scalarReconstructionMatch=false(1,3); P.scalarReconstructionMaxAbsError=nan(1,3);
for k=1:3
 rows=regions{k}; r=(0:numel(rows)-1)'/(numel(rows)-1);
 vertical=(min(r/powers(k),1)+eps).^3; vertical=vertical/max(vertical);
 raw=sum(Q(rows,:).*vertical,1)'; raw(1)=0; raw=smooth(raw,5);
 med=median(raw,'omitnan'); scale=1.4826*median(abs(raw-med),'omitnan');
 pred=(raw-med)/scale; pred(isnan(pred))=0; pred(bad)=NaN; actual=targets{k}(:);
 P.scalarReconstructionMatch(k)=all((isnan(pred)&isnan(actual))|(pred==actual)| ...
  (isfinite(pred)&isfinite(actual)&abs(pred-actual)<=1e-8+1e-6*abs(actual)));
 finite=isfinite(pred)&isfinite(actual); if any(finite), P.scalarReconstructionMaxAbsError(k)=max(abs(pred(finite)-actual(finite))); end
end
end
function [position,fraction,total,noMotion]=indices(M,height,below,invalid)
total=sum(M,1)'; noMotion=~isfinite(total)|total<=0;
position=(sum(M.*height,1)')./total; fraction=(sum(M(below,:),1)')./total;
position(invalid|noMotion)=NaN; fraction(invalid|noMotion)=NaN;
end
