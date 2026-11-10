# Exploratory height of detected post-mouse motion

This exploratory analysis describes the **vertical location of detected image
motion**, not a tracked tail point or stationary-tail height. Paw/body motion,
low-level background, movement of the crop and varying tail visibility can
contribute. Zero is the detected bar top. The approximate horizontal tape-mark
calibration (700/1201 mm per source pixel) is also used vertically. The
analysis retains the entire tracked crossing, including stops and regions outside
the tape marks; it makes no 0–5 mm blank. This is consistent with the selected
runner demonstration, but that example does not validate every trial.

## Quantities and averaging

For each valid frame, find the weighted median height across all image rows,
using saved `P.probabilityWeighted` as weights, scanning high to low and taking
the first row where cumulative weight reaches 50%. This is a median across
height *within* a frame. Smooth that per-frame trajectory with a centered
five-frame moving mean within contiguous valid segments, shrinking at segment
edges and never bridging invalid frames. For each crossing, calculate the mean,
median, SD and IQR across its valid smoothed frame heights. The SD and IQR
measure the spread of detected motion heights within a crossing; neither is a
speed, frequency or direct measure of anatomical tail movements. As a separate
sensitivity quantity, `meanWeightedMeanHeight` averages the original per-frame
weighted **mean** heights (without the five-frame median smoothing).

Each available crossing contributes equally to its mouse-day mean, then each
mouse equally to plotted group means and SEM. Paired D7−D0 and D14−D0 changes
are computed per mouse. Thus meanHeight is the mean over time of the per-frame
weighted medians, not the weighted mean across image rows. `medianHeight` is
the median over time of those per-frame weighted medians. `sdHeight` and
`iqrHeight` are within-crossing measures averaged across crossings per mouse.
Original full filenames, day, cage and mouse identifiers are preserved.

There are 377 crossings from 42 mice, 15 cages (sedentary: 12 mice, 4 cages;
walk: 12 mice, 4 cages; run: 18 mice, 7 cages). One run mouse has two rather
than three retained D0 crossings; all other mouse-days have three. Of 388,616
frames, 84,078 invalid frame pairs and 14 zero-motion frames were excluded,
leaving 304,524 valid samples; no additional finite valid profile failed the
nonfinite check. Valid fractions ranged 0.558–0.913 by trial (median 0.805);
D14 pooled valid fractions were 0.794, 0.793 and 0.796 in sedentary, walk and
run. This does not establish that missingness is behaviorally neutral.

## Exploratory cage-aware comparisons

Cage means are tested with the existing exact cage-label permutation procedure
within cohort. Its validity depends on cage-label exchangeability within each
cohort; whether randomization was explicitly stratified by cohort is not
established. The two-cohort pairwise effect is equally weighted across cohorts
and can differ from the difference of mouse-weighted group means in the figure.
Two-sided pairwise p-values are Holm-adjusted across the three group pairs
**within each metric and each day/change**, not across metrics or periods. These
are exploratory analyses across several correlated measures and time points;
threshold-crossing results should not be treated as confirmatory.

For meanHeight, mouse-weighted mean D7−D0 changes were +0.04 mm sedentary,
−7.27 mm walk, and −5.82 mm run. The group omnibus p=0.00075; run−sedentary
cohort-balanced difference −5.52 mm, raw p=0.00794, Holm p=0.02381. All seven
run cage means changed downward, but this observation does not prove the source
is tail posture or treatment. By D14 the mean heights were 31.82, 31.05 and
31.01 mm, respectively; D14−D0 omnibus p=0.245. The medianHeight measure shows
similar D7−D0 behavior (omnibus p=0.00194). D0 differences and the post-hoc,
multiple-metric nature matter for interpretation.

For sdHeight on D14, the mouse group means were 18.75, 18.22, 16.69 mm
(sedentary, walk, run); omnibus p=0.0279, run−sedentary cohort-balanced
contrast −2.23 mm, raw p=0.01587, Holm p=0.04762. D14−D0 omnibus p=0.300,
and the robust IQR on D14 has omnibus p=0.385, so this is a tentative finding,
not strong evidence of a treatment-specific change in tail motion variability.

## Outputs and reproduction

The earlier `motion-height-group-day` and `motion-height-d14-minus-d0` figure
exports are no longer retained; their underlying trial and mouse-day data remain.
The first showed mouse trajectories and group mean ± SEM; the second showed
paired change with mouse points, cage means and mouse means.
`trial-motion-height.csv`, `mouse-day-motion-height.csv`, `descriptive.csv`,
and `group-comparisons.csv` hold the values and tests. Regenerate with
`extract_tail_height(datasetFile)` in MATLAB, then `python3 analyze_tail_height.py`
and `plot_tail_height` in MATLAB if those figures are needed again. Do not load
and overwrite the source dataset.

`median-motion-height-statistics` follows the posture and slip statistics
layout: D0, D7, D14 and paired D14−D0 panels; mouse circles, cage diamonds and
mouse-mean bars, with overall, raw-pair and Holm-adjusted p-values. The separate
`median-motion-height-D07-minus-D00-statistics` shows the paired D7−D0
contrast of exploratory interest. Both are saved as PNG, FIG and SVG and
regenerated by `plot_median_height_statistics.m`. These plots use `medianHeight`,
the within-crossing median of the smoothed per-frame weighted-median motion
heights, averaged across each mouse's crossings.

**Follow-up:** after reviewing the definitions and results with the user, add
these newly calculated frame-level weighted-median trajectories and/or
trial-level/mouse-day summaries to the combined Proton Drive MATLAB dataset.
The current combined file has the input row profiles, but does not yet contain
these new height summaries. Any update should be validated and preserve the
existing original data and invalid masks.

## Candidate debug-video examples

`select_debug_examples.py` ranks mice within each group by their root-mean-
square distance from the group's mouse-weighted mean trajectory of meanHeight
at D0, D7 and D14. Mice must have three available crossings on each day.
For the top-ranked mouse, one crossing per day is selected by closeness of its
meanHeight to that mouse's daily mean (ties resolved by full filename). This
does not select on video appearance or variability, and does not make the
selected mice representative of other metrics, groups, or all cages. Selection
and candidate rankings are in `debug-example-trials.csv` and
`debug-example-mice-ranking.csv`. These inputs require independent video QA.
The runner's already displayed D14 trial 2 is useful for continuity but trial 1
is closer to its D14 mouse mean. The earlier sedentary debug-video export was
corrupted; regenerate from the verified source rather than using that movie.
