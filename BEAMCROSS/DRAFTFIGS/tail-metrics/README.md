# Above-bar tail motion by position

Exploratory, descriptive profiles from the Mac mini L40 rerun archive. The
plotted quantity is `TailAboveBar`, the existing frame-level above-bar tail
motion trace, normalized within each crossing by that algorithm's median and
MAD. It is an index in arbitrary units, not physical tail displacement. The
negative values represent below-median normalized motion, not negative movement.
The x coordinate is the mouse centroid, not the tail tip or the place in the
image where the motion occurred. Crop motion and non-tail image changes may
contribute. Original reference exports contained scalar tail-trace placeholders;
although the rerun scalar metrics matched, frame-level traces lack independent
reference validation.

Coordinates use the entry-right common camera-field fraction and the approximate
tape centers at pixels 42 and 1243 from a single calibration video. The axis
is 0 mm at the exit-side mark to 700 mm at the entry-side mark. Plots place
entry on the right, matching the slip/stop position plots; the current
posture/speed trajectory files have a reversed displayed x-axis. The common
position is not a trial-specific tape calibration.

D0 and D14 use 250 direction-consistent validated crossings: sedentary 36,
walk 36, run 52 on D0; sedentary 36, walk 36, run 54 on D14. All 42 mice
contribute at least somewhere. One D0 run crossing was excluded for inconsistent
entry direction and another was absent from the retained trial set. Finite
centroid and above-bar motion values within the tape marks are assigned to 10 mm
bins; the original tail bad-frame flags are excluded, not set to zero. Frames
within a stop are retained. First average the available frames in each trial
and position bin, then average available crossing means equally within each
mouse and position bin. Lines are means across mice; bands are across-mouse SEM.
More time spent in a bin gives that trial more frames in its
within-bin mean, but does not increase its weight across trials or mice.

Dashed lines indicate fewer than half the group's mice; at least two mice are
required to draw the trace or band. Positions with no line have insufficient
valid data, not zero movement. The region near the entry mark has especially
low coverage because tail crop frames are flagged invalid. Group counts in the
legend are total mice with any contribution, not the sample size at every bin;
`group-position-bin-summary.csv` records per-bin counts. No smoothing or
inference by position is applied. Positions are bins and not independent
replicates; the shading is descriptive and not a cage-aware group test.

`prepare_position_profiles.py` reads the frame traces and trial manifest from
`../analysis-data/`, and writes trial- and mouse-level bin data, frame counts
and group summaries; `plot_tail_position.m` writes PNG, FIG and SVG. CSV rows
preserve original complete trial filenames.

## Pooled histogram-style view

`tail-above-pooled-days-histogram-10mm` overlays D0 and D14 as bars in 10 mm
bins. Each bar is the mean of available mouse-level means across all groups,
not a count of tail movements or a sum of motion over time. Individual mice
have equal weight; therefore groups with more mice contribute more to the
pooled mean. The lower panel shows the number of contributing mice per bin;
all bins with valid data are shown. The position range without valid data is
blank, not zero. This is descriptive and does
not establish a group or day effect. `pool_tail_positions.py` and
`plot_pooled_tail_histogram.m` produce this view and its per-bin summary.

The D0 combined tail/slip/stop histogram uses 10 mm bins over 0–700 mm,
pooled groups and the same 124 eligible crossings. Tail bars show the mean of
available mouse-level tail indices and a separate panel shows contributing mice;
slip and stop bars are raw event counts. Slips overlapping any stop are omitted only for
this combined display; main slip counts retain those events. The tail profile
and event counts use different summaries and their bar heights are not
directly comparable. The side-by-side profiles are descriptive and do not
establish that tail motion precedes or predicts individual slips. See
`d0-pooled-tail-slips-stops-10mm.csv` and the associated prepare/plot scripts.

The `d0-pooled-tail-slips-stops-histograms-10mm-all-data` version displays every
bin with at least one valid mouse and adds a separate contributing-mouse panel.
In D0, the 620–630 mm bin has data from three mice and a negative mean index;
630–700 mm has no valid data. Negative normalized values mean below that
crossing's median signal, not negative physical motion.

## Example height of post-mouse motion

