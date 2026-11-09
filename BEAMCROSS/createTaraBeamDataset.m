function createTaraBeamDataset(archive, reweightFolder, destination, opts)
%CREATETARABEAMDATASET Combine original per-trial C, P and corrected R.
% One v7.3 MAT variable, dataset, contains dataset.trials(i).original,
% .rowProfiles and .correctedBelow for every retained original video name.
% Inputs are the original rerun ZIP and the corrected-below results folder.
% Output is new; no source files are modified. Temporary files contain only
% one trial pair at a time, plus small index/metadata files.
arguments
 archive (1,:) char
 reweightFolder (1,:) char
 destination (1,:) char
 opts.ReplaceExisting (1,1) logical = false
end
assert(isfile(archive),'Rerun archive not found');
assert(isfolder(fullfile(reweightFolder,'trials')),'Corrected trial results not found');
assert(endsWith(lower(destination),'.mat'),'Destination must be a MAT file');
assert(~isfile(destination)||opts.ReplaceExisting,'Destination already exists; set ReplaceExisting=true to replace it after validation.');
parent=fileparts(destination); if isempty(parent),parent=pwd;end
assert(isfolder(parent),'Destination folder does not exist');
work=tempname;mkdir(work);cleaner=onCleanup(@()rmdir(work,'s')); %#ok<NASGU>
helper=fullfile(fileparts(mfilename('fullpath')),'private','extractTaraBeamArchive.py');
extract(helper,archive,'--index',work);
manifest=readtable(fullfile(work,'trial_manifest.csv'),'TextType','string');
assert(height(manifest)==377 && numel(unique(manifest.File))==377,'Unexpected trial manifest');
index=load(fullfile(work,'dataset_index.mat'));
% The old reference-comparison table contains three superseded numerical
% below-bar summary measures; remove those rows rather than mislabel them.
if isfield(index,'comparison') && istable(index.comparison)
 fields=lower(string(index.comparison.Field));
 index.comparison(contains(fields,'underbar')|contains(fields,'belowbar'),:)=[];
end
dataset=struct;
dataset.schema='Tara balance beam combined trial results v2';
dataset.createdUTC=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
dataset.sourceArchive=archive;
dataset.correctedResultsFolder=reweightFolder;
dataset.description=['Each trial contains the original rerun C, full row profiles P, and corrected below-bar result R. ' ...
 'Original source videos, moving crop videos, and per-column debug contributions were not stored for every trial and are not included. ' ...
 'NaN/Inf, original frame numbers, invalid masks, source filenames, parameter values and corrected below-bar traces are retained. ' ...
 'Superseded original below-bar values and their old reference-comparison rows are omitted; the original source archive remains unchanged.'];
