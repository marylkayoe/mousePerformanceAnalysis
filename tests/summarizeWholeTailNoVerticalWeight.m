% Summarize the exact raw whole-motion definition used in three-trace example.
o='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_no_vertical_weight_20261113';
prior='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_current_criteria_scatters_20261112';
for stem=["D0_first","D14_last"]
 S=readtable(fullfile(o,stem+'_summary.csv'),'TextType','string');assert(height(S)==42);means=nan(42,1);validFrames=zeros(42,1);
 for k=1:height(S)
  f=char(S.File(k));z=load(fullfile(o,'traces',[f '.mat']));old=load(fullfile(prior,'traces',[f '.mat']));
  assert(isequaln(z.normalized,old.normalized)&&isequaln(z.motionHeight,old.motionHeight)&&isequaln(z.invalid,old.invalid),'Existing trace parity failed');
  v=~z.invalid(:)&isfinite(z.wholeUnweighted(:));validFrames(k)=sum(v);assert(validFrames(k)>0);means(k)=mean(z.wholeUnweighted(v));
 end
 S.MeanWholeMotion=means;S.ValidFrames=validFrames;writetable(S,fullfile(o,stem+'_whole_summary.csv'));
end
