function info = createTailMetricsDebugVideo(exportFolder, profileFile, outputFile, opts)
%CREATETAILMETRICSDEBUGVIDEO Render a validated, cropped tail tracking demo.
% info = createTailMetricsDebugVideo(exportFolder, profileFile, outputFile)
% exportFolder contains column_contributions.mat (E), frame_mapping.csv with
% per-frame lossless SHA-256 hashes, and post_mouse_crop_lossless.mkv.
% profileFile is the same trial's saved *.profiles.mat (P). This function
% does not infer column profiles or crop video from scalar tail traces.
% Options: MillimetersPerPixel (default 700/1201, Tara calibration),
% PlaybackFPS (30), ScaleBarMM (20), DisplayScale (2),
% DisplaySpatialWindow (1: no smoothing; odd integer in source columns).
arguments
 exportFolder (1,:) char
 profileFile (1,:) char
 outputFile (1,:) char
 opts.MillimetersPerPixel (1,1) double {mustBePositive,mustBeFinite} = 700/1201
 opts.PlaybackFPS (1,1) double {mustBePositive,mustBeFinite} = 30
 opts.ScaleBarMM (1,1) double {mustBePositive,mustBeFinite} = 20
 opts.DisplayScale (1,1) double {mustBeInteger,mustBePositive} = 2
 opts.DisplaySpatialWindow (1,1) double {mustBeInteger,mustBePositive} = 1
end
assert(mod(opts.DisplaySpatialWindow,2)==1,'DisplaySpatialWindow must be odd.');
assert(~isfile(outputFile),'Output exists; choose a new file to avoid overwriting it.');
assert(endsWith(lower(outputFile),'.mp4'),'Output must have an .mp4 extension.');
crop=fullfile(exportFolder,'post_mouse_crop_lossless.mkv'); map=fullfile(exportFolder,'frame_mapping.csv');
assert(isfile(crop)&&isfile(map)&&isfile(profileFile),'Missing crop, frame mapping, or row-profile file.');
a=load(fullfile(exportFolder,'column_contributions.mat'),'E'); b=load(profileFile,'P'); E=a.E; P=b.P;
[~,profileName,ext]=fileparts(profileFile);assert(strcmp([profileName ext],[E.fileName '.profiles.mat']),'Profile filename does not match original source filename.');
assert(isfield(P,'fileName')&&strcmp(P.fileName,E.fileName),'Stored profile trial identifier differs.');
assert(isfield(P,'originalFrames')&&isequal(P.originalFrames(:),E.originalFrames(:)),'Original frame mapping differs.');
assert(isequal(P.invalidFramePairMask(:),E.invalidFramePairMask(:)),'Invalid frame-pair masks differ.');
assert(P.barTopOriginal==E.barTopOriginal && P.barWidth==E.barWidth,'Bar geometry differs.');
n=E.nFrames; assert(isequal(size(P.probabilityWeighted),[E.height,n]),'Row-profile dimensions differ.');
assert(isequal(size(E.aboveContributions),[n,E.width])&&isequal(size(E.newBelowContributions),[n,E.width]),'Column-profile dimensions differ.');
assert(isfield(E,'rowProfileMatches')&&all(E.rowProfileMatches(:))&&isfield(E,'newBelowMatches')&&all(E.newBelowMatches(:)),'Saved export failed numerical validation.');
m=readtable(map,'TextType','string'); assert(height(m)==n && isequal(double(m.OriginalFrame(:)),double(E.originalFrames(:))) && isequal(logical(m.InvalidFramePair(:)),logical(E.invalidFramePairMask(:))),'Frame mapping differs.');
assert(ismember('LosslessGrayFrameSHA256',m.Properties.VariableNames),'Crop frame hashes are required.');
assert(all(isfinite(double(P.rowHeightRelativeToBar(:)))) && isequal(double(P.rowHeightRelativeToBar(:)),double(E.barTopOriginal-(1:E.height)')),'Row height convention differs.');
work=tempname;mkdir(work);cleaner=onCleanup(@()rmdir(work,'s')); %#ok<NASGU>
writematrix(double(P.probabilityWeighted)',fullfile(work,'rows.csv'));
writematrix(double(E.aboveContributions),fullfile(work,'above.csv'));
writematrix(double(E.newBelowContributions),fullfile(work,'below.csv'));
metadata=struct('sourceFilename',E.fileName,'width',E.width,'height',E.height,'nFrames',n,'barTop',E.barTopOriginal,'barWidth',E.barWidth,'originalFrames',double(E.originalFrames(:))','invalid',logical(E.invalidFramePairMask(:))','mmPerPixel',opts.MillimetersPerPixel,'fps',opts.PlaybackFPS,'scaleBarMM',opts.ScaleBarMM,'displayScale',opts.DisplayScale,'displaySpatialWindow',opts.DisplaySpatialWindow);
fid=fopen(fullfile(work,'metadata.json'),'w');assert(fid>=0);fwrite(fid,jsonencode(metadata),'char');fclose(fid);
here=fileparts(mfilename('fullpath'));python=fullfile(here,'private','renderTailMetricsDebug.py');font=fullfile(here,'private','tailDebugLabel.c');
workOutput=fullfile(work,'result.mp4');cmd=sprintf('python3 %s %s %s %s %s %s',quote(python),quote(work),quote(crop),quote(map),quote(font),quote(workOutput));
[status,out]=system(cmd);assert(status==0,'Debug rendering failed: %s',out);
[ok,msg]=movefile(workOutput,outputFile);assert(ok,'Could not save video: %s',msg);
info=struct('outputFile',outputFile,'sourceFilename',E.fileName,'frames',n,'playbackFPS',opts.PlaybackFPS,'millimetersPerPixel',opts.MillimetersPerPixel,'displaySpatialWindow',opts.DisplaySpatialWindow,'renderLog',strtrim(out));
end
function s=quote(s)
% POSIX shell quoting for paths.
s=['''' strrep(s,'''','''"''"''') ''''];
end