The earlier `example-motion-weighted-height-by-position-D14` showed the saved weighted
motion-height index for the selected TMCS3_S09 sedentary and TMCS2_S18 run
D14 trial-2 examples. Pale points are valid frame samples, and lines are
frame-weighted means within 10 mm centroid-position bins; stops are included.
Gaps remain where the index is invalid or the centroid falls outside the
calibrated tape span. The weighted height uses the original detected bar top
as zero, with the approximate horizontal calibration applied vertically.
This measures the height of image motion in the post-mouse crop, not the
stationary tail position; residual background, body/paw movement, moving
crops, and small nonzero motion may affect it. The individual debug videos
should be inspected before assigning a biological interpretation. The figure
exports, their dedicated frame-level CSV, and the old plotting scripts are no
longer retained; rerun frame traces remain available in the source archive.

The earlier unsmoothed `example-motion-weighted-height-by-time-D14` showed
the same two examples as frame-by-frame traces against elapsed time from the first tracked frame. It
uses encoded timestamps, includes the entire tracked crossing without a tape
position filter, and applies no spatial or temporal binning or smoothing.
Invalid measurements remain NaN gaps. The run panel uses the same 0–5.5 s
horizontal range as the sedentary panel, so the part after its crossing ends
is blank. Its figure exports are no longer retained; the frame-level CSV
preserves full source filenames, original frame numbers, stop masks and invalid flags.

The `example-motion-weighted-height-by-time-D14-5frame` variant applies a
centered five-frame moving mean separately within each contiguous run of valid
samples. Windows shrink at the edges of a valid run; invalid frames remain
gaps and are never bridged. At 160 frames/s, five frames span about 31 ms.
The saved frame-level CSV remains unchanged; the smoothed figure is retained.

## Exploratory near-bar exclusion

The earlier `example-motion-height-exclude-0to5mm-D14` compared the original height index
with a version recomputed from probability-weighted image-motion rows after
removing rows from the detected bar top up to, but not including, 5 mm above
it. Its figure exports are no longer retained; the comparison CSV remains.
This is an illustrative threshold, not a validated hind-paw mask. Motion
below the bar and 5 mm or higher remains included. The weighted mean is
recomputed using the remaining rows for each frame; the existing invalid-pair
mask remains in force, and a frame with no remaining motion weight is NaN.
A centered five-frame mean is applied separately within each run of valid
frames. The two original profile MAT files are preserved under
`example-row-profiles/`, with original filenames, for reproducibility.

## Presentation focus and running-example tracking movie

The main presentation focuses on **above-bar tail motion**; the exploratory
below-bar analysis is retained in `below-bar-reweighted/`. The earlier
runner-specific debug movie versions and their one-off rendering scripts have
been removed. The current local movie with legend is produced by the reusable
renderer described below. The earlier mean-versus-median example data remain
in `run-example-mean-median-motion-height.csv`.

### Example sensitivity to excluding the near-bar band

`compare_weighted_median_exclude_5mm.m` uses the same original per-row motion
profiles and frame validity for the two example crossings. It recalculates
weighted means and medians after excluding rows from 0 to <5 mm above the bar;
below-bar rows remain included. It writes frame values, a descriptive summary,
and formerly `example-median-height-exclude-0to5mm-D14` figures (PNG, FIG, SVG;
no longer retained). The
curves use a centered five-frame mean within each valid segment; the summary
compares unsmoothed paired frames. Frame-level values are not independent mice.
The sedentary example has previously observed tracking problems, so it is not
evidence of a group effect. The earlier comparison movie and its one-off
rendering script are no longer retained; the frame-level comparisons remain.

Decision: retain the full row profile for the weighted-median motion-height
demo, without excluding the 0 to <5 mm band. In the runner example the
overall shift from blanking was small, though individual frames can differ,
particularly when little tail motion is visible and near-bar motion contributes.
This is a decision based on example crossings, not a validation across the
dataset. The marker measures the height of detected motion, so a largely still
tail can sit higher than the marker; near-bar movement may include a hind paw.

