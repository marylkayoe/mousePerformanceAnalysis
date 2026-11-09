function checkEntranceNumerics
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
out='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_entry_review_20261107';
addpath(fullfile(root,'code_snapshot'));
M=readtable(fullfile(out,'D0_entry_exposure_by_trial.csv'),'TextType','string');
M.DetectedBarTop=zeros(height(M),1);M.DetectedBarThickness=M.DetectedBarTop;
M.DetectorFirstOriginalRow=M.DetectedBarTop;M.DetectorLastOriginalRow=M.DetectedBarTop;
for i=1:height(M)
 S=load(fullfile(root,'trials',[char(M.File(i)) '.mat']),'C');C=S.C;
 M.DetectedBarTop(i)=C.barTopCoordOriginal;M.DetectedBarThickness(i)=C.barThickness;
 M.DetectorFirstOriginalRow(i)=round(C.barTopCoordAnalysis+C.barThickness/2)+3+C.cropRange(1)-1;
 M.DetectorLastOriginalRow(i)=round(C.barTopCoordAnalysis+C.barThickness*1.5)+3+C.cropRange(1)-1;
end
writetable(M,fullfile(out,'detector_geometry.csv'));
S=load(fullfile(root,'trials','TMCS3_S07_T1_C03_BB_D00_20260219_THT_TRIAL4_gray.mp4.mat'),'C');C=S.C;
% Isolate speed/smoothing numerical behavior; synthetic positive raw motion is NOT a biological rerun.
speed=C.forwardSpeeds(:);z=log1p(speed);z(z<0)=eps;
syntheticRaw=ones(size(speed));scaled=syntheticRaw.*(160./z);smoothed=smooth(scaled,10);
baseline=smoothed(isfinite(smoothed)&~C.stoppingFrames(:));med=median(baseline);sigma=1.4826*median(abs(baseline-med));
normalized=(smoothed-med)/sigma;normalized(normalized<0)=0;normalized(isnan(normalized))=0;
T=table(C.originalFrames(:),speed,C.movementTrace(:),scaled,smoothed,normalized,'VariableNames',{'OriginalFrame','SavedForwardSpeed','SavedMovementTrace','SyntheticSpeedScaledMotion','SyntheticSmoothedMotion','SyntheticNormalizedMotion'});
writetable(T(T.OriginalFrame>=1720&T.OriginalFrame<=1895,:),fullfile(out,'zero_speed_diagnostic.csv'));
D=struct('method','Synthetic raw motion=1; saved actual speeds and stop mask; unchanged speed scaling, smooth(...,10), finite non-stop MAD baseline and NaN-to-zero behavior. Not a rerun or replacement for original trace.',...
 'syntheticInvalidSmoothedFrames',C.originalFrames(~isfinite(smoothed)),...
 'targetParameters',C.parameters,'barTop',C.barTopCoordOriginal,'barThickness',C.barThickness);
fid=fopen(fullfile(out,'zero_speed_diagnostic.json'),'w');fprintf(fid,'%s',jsonencode(D));fclose(fid);
disp(T(T.OriginalFrame>=1753&T.OriginalFrame<=1781,:));
end
