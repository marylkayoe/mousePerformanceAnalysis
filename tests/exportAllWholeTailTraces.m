b='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_no_vertical_weight_20261113';o=fullfile(b,'per_crop_pixel/all_mouse_traces');if ~isfolder(o),mkdir(o);end
T=table();
for stem=["D0_first","D14_last"]
 S=readtable(fullfile(b,'per_crop_pixel',stem+'_whole_summary.csv'),'TextType','string');
 for k=1:height(S)
  f=char(S.File(k));z=load(fullfile(b,'traces',[f '.mat']));q=load(fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials',[f '.mat']),'C');C=q.C;assert(isequal(z.originalFrames(:),C.originalFrames(:)));v=C.forwardSpeeds(:);x=1000*z.wholeUnweighted(:)/S.CropPixels(k);keep=~z.invalid(:)&isfinite(x)&~logical(C.stoppingFrames(:))&isfinite(v)&v>=40;n=numel(x);
  A=table(repmat(string(f),n,1),repmat(stem,n,1),z.originalFrames(:),(0:n-1)'/160,x,keep,'VariableNames',{'File','Selection','OriginalFrame','TimeSeconds','MotionPerPixelTimes1000','Keep'});T=[T;A];
 end
end
writetable(T,fullfile(o,'all_traces.csv'));
