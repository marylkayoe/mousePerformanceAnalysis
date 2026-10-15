function compareStoppingFrameExclusion(outputDir)
% Compare paired stop-exclusion settings on a reproducible random video sample.
% Saves scalar results and static plots only; no video matrices are retained.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoRoot));
set(groot, 'defaultFigureVisible', 'off');
dataPath = '/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
files = dir(fullfile(dataPath, '*.mp4'));
[~, order] = sort({files.name}); files = files(order);
rng(20261015, 'twister');
files = files(randperm(numel(files), min(12, numel(files))));
n = numel(files);
results = table(repelem(string({files.name})',2), repmat([false;true],n,1), ...
    nan(2*n,1),nan(2*n,1),nan(2*n,1),nan(2*n,1),nan(2*n,1), ...
    strings(2*n,1), 'VariableNames', {'File','ExcludeStops','NSlips','TotalMagnitude','NStops','StopFrames','OverlappingEvents','Error'});
writetable(results,fullfile(outputDir,'comparison.csv'));
for r = 1:height(results)
    checkResources();
    fprintf('\nRUN %d/%d %s exclude=%d\n',r,height(results),results.File(r),results.ExcludeStops(r));
    try
        R = BBanalysisSingleFile(dataPath,char(results.File(r)), ...
            'MOUSESIZETHRESHOLD',2,'SLIPTHRESHOLD',2.5,'LOCOTHRESHOLD',150, ...
            'EXCLUDE_STOPPING_FRAMES',results.ExcludeStops(r),'MAKEPLOT',false,'SHOWVIDEOS',false);
        assert(isstruct(R),'Analysis returned a non-struct result.');
        stopMask = false(numel(R.forwardSpeeds),1);
        if R.nStops > 0
            for s=1:size(R.stoppingStartStops,1)
                stopMask(R.stoppingStartStops(s,1):R.stoppingStartStops(s,2))=true;
            end
        end
        overlaps=0;
        for s=1:R.nSlips
            inds=R.slipEventStarts(s)+(0:R.slipEventDurations(s)-1);
            overlaps=overlaps+any(stopMask(inds));
        end
        results{r,3:7}=[R.nSlips,R.totalSlipMagnitude,R.nStops,sum(stopMask),overlaps];
        fprintf('RESULT slips=%d magnitude=%.6g stops=%d overlap=%d\n',R.nSlips,R.totalSlipMagnitude,R.nStops,overlaps);
        clear R
    catch ME
        results.Error(r)=string(getReport(ME,'extended','hyperlinks','off'));
        fprintf('FAIL %s\n',results.Error(r));
        clear R
    end
    close all force
    writetable(results,fullfile(outputDir,'comparison.csv'));
end
included=results(1:2:end,:); excluded=results(2:2:end,:);
valid=included.Error=="" & excluded.Error=="" & isfinite(included.TotalMagnitude) & isfinite(excluded.TotalMagnitude);
A=included(valid,:); B=excluded(valid,:);
f=figure('Color','w','Position',[100 100 1300 850],'Visible','off');
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
c1=[0.1 0.4 0.75]; c2=[0.85 0.3 0.1];
nexttile; hold on
for j=1:height(A)
    plot([A.NSlips(j),B.NSlips(j)],[A.TotalMagnitude(j),B.TotalMagnitude(j)],'-','Color',[.75 .75 .75],'HandleVisibility','off');
end
scatter(A.NSlips,A.TotalMagnitude,55,c1,'filled','DisplayName','Include stops (false)');
scatter(B.NSlips,B.TotalMagnitude,55,c2,'filled','DisplayName','Exclude stops (true)');
xlabel('Slip count'); ylabel('Total slip magnitude (normalized score sum)');
title('Paired outcomes: lines connect the same video'); legend('Location','best'); grid on
nexttile; hold on
scatter(A.NSlips,B.NSlips,65,c1,'filled');
lim=max([A.NSlips;B.NSlips;1])*1.1; plot([0 lim],[0 lim],'k--'); xlim([0 lim]); ylim([0 lim]); axis square
xlabel('Slip count: include stops'); ylabel('Slip count: exclude stops'); title('Slip counts (dashed line = equal)'); grid on
nexttile; hold on
scatter(A.TotalMagnitude,B.TotalMagnitude,65,c2,'filled');
lim=max([A.TotalMagnitude;B.TotalMagnitude;1])*1.1; plot([0 lim],[0 lim],'k--'); xlim([0 lim]); ylim([0 lim]); axis square
xlabel('Total magnitude: include stops'); ylabel('Total magnitude: exclude stops'); title('Slip magnitude (dashed line = equal)'); grid on
nexttile; hold on
plot([1 2],[A.TotalMagnitude B.TotalMagnitude]','-o','Color',[.65 .65 .65],'MarkerSize',4);
plot([1 2],[median(A.TotalMagnitude),median(B.TotalMagnitude)],'-o','Color',[.1 .1 .1],'LineWidth',3,'MarkerSize',8);
xlim([.7 2.3]); xticks([1 2]); xticklabels({'Include stops','Exclude stops'}); ylabel('Total slip magnitude'); title('Paired magnitudes; black = sample median'); grid on
sgtitle(sprintf('Stop exclusion comparison | %d/%d paired videos | LOCOTHRESHOLD 150, SLIPTHRESHOLD 2.5',height(A),n));
exportgraphics(f,fullfile(outputDir,'comparison.png'),'Resolution',160);
exportgraphics(f,fullfile(outputDir,'comparison.pdf'),'ContentType','vector');
close(f)
fid=fopen(fullfile(outputDir,'README.txt'),'w');
fprintf(fid,'Source: %s\nMATLAB: %s\nSeed: 20261015 (twister), random sample of %d files.\nThresholds: mouse area 2; slip 2.5; locomotion 150.\nOnly EXCLUDE_STOPPING_FRAMES differs within pairs.\nPlots use %d complete finite pairs. Lines connect the same video.\nMagnitudes are sums of normalized scores above threshold, not physical displacement.\nStop suppression precedes smoothing/normalization; differences are not limited to stopping frames.\nNo video matrices saved. comparison.csv includes errors, if any.\n',dataPath,version,n,height(A));
fclose(fid);
plotStoppingFrameComparison(outputDir);
fprintf('\nSUMMARY paired=%d/%d countMedian=%.3g/%.3g magnitudeMedian=%.6g/%.6g\n',height(A),n,median(A.NSlips),median(B.NSlips),median(A.TotalMagnitude),median(B.TotalMagnitude));
disp(results(:,1:7));
end

function checkResources()
[~,diskInfo]=system('df -k /System/Volumes/Data');
lines=splitlines(strtrim(diskInfo)); parts=strsplit(strtrim(lines{end}));
availGiB=str2double(parts{4})/1024^2;
[~,swapInfo]=system('sysctl vm.swapusage');
tok=regexp(swapInfo,'used = ([0-9.]+)M','tokens','once');
fprintf('Resources: free disk %.2f GiB; %s',availGiB,swapInfo);
assert(availGiB>=20,'Internal disk space below 20 GiB; stopping.');
assert(~isempty(tok),'Could not inspect swap use; stopping.');
assert(str2double(tok{1})<=8192,'Swap exceeds 8 GiB; stopping.');
end
