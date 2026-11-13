% Same frame eligibility and reference-speed scaling as six-example traces.
b='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_no_vertical_weight_20261113';o=fullfile(b,'per_crop_pixel/locomotion_scatters');if ~isfolder(o),mkdir(o);end
for stem=["D0_first","D14_last"]
 S=readtable(fullfile(b,'per_crop_pixel',stem+'_whole_summary.csv'),'TextType','string');n=height(S);means=nan(n,1);scaled=means;retained=zeros(n,1);valid=retained;
 for k=1:n
  f=char(S.File(k));z=load(fullfile(b,'traces',[f '.mat']));q=load(fullfile('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials',[f '.mat']),'C');C=q.C;
  assert(C.parameters.LOCOTHRESHOLD==40&&isequal(z.originalFrames(:),C.originalFrames(:)));v=C.forwardSpeeds(:);x=1000*z.wholeUnweighted(:)/S.CropPixels(k);ok=~z.invalid(:)&isfinite(x);keep=ok&~logical(C.stoppingFrames(:))&isfinite(v)&v>=40;assert(any(keep));
  means(k)=mean(x(keep));scaled(k)=mean(x(keep).*100./(v(keep)*700/1201));retained(k)=sum(keep);valid(k)=sum(ok);
 end
 S.LocomotingMean=means;S.SpeedScaledMean=scaled;S.RetainedFrames=retained;S.TailValidFrames=valid;S.RetainedFraction=retained./valid;writetable(S,fullfile(o,stem+'_summary.csv'));
end
