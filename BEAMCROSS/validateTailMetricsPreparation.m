function result=validateTailMetricsPreparation(folder,rerunRoot,correctedRoot)
% Independently normalize serialized contribution sums against saved traces.
z=load(fullfile(folder,'column_contributions.mat'),'E');E=z.E;
z=load(fullfile(rerunRoot,'trials',[E.fileName '.mat']),'C');C=z.C;
z=load(fullfile(correctedRoot,'trials',[E.fileName '.mat']),'R');R=z.R;
assert(isequal(E.originalFrames(:),C.originalFrames(:),R.originalFrames(:)));
raws={sum(E.aboveContributions,2),sum(E.newBelowContributions,2)};
targets={C.tailMovementTraceAboveBar(:),R.newBelowTrace(:)};
result=struct('fileName',E.fileName,'absoluteTolerance',1e-6,'relativeTolerance',1e-6, ...
 'aboveNormalizedMatch',false,'belowNormalizedMatch',false,'maxAbsoluteErrors',nan(1,2));
matches=false(1,2);
for j=1:2
 sm=smooth(raws{j},5);m=median(sm,'omitnan');sig=1.4826*median(abs(sm-m),'omitnan');
 pred=(sm-m)/sig;pred(isnan(pred))=0;pred(E.tailBadFrames)=NaN;a=targets{j};
 finite=isfinite(a)&isfinite(pred);
 matches(j)=all((isnan(a)&isnan(pred))|(a==pred)|(finite&abs(a-pred)<=1e-6+1e-6*abs(a)));
 if any(finite),result.maxAbsoluteErrors(j)=max(abs(a(finite)-pred(finite)));end
end
result.aboveNormalizedMatch=matches(1);result.belowNormalizedMatch=matches(2);
assert(all(matches),'Decoded contributions do not reproduce normalized saved traces.');
end
