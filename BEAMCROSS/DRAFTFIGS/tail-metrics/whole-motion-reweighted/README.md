# Reweighted whole-range tail motion: exploratory group and time analysis

Source: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110`.
All 377 trial reconstructions passed. Whole-range row weights use the original
above-bar cubic ramp reaching 1 at bar top, 1 through beam-interior rows,
and a below-bar ramp from 1 to 2 at half-depth, then 2 to image bottom.
Destination-frame column probability weights, five-frame smoothing and per-trial
median/MAD normalization are unchanged. Beam-interior rows are included.
This is an image-motion index, not physical tail displacement or guaranteed
tail-specific movement; body, paws, background and crop movement can contribute.

This folder repeats the below-bar-reweighted workflow with new whole-motion
inputs. `cage_tests.py` is byte-identical. Frame masks and sample counts match
that analysis. Legacy pools all finite normalized samples within mouse/day,
weighting crossings by unmasked frame counts. Strict excludes invalid pairs
and uses the pre-replacement normalized value. Raw pools unsmoothed raw weighted
motion over valid pairs. Legacy includes 443 invalid pairs not marked tail-bad.
There are 42 mice (12 sedentary, 12 walk, 18 run), 15 cages (4, 4, 7), and
126 mouse-day summaries; one runner has only two D0 crossings.

Exact cage-label permutation tests are stratified by cohort, preserving group
counts within cohort. Pairwise tests use cohort-balanced cage contrasts; Holm
correction is across the three pairs separately for each outcome and period.
Overall p values are unadjusted. There is no joint adjustment across days,
change periods, outcomes or alternative metrics. Within-group change tests use
exact cage-level sign flips, Holm-adjusted across groups within each period.
This is exploratory, not a new preregistered analysis or a fully specified
repeated-measures model. The weighting revision followed inspection of the
measurement/debug movies. Interpretation must acknowledge that history.

## Results and sensitivity

For the normalized Legacy outcome, D14 overall p = 0.0188; the run-sedentary
and run-walk pairwise Holm p values are both 0.0714. D14-D0 change overall
p = 0.0154; run-sedentary raw p = 0.00794 and Holm p = 0.0238. The normalized
mean increased in sedentary mice and decreased in runners. Strict-mask results
are similar (change overall p = 0.0161, run-sedentary Holm p = 0.0238).

Raw motion does not show the same pattern: D14-D0 overall p = 0.1623 and
run-sedentary Holm p = 0.1429; the raw mean change is larger in runners.
Within-trial MAD-normalized averages describe motion relative to each trial's
own baseline and variability; they must not be interpreted as absolute motion
amounts. The normalized finding is not supported as an absolute-motion decrease.

## Files and reproduction

`whole-motion-reweighted-days-and-change.svg/.png/.fig` repeats the original
four-panel layout: D0, D7, D14 and within-mouse D14-D0. Circles are mice,
diamonds cage means, horizontal bars mouse means. Original axis limits and
random jitter seed are retained; no values fall outside those limits.
The FIG is saved visible, in a normal window with a recenter-on-open callback.

`trial-values.csv`, `mouse-day-values.csv`, `descriptive.csv`,
`group-comparisons.csv`, `within-group-time-exploratory.csv` retain the detailed
results, counts and original filenames. `validation.json` records checks.
Run `python3 analyze.py`, then `plot_whole_reweighted.m` in MATLAB R2024b.
Source traces remain on ShosaiData; no video matrices or bulk profiles are copied.
The below-bar folder and previous statistical analyses remain unchanged.
