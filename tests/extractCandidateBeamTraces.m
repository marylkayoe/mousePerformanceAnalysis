function extractCandidateBeamTraces(outputDir, selectedIndices)
% Non-invasive capture of the 12 supplementary-video candidate traversals.
if nargin<2, selectedIndices=1:12; end
repo=fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repo)); set(groot,'defaultFigureVisible','off');
if ~isfolder(outputDir), mkdir(outputDir); end
codeDir=fullfile(outputDir,'instrumented_code'); if ~isfolder(codeDir), mkdir(codeDir); end
src=fileread(fullfile(repo,'BEAMCROSS','BBanalysisSingleFile.m'));
src=strrep(src,'function R = BBanalysisSingleFile','function R = captureCandidateBeam');
% Disable only the unconditional diagnostic plot; all numerical code is retained.
src=strrep(src,'''MAKEDEBUGPLOT'',true','''MAKEDEBUGPLOT'',false');
capture=sprintf(['\nC=struct; C.fileName=fileName; C.sourcePath=fullFilePath; C.parameters=p.Results;\n' ...
 'C.frameRate=frameRate; C.analysisFrameRate=FRAMERATE; C.originalFrames=mouseFrames(:);\n' ...
 'C.firstOriginalFrame=firstMouseFrame; C.lastOriginalFrame=lastMouseFrame;\n' ...
 'C.decodedVideoSize=size(videoMatrix); C.cropRange=cropRange; C.barTopCoordOriginal=barTopCoordOriginal;\n' ...
 'C.barTopCoordAnalysis=barTopCoord; C.barThickness=barThickness; C.mouseEntersFromRight=mouseEntersFromRight;\n' ...
 'C.mouseCentroids=mouseCentroids; C.forwardSpeeds=forwardSpeeds; C.movementTrace=movementTrace;\n' ...
 'C.stoppingFrames=stoppingFrames; C.timeSeconds=(C.originalFrames-1)/frameRate;\n' ...
 'save(fullfile(getenv(''BB_CAPTURE_DIR''),[fileName ''.partial.mat'']),''C'',''-v7'');\n']);
needle=' T = getTailMotionMetrics'; assert(contains(src,needle)); src=strrep(src,needle,[capture needle]);
needle='%% --- Generate Plots & Show Videos if Requested ---';
capture=sprintf(['C.tailMovementTraceAboveBar=T.tailMovementTraceAboveBar; C.tailBadFrames=T.badFrames;\n' ...
 'C.tailMovementTraceUnderBar=T.tailMovementTraceUnderBar; C.tailMovementTrace=T.tailMovementTrace;\n' ...
 'R=rmfield(R,''BBvideo''); R.capture=C;\n']);
src=strrep(src,needle,[capture needle]);
fid=fopen(fullfile(codeDir,'captureCandidateBeam.m'),'w'); fwrite(fid,src); fclose(fid);
addpath(codeDir,'-begin'); setenv('BB_CAPTURE_DIR',outputDir);
dataPath='/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved';
files=strings(12,1); k=0;
for cohort=1:2
 if cohort==1, prefix='TMCS3_S09_T3_C03'; dates={'20260219','20260305'}; else, prefix='TMCS2_S18_T3_C05'; dates={'20251022','20251105'}; end
 for day=1:2
  trials=1:3; if cohort==1 && day==1, trials=[1 2 4]; end
  for trial=trials
   k=k+1; files(k)=sprintf('%s_BB_D%02d_%s_THT_TRIAL%d_gray.mp4',prefix,(day-1)*14,dates{day},trial);
  end
 end
end
refDir='/Users/yoe/Downloads';
a=load(fullfile(refDir,'BB_values_261105_2.mat')); refValues=a.values_261105_2;
a=load(fullfile(refDir,'BB_fileNames_261105_2.mat')); refFiles=string(a.fileNames_261105_2);
a=load(fullfile(refDir,'BB_fieldNames_261105_2.mat')); refFields=string(a.fieldsToExtract);
disp(refFields); disp(refFiles(1:min(3,end)));
[~,commit]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
provenance=struct('commit',strtrim(commit),'matlabVersion',version,'referenceDirectory',refDir, ...
 'referenceVersionKnown',false,'referenceParametersKnown',false,'parametersBasis','Prior local validation: 2, 2.5, 150; exclude stops false. Tara settings unverified.');
save(fullfile(outputDir,'provenance.mat'),'provenance','files','refFields');
status=table(files,repmat("pending",12,1),nan(12,1),nan(12,1),nan(12,1),nan(12,1),nan(12,1),nan(12,1),nan(12,1),strings(12,1), ...
 'VariableNames',{'File','Status','Frames','FirstFrame','LastFrame','SpeedNonfinite','HeightNonfinite','MovementNonfinite','TailNonfinite','Error'});
comparison=table('Size',[0 7],'VariableTypes',{'string','string','double','double','double','logical','string'}, ...
 'VariableNames',{'File','Field','Regenerated','Reference','Difference','Match','Note'});
if isfile(fullfile(outputDir,'status.csv'))
 status=readtable(fullfile(outputDir,'status.csv'),'TextType','string');
 status.Error=string(status.Error); status.Error(ismissing(status.Error)|status.Error=="NaN")="";
 comparison=readtable(fullfile(outputDir,'summary_comparison.csv'),'TextType','string');
end
for j=selectedIndices
 if status.Status(j)=="saved", continue; end
 fprintf('\nCANDIDATE %d/12 %s\n',j,files(j));
 [~,disk]=system('df -k /System/Volumes/Data'); disp(disk);
 lines=splitlines(strtrim(disk)); parts=strsplit(strtrim(lines{end})); assert(str2double(parts{4})/1024^2>=20,'Low disk space');
 [~,swap]=system('sysctl vm.swapusage'); disp(swap);
 tok=regexp(swap,'used = ([0-9.]+)M','tokens','once'); if str2double(tok{1})>8192, warning('Swap exceeds 8 GiB; operator warned; one fresh process per remaining trial.'); end
 try
  assert(isfile(fullfile(dataPath,files(j))),'Source video missing');
  R=captureCandidateBeam(dataPath,char(files(j)),'MOUSESIZETHRESHOLD',2,'SLIPTHRESHOLD',2.5,'LOCOTHRESHOLD',150, ...
   'EXCLUDE_STOPPING_FRAMES',false,'MAKEPLOT',false,'SHOWVIDEOS',false);
  assert(isstruct(R)&&isfield(R,'capture'),'Analysis did not produce capture');
  C=R.capture; R=rmfield(R,'capture'); C.summary=R; C.provenance=provenance;
  lengths=[numel(C.originalFrames),numel(C.forwardSpeeds),size(C.mouseCentroids,1),numel(C.movementTrace),numel(C.tailMovementTraceAboveBar),numel(C.tailBadFrames)];
  C.traceLengths=lengths; C.alignmentValid=all(lengths==lengths(1)) && all(diff(C.originalFrames)==1);
  save(fullfile(outputDir,[char(files(j)) '.mat']),'C','-v7');
  assert(C.alignmentValid,'Trace lengths or original-frame mapping mismatch; raw values saved without trimming/padding');
  n=lengths(1); F=table(repmat(files(j),n,1),C.originalFrames,C.timeSeconds,repmat(C.frameRate,n,1), ...
   C.forwardSpeeds(:),C.mouseCentroids(:,2),C.movementTrace(:),C.tailMovementTraceAboveBar(:),C.tailBadFrames(:), ...
   'VariableNames',{'File','OriginalFrame','TimeSeconds','FrameRate','ForwardSpeed','PostureHeight','MovementTrace','TailMovementAboveBar','TailBadFrame'});
  writetable(F,fullfile(outputDir,[char(files(j)) '.csv']));
  % Verify MAT and CSV preserve frame mapping and nonfinite samples.
  V=load(fullfile(outputDir,[char(files(j)) '.mat'])); assert(isequaln(V.C,C));
  Q=readtable(fullfile(outputDir,[char(files(j)) '.csv']));
  assert(isequal(Q.OriginalFrame,C.originalFrames));
  A=F{:,5:8}; B=Q{:,5:8}; assert(isequal(isnan(A),isnan(B))&&isequal(isinf(A),isinf(B)));
  mask=isfinite(A); assert(all(abs(A(mask)-B(mask))<=1e-10*max(1,abs(A(mask)))));
  status{j,3:9}=[n,C.firstOriginalFrame,C.lastOriginalFrame,sum(~isfinite(A),1)]; status.Status(j)="saved";
  idx=find(refFiles==files(j));
  if numel(idx)~=1
   comparison(end+1,:)={files(j),"ALL",NaN,NaN,NaN,false,"Reference filename missing or ambiguous"};
  else
   referenceRow=refValues(idx,:); save(fullfile(outputDir,[char(files(j)) '.reference.mat']),'referenceRow','refFields');
   for q=1:numel(refFields)
    field=char(refFields(q)); ref=refValues{idx,q};
    if isfield(R,field)&&isnumeric(R.(field))&&isnumeric(ref)
     value=R.(field); equal=isequal(size(value),size(ref));
     if equal
      equal=all((isnan(value(:))&isnan(ref(:))) | (value(:)==ref(:)) | ...
       (isfinite(value(:))&isfinite(ref(:))&abs(value(:)-ref(:))<=1e-8+1e-6*abs(ref(:))));
     end
     if isscalar(value)&&isscalar(ref), comparison(end+1,:)={files(j),string(field),value,ref,value-ref,equal,"scalar"};
     else, comparison(end+1,:)={files(j),string(field),NaN,NaN,NaN,equal,"array comparison; values in MAT files"}; end
    else
     comparison(end+1,:)={files(j),string(field),NaN,NaN,NaN,false,"field absent or nonnumeric"};
    end
   end
  end
  fprintf('SAVED frames=%d bounds=%d:%d nonfinite=%s\n',n,C.firstOriginalFrame,C.lastOriginalFrame,mat2str(sum(~isfinite(A),1)));
 catch ME
  status.Status(j)="failed"; status.Error(j)=string(getReport(ME,'extended','hyperlinks','off')); disp(status.Error(j));
 end
 writetable(status,fullfile(outputDir,'status.csv')); writetable(comparison,fullfile(outputDir,'summary_comparison.csv'));
 clear R C V Q F A B; close all force
end
save(fullfile(outputDir,'comparison.mat'),'comparison','status'); disp(status); fprintf('COMPLETE\n');
end