For the three-day presentation movies, the preferred visual uses a single
green/red display scale shared across D0, D7 and D14 for each mouse. In the
runner example, the earlier trial-specific display scale magnified equal raw
contributions on D14 by 4.11 times relative to D7; a small visual audit found
similar raw below-bar background contributions despite the noisier-looking D14
trace. These video curves are weighted spatial image-difference profiles,
not the trial-specific MAD-normalized scalar time series used in the existing
tail analysis. The shareable comparison videos are on Proton Drive; Mac mini's
newer generation code and detailed audit files require a separate status check.

### Reusable debug-video renderer

`BEAMCROSS/createTailMetricsDebugVideo.m` renders the median/scale-bar movie
from a trial's lossless crop and validated per-column export plus its saved
row-profile MAT. It checks original trial names, frames, masks, bar geometry,
dimensions, prior numerical validation and every lossless crop frame hash.
The rendered crop includes an in-image legend for above-bar motion (green),
corrected below-bar motion (red), motion by height (purple), and the smoothed
weighted-median motion height (black). Invalid or unusable frame pairs are
marked by a red cross at the upper right. The local runner demo with legend is
`TMCS2_S18-D14-trial2-tail-position-median-legend.mp4` (ignored by Git).
For the runner example, from the repository root in MATLAB:

```matlab
addpath('BEAMCROSS');
createTailMetricsDebugVideo( ...
  'BEAMCROSS/results/running_column_export_L40_halfdepth_20261109', ...
  'BEAMCROSS/DRAFTFIGS/tail-metrics/example-row-profiles/TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4.profiles.mat', ...
  'runner-debug-new.mp4');
```

Optional name-value arguments include `MillimetersPerPixel`, `PlaybackFPS`,
`ScaleBarMM`, `DisplayScale`, and `DisplaySpatialWindow`. Defaults are
700/1201, 30, 20, 2, and 1 (no spatial smoothing). Setting
`DisplaySpatialWindow=5` applies a centered five-source-column moving mean to
both the green and red curves for display only, keeping the original shared
display scale. It does not smooth in time or alter the row profile, median
marker, measurements, or analysis. It can soften narrow spatial peaks. The
local runner example is `TMCS2_S18-D14-trial2-tail-position-median-legend-spatial5.mp4`.
The renderer needs MATLAB, Python 3, FFmpeg, and macOS Core Text/clang. It
refuses to overwrite the output. The scalar traces and row profiles alone
cannot provide the per-column overlays or background video: those require a
separate validated, trial-matched crop/column export. Generalized preparation is
now available through `BEAMCROSS/createTailMetricsDebugForTrial.m`; see
`BEAMCROSS/TAIL_METRICS_WORKFLOW.md` for reconstruction checks, two-trial validation
and current limits. Per-trial row profiles are stored
in the original external rerun results rather than the smaller reweighting
copy in this repository.

### Combined shareable dataset

The original full rerun is archived in Proton Drive `WORK/DATA` as
`Tara_balance_beam_L40_events_traces_row_profiles_20261106.zip`; its canonical
Mac mini results are under `/Volumes/ShosaiData/DATA/Tara/RESULTS/` in
`balance_beam_events_traces_L40_20261106`. A combined MATLAB v7.3 file,
`Tara_balance_beam_combined_results_L40_20261109.mat`, was created in the
same Proton Drive folder with `BEAMCROSS/createTaraBeamDataset.m`. Its one
variable `dataset` contains the trial structure, saved row profiles,
and corrected-below results for each of 377 trials, along with the manifest,
original dataset index, methods and validation text. The frame identifiers,
times and masks were cross-checked when joining the source files and checked
again after reading the output. Superseded below-bar traces, derived summaries,
old weights, and reference-comparison values are omitted from this shareable
file. Raw row profiles and the original source archive remain intact. File SHA-256:
`24a0b824e8b4cbacdd2890076cc9fb258354b30b36df052647f2d7abf629186e`.
Neither original video frames nor the per-column data required by the debug
movie were present in the complete rerun; the weighted-median estimates used
in the examples have not been calculated dataset-wide. They are not claimed
to be included. The original source archive and reweighting files are retained.

### Exploratory motion-height metrics

`height-exploratory/` contains median-height statistics figures, trial and
mouse-day measures, cage-aware exploratory comparisons, code and definitions.
It summarizes both typical weighted-median motion height and its within-crossing
spread. These newly derived summaries are not yet in the consolidated dataset;
the folder's README records the follow-up to add them after review.
