function runTailExamples
root='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106';
out='/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_examples_L40_20261109';
addpath(fullfile(root,'code_snapshot'));addpath(fullfile(out,'instrumentation'),'-begin');
setenv('TARA_TAIL_EXAMPLE_OUTPUT',out);
files={'TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4','TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4'};
src='/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved';
for j=1:2
 setenv('TARA_BEAM_CHECKPOINT',fullfile(out,[files{j} '.checkpoint.mat']));
 R=captureTailExample(src,files{j},'LOCOTHRESHOLD',40,'SLIPTHRESHOLD',2.5,'MOUSESIZETHRESHOLD',2,'EXCLUDE_STOPPING_FRAMES',false,'MAKEPLOT',false,'SHOWVIDEOS',false); %#ok<NASGU>
 clear R;close all
end
end
