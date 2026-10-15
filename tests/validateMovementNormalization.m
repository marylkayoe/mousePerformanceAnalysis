function validateMovementNormalization(outputDir)
% Validate 40 videos, retaining scalar metrics and warnings, not video arrays.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(genpath(root));
set(groot,'defaultFigureVisible','off');
dataPath='/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved';
files=dir(fullfile(dataPath,'*.mp4')); names=sort(string({files.name})');
previous=readtable('/Volumes/ShosaiData/DATA/Tara/RESULTS/stop_exclusion_comparison_20261015/comparison.csv','TextType','string');
priority=unique([previous.File; "TMCS2_S10_T1_C04_BB_D07_20251029_THT_TRIAL1_gray.mp4"],'stable');
remaining=setdiff(names,priority); rng(20261016,'twister');
selected=[priority;remaining(randperm(numel(remaining),40-numel(priority)))];
if ~exist(outputDir,'dir'),mkdir(outputDir);end
results=table(selected,nan(40,1),nan(40,1),nan(40,1),nan(40,1),nan(40,1),false(40,1),false(40,1),false(40,1),repmat("pending",40,1),strings(40,1), ...
 'VariableNames',{'File','NSlips','TotalMagnitude','NStops','MissingCentroids','Seconds','FiniteSlipMetrics','BaselineFallback','InvalidNormalization','Status','Error'});
csvPath=fullfile(outputDir,'validation.csv');
if exist(csvPath,'file')
 results=readtable(csvPath,'TextType','string');
 selected=results.File;
end
for j=1:40
 if results.Status(j)~="pending",continue;end
 [~,diskInfo]=system('df -k /System/Volumes/Data'); lines=splitlines(strtrim(diskInfo));parts=strsplit(strtrim(lines{end}));freeGB=str2double(parts{4})/1024^2;
 [~,swapInfo]=system('sysctl vm.swapusage'); tok=regexp(swapInfo,'used = ([0-9.]+)M','tokens','once');
 fprintf('RESOURCES disk=%.2f GiB %s',freeGB,swapInfo);
 if freeGB<20 || isempty(tok) || str2double(tok{1})>8192
  fprintf('RESOURCE STOP before %d\n',j); break
 end
 fprintf('\nTEST %d/40 %s\n',j,selected(j)); t=tic; captured='';
 try
  captured=evalc('R=BBanalysisSingleFile(dataPath,char(selected(j)),''MOUSESIZETHRESHOLD'',2,''SLIPTHRESHOLD'',2.5,''LOCOTHRESHOLD'',150,''EXCLUDE_STOPPING_FRAMES'',false,''MAKEPLOT'',false,''SHOWVIDEOS'',false);');
  assert(isstruct(R),'Analysis returned a nonstruct result.');
  results.NSlips(j)=R.nSlips;results.TotalMagnitude(j)=R.totalSlipMagnitude;results.NStops(j)=R.nStops;
  results.MissingCentroids(j)=sum(any(~isfinite(R.mouseCentroids),2));
  results.FiniteSlipMetrics(j)=all(isfinite([R.nSlips,R.totalSlipMagnitude,R.slipEventAreas(:)',R.slipEventPeaks(:)',R.slipEventDurations(:)']));
  results.BaselineFallback(j)=contains(captured,'Locomotion baseline is insufficient');
  results.InvalidNormalization(j)=contains(captured,'Cannot normalize movement reliably');
  results.Status(j)="completed";
 catch ME
  results.Status(j)="error";results.Error(j)=string(getReport(ME,'extended','hyperlinks','off'));
 end
 results.Seconds(j)=toc(t); clear R; close all force
 fprintf('%s\n',captured);
 fprintf('RESULT status=%s slips=%g magnitude=%.8g finite=%d fallback=%d invalid=%d seconds=%.1f\n',results.Status(j),results.NSlips(j),results.TotalMagnitude(j),results.FiniteSlipMetrics(j),results.BaselineFallback(j),results.InvalidNormalization(j),results.Seconds(j));
 if results.Status(j)=="error",fprintf('%s\n',results.Error(j));end
 writetable(results,fullfile(outputDir,'validation.csv'));
end
fprintf('\nSUMMARY completed=%d errors=%d pending=%d nonfinite=%d fallback=%d invalid=%d\n',sum(results.Status=="completed"),sum(results.Status=="error"),sum(results.Status=="pending"),sum(results.Status=="completed" & ~results.FiniteSlipMetrics),sum(results.BaselineFallback),sum(results.InvalidNormalization));
end