dataset.rerunReadme=fileread(fullfile(work,'README.txt'));
dataset.rerunMethods=fileread(fullfile(work,'METHODS.txt'));
dataset.rerunValidation=fileread(fullfile(work,'VALIDATION_REPORT.txt'));
dataset.rerunVisualAudit=fileread(fullfile(work,'VISUAL_AUDIT_NOTES.txt'));
dataset.rerunManifestJSON=fileread(fullfile(work,'run_manifest.json'));
dataset.correctedMethods=fileread(fullfile(reweightFolder,'METHODS.md'));
dataset.correctedValidation=fileread(fullfile(reweightFolder,'validation_summary.json'));
dataset.manifest=manifest;dataset.originalDatasetIndex=index;
template=struct('fileName','','original',[],'rowProfiles',[],'correctedBelow',[]);
dataset.trials=repmat(template,height(manifest),1);
for j=1:height(manifest)
 file=char(manifest.File(j));extract(helper,archive,file,work);
 c=load(fullfile(work,'trial.mat'),'C');p=load(fullfile(work,'profiles.mat'),'P');
 corrected=fullfile(reweightFolder,'trials',[file '.mat']);assert(isfile(corrected),'Missing corrected result for %s',file);
 r=load(corrected,'R'); C=c.C;P=p.P;R=r.R;clear c p r
 assert(strcmp(P.fileName,file)&&strcmp(R.fileName,file),'Original trial identity differs: %s',file);
 assert(isequal(C.originalFrames(:),P.originalFrames(:),R.originalFrames(:)),'Frame mismatch: %s',file);
 assert(isequaln(C.timeSeconds(:),P.timeSeconds(:),R.timeSeconds(:)),'Timing mismatch: %s',file);
 assert(isequal(P.invalidFramePairMask(:),R.invalidFramePairMask(:)),'Mask mismatch: %s',file);
 assert(isequal(P.tailBadFrames(:),C.tailBadFrames(:),R.tailBadFrames(:)),'Bad-frame mismatch: %s',file);
 assert(P.barTopOriginal==R.barTopOriginal&&P.barWidth==R.barWidth,'Geometry mismatch: %s',file);
 assert(size(P.probabilityWeighted,2)==numel(C.originalFrames) && isequal(size(P.probabilityWeighted),size(P.unweighted)),'Profile size mismatch: %s',file);
 assert(strcmp(R.status,'complete')&&all(R.reconstructionMatch),'Corrected result failed validation: %s',file);
 % Keep the full unweighted and probability-weighted row profiles: they are
 % raw measurements, not the superseded below-bar weighted trace.
 C=dropFields(C,{'tailMovementTraceUnderBar'});
 C.summary=dropFields(C.summary,{'tailMotionSumUnderBar','tailMotionIndexUnderBar','tailMotionMeanUnderBar'});
 if isfield(C,'frameLengths'),C.frameLengths=dropFields(C.frameLengths,{'tailMovementTraceUnderBar'});end
 if isfield(C,'nonfinite'),C.nonfinite=dropFields(C.nonfinite,{'tailMovementTraceUnderBar'});end
 R=dropFields(R,{'oldBelowRowWeights','originalBelowTrace','reconstructedOriginalTraces','oldBelowRaw'});
 dataset.trials(j)=struct('fileName',file,'original',C,'rowProfiles',P,'correctedBelow',R);
 if mod(j,25)==0||j==height(manifest),fprintf('Combined %d/%d trials\n',j,height(manifest));end
end
% Write to the requested volume as a temporary sibling and rename only after
% read-back validation. A failed intermediate file is retained for inspection.
partial=[destination '.partial.mat'];assert(~isfile(partial),'Partial output already exists');
fprintf('Saving combined MAT file...\n');save(partial,'dataset','-v7.3');
clear dataset C P R
fprintf('Reading saved file for validation...\n');v=load(partial,'dataset');dataset=v.dataset;clear v
assert(numel(dataset.trials)==height(manifest));
for j=1:height(manifest)
 t=dataset.trials(j);assert(strcmp(t.fileName,char(manifest.File(j))));
 assert(isequal(t.original.originalFrames(:),t.rowProfiles.originalFrames(:),t.correctedBelow.originalFrames(:)));
 assert(isequal(t.rowProfiles.invalidFramePairMask(:),t.correctedBelow.invalidFramePairMask(:)));
 assert(size(t.rowProfiles.probabilityWeighted,2)==numel(t.original.originalFrames));
 assert(~isfield(t.original,'tailMovementTraceUnderBar')&&~isfield(t.correctedBelow,'originalBelowTrace')&&~isfield(t.correctedBelow,'oldBelowRaw'));
end
clear dataset t
if opts.ReplaceExisting
 [ok,msg]=movefile(partial,destination,'f');
else
 [ok,msg]=movefile(partial,destination);
end
assert(ok,'Could not rename verified result: %s',msg);
fprintf('Saved and verified %d trials: %s\n',height(manifest),destination);
end
function s=dropFields(s,names)
names=intersect(fieldnames(s),names);
if ~isempty(names),s=rmfield(s,names);end
end
function extract(helper,archive,key,work)
cmd=sprintf('python3 %s %s %s %s',quote(helper),quote(archive),quote(key),quote(work));
[status,out]=system(cmd);assert(status==0,'Archive extraction failed: %s',out);
end
function s=quote(s)
s=['''' strrep(s,'''','''"''"''') ''''];
end
