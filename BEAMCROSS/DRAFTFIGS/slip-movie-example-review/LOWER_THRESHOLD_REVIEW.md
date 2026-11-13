# Lower prominence and relaxed height gate pilot

12 trials, six mice, five cages. Same exact MATLAB findpeaks, masks, per-trial robust scale and minimum distance as prior tests. No production changes. Gate is height<=+10mm (includes all negative heights), not absolute distance<=10mm. Height remains the saved full-profile smoothed motion-weighted median.

|MAD multiplier|No height gate|Height<=0|Height<=+10mm|
|---|---:|---:|---:|
|7.5|22|18|20|
|5|56|22|27|
|2.5|195|22|37|

All 19 additional candidates relative to 7.5 plus height<=0 were inspected as lossless peak frames, verified against saved SHA256. Provisional unblinded single-agent labels:13 visibly below,3 visibly above,3 uncertain. These combine with the18 previously reviewed below-bar retained peaks. At5 plus<=10:25/27 visibly below,2 above. At2.5 plus<=10:31/37 visibly below,3 above,3 uncertain. At7.5 plus<=10:19/20 below,1 above. These are selected-peak visual fractions, not general sensitivity or physical-slip validation. Single-frame uncertainty must not be counted as absence. Repeated peaks can belong to the same episode.

2.5 plus<=10 recovers S08 D0T1 original1467 (3.069xMAD,height+6.761mm), during the previously missed vertical-tail episode. Additional clear low-prominence below-bar examples include S09 D0T4 f1382 and D14T2 f1409. Relaxation also admits clear above-bar examples S04 D14T2 f1590, S18 D14T1 f961 and998; ambiguous folded/occluded-tail frames remain. 5 plus<=10 is a reasonable intermediate candidate for further review; it still misses the S08 vertical episode. No final threshold selected.

Files: events.csv and counts.csv exact sweep; height_gate_counts.csv; new_candidates.csv; new_candidate_visual_labels.csv; four new_candidates_N.png sheets. Scripts tests/reviewLowerTailThresholds.m and tests/showLowerTailThresholdFrames.py. Persistent outputs are under /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_threshold_review_20261112/lower_thresholds. No bulk scratch or new video matrices saved.
