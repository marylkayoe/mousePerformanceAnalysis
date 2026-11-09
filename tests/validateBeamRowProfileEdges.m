function result=validateBeamRowProfileEdges()
% Small synthetic checks: stationary frames, one-row motion, and bad-pair propagation.
V=zeros(20,10,8,'uint8');W=ones(10,8);bad=false(8,1);xy=repmat([5 5],8,1);
T=makeT(V,W,bad);P=computeBeamRowProfiles(T,xy,10,2);
assert(all(isnan(P.weightedPosition))&&all(isnan(P.unweightedPosition)));
assert(all(P.weightedNoMotion)&&all(P.unweightedNoMotion));assert(all(P.scalarReconstructionMatch));
V(12,3,2:end)=255;W(3,2)=.9;
T=makeT(V,W,bad);P=computeBeamRowProfiles(T,xy,10,2);
assert(abs(double(P.unweighted(12,2))-1)<1e-8);
assert(abs(double(P.probabilityWeighted(12,2))-.81)<1e-6);
assert(abs(P.weightedPosition(2)+2)<1e-12&&P.weightedBelowBarFraction(2)==1);
assert(isnan(P.weightedPosition(1))&&all(isnan(P.weightedPosition(3:end))));
bad(2)=true;T=makeT(V,W,bad);P=computeBeamRowProfiles(T,xy,10,2);
assert(all(P.invalidFramePairMask(1:3))&&~P.invalidFramePairMask(4));
assert(isnan(P.weightedPosition(2))&&isnan(P.weightedBelowBarFraction(2)));
bad(:)=false;xy(2,1)=NaN;T=makeT(V,W,bad);P=computeBeamRowProfiles(T,xy,10,2);
assert(all(P.invalidFramePairMask(1:3))&&isnan(P.weightedPosition(2)));
result=struct('passed',true,'checks',{{'No-motion indices missing','Destination probability squared','Known row height and below-bar fraction','First-frame missing','Bad crop propagates to next difference','Original missing X propagates to next difference'}});
end
function T=makeT(V,W,bad)
T=struct('postMouseVideoMatrix',V,'croppedNoMouseProbValues',W,'badFrames',bad);
T.tailMovementTrace=getTailMotionTrace(V,W);T.tailMovementTraceAboveBar=getTailMotionTrace(V(1:10,:,:),W);
T.tailMovementTraceUnderBar=getTailMotionTrace(V(12:end,:,:),W,'verticalWeightMaxAt',.5);
T.tailMovementTrace(bad)=NaN;T.tailMovementTraceAboveBar(bad)=NaN;T.tailMovementTraceUnderBar(bad)=NaN;
end
