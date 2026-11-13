# Height-cutoff comparison after excluding 2.5x MAD

User requested height sensitivity at stronger prominence thresholds. Same 12 trials,6 mice,5 cages; no production changes. Filter the exact saved5x and7.5x MATLAB peak sets at motion height<=0,+2.5,+5,+7.5,+10mm. Negative heights always accepted. Existing unblinded peak-frame visual labels are reused, not independent validation.

|Maximum height|5xMAD: below/all|7.5xMAD: below/all|
|---|---|---|
|0mm|22/22|18/18|
|+2.5mm|23/23|18/18|
|+5mm|24/24|18/18|
|+7.5mm|25/25|19/19|
|+10mm|25/27|19/20|

At5xMAD, relaxing0 to+7.5 recovers S09D14f1383(height+2.10),S04D14f1101(+3.38),S09D14f1259(+6.53), all visibly below. Relaxing to+10 adds S18D14f998(+8.63) and S04D14f1590(+8.74), visually above. At7.5xMAD only the S09f1259 below event and S04f1590 above event are eligible among these.

5xMAD plus<=+7.5mm retains six more visibly-below peaks than7.5xMAD plus<=+7.5mm in this sample. This is a provisional calibration candidate, selected on inspected data, not a validated optimum or proof of100% reliability. Single-frame below-tail labels do not establish distinct physical slips; recall remains unmeasured. The known low-prominence S08vertical-tail episode remains missed at both stronger thresholds. Dataset-wide detector/statistics/movies unchanged.

Machine-readable results: height_cutoff_sweep.csv in this canonical directory. Inputs: events.csv and new_candidate_visual_labels.csv, plus previously reviewed18 baseline gated events documented in parent review reports.

## User preference after review
User explicitly prioritizes avoiding false positives over avoiding false negatives. Keep7.5xMAD plus height<=+7.5mm as the more conservative candidate for further validation; do not adopt5x solely because it recovers more peaks. extra_5MAD_candidates_1.png shows the six peaks added by5x with the same height cutoff, all visually below in the current pilot. No production change authorized or performed.
