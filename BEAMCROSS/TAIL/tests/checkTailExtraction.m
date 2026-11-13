function checkTailExtraction
% Small synthetic parity check. Does not read video or write scientific data.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(root,'BEAMCROSS','TAIL'));addpath(fullfile(root,'BEAMCROSS'));
assert(strcmp(root,bbtail.repositoryRoot()));
names={'getTailMotionTrace','getTailMotionMetrics','reweightTaraTailProfiles', ...
 'reweightTaraWholeTailProfiles','exportD0TailSpatialProfiles', ...
 'exportD14TailSpatialProfiles','exportTailCDFValues','countD0FirstBelowBarPeaks', ...
 'countBelowBarMotionEpisodes','extractTailHeight'};
for k=1:numel(names),assert(~isempty(which(['bbtail.' names{k}])));end
rng(12);v=uint8(randi([0 255],[9 11 25]));p=rand(11,25);
a=bbtail.getTailMotionTrace(v,p);b=getTailMotionTrace(v,p);assert(isequaln(a,b));
z=bbtail.getTailMotionTrace(zeros(9,11,25,'uint8'),p);assert(numel(z)==25);
% Optional migration-only reference provided outside repository.
if exist('tailTraceBeforeExtraction','file')==2
 c=tailTraceBeforeExtraction(v,p);assert(isequaln(a,c));
 assert(isequaln(z,tailTraceBeforeExtraction(zeros(9,11,25,'uint8'),p)));
 fprintf('Original/package/wrapper synthetic outputs identical, including zero-motion nonfinite handling.\n');
end
fprintf('10 package entry points resolve; root and compatibility checks passed.\n');
end
