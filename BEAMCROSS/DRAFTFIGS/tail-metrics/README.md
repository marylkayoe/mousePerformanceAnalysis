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
mouse and position bin. Lines are means across mice; bands are across-mouse SD
or SEM as labeled. More time spent in a bin gives that trial more frames in its
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

`example-motion-weighted-height-by-position-D14` shows the saved weighted
motion-height index for the selected TMCS3_S09 sedentary and TMCS2_S18 run
D14 trial-2 examples. Pale points are valid frame samples, and lines are
frame-weighted means within 10 mm centroid-position bins; stops are included.
Gaps remain where the index is invalid or the centroid falls outside the
calibrated tape span. The weighted height uses the original detected bar top
as zero, with the approximate horizontal calibration applied vertically.
This measures the height of image motion in the post-mouse crop, not the
stationary tail position; residual background, body/paw movement, moving
crops, and small nonzero motion may affect it. The individual debug videos
should be inspected before assigning a biological interpretation. Frame-level
values, original filenames, and original frame numbers are in
`example-motion-height-frames.csv`; the accompanying prepare and plot scripts
read the saved rerun frame traces and reproduce the figure.

`example-motion-weighted-height-by-time-D14` shows the same two examples as
frame-by-frame traces against elapsed time from the first tracked frame. It
uses encoded timestamps, includes the entire tracked crossing without a tape
position filter, and applies no spatial or temporal binning or smoothing.
Invalid measurements remain NaN gaps. The run panel uses the same 0–5.5 s
horizontal range as the sedentary panel, so the part after its crossing ends
is blank. The frame-level CSV preserves full source filenames, original frame
numbers, stop masks and invalid flags.

The `example-motion-weighted-height-by-time-D14-5frame` variant applies a
centered five-frame moving mean separately within each contiguous run of valid
samples. Windows shrink at the edges of a valid run; invalid frames remain
gaps and are never bridged. At 160 frames/s, five frames span about 31 ms.
The saved frame-level CSV and the unsmoothed figure remain unchanged.

## Exploratory near-bar exclusion

`example-motion-height-exclude-0to5mm-D14` compares the original height index
with a version recomputed from probability-weighted image-motion rows after
removing rows from the detected bar top up to, but not including, 5 mm above
it. This is an illustrative threshold, not a validated hind-paw mask. Motion
below the bar and 5 mm or higher remains included. The weighted mean is
recomputed using the remaining rows for each frame; the existing invalid-pair
mask remains in force, and a frame with no remaining motion weight is NaN.
A centered five-frame mean is applied separately within each run of valid
frames. The two original profile MAT files are preserved under
`example-row-profiles/`, with original filenames, for reproducibility.

## Run debug video with motion-height trace

`TMCS2_S18-D14-trial2-tail-debug-with-motion-height.mp4` appends a graph of
the five-frame-smoothed motion-weighted height to the existing 678-frame run
debug video. The red cursor marks the current frame and its height; when the
height is invalid, the cursor moves without a point. The graph uses elapsed
source time from the start of the tracked crossing, whereas the debug video
plays at 30 fps for inspection (source frame rate 160 fps). Original frame
numbers appear in the source debug panel. The output retains the existing
L40 debug weighting panels, whose under-bar weighting is under review; the
height trace is the separate saved probability-weighted row-motion height,
not the green/red visualization in that panel. Frame counts and original-frame
mapping were verified. `plot_run_motion_height_video_panel.m` and
`render_run_debug_with_height.py` produce the video from the saved trace and
repository debug MP4. The repository ignores new MP4 files by default, so the
video is a local output unless explicitly added to Git.

## Presentation focus and running-example tracking movie

The user chose to retain **above-bar tail motion** as the focus for the main
presentation after the exploratory below-bar reweighting analysis. The
below-bar group/day analysis remains available in `below-bar-reweighted/`.

`TMCS2_S18-D14-trial2-tail-tracking-demo-corrected.mp4` is a local draft
single-panel tracking illustration, using the verified lossless running crop
and synchronized per-column export in
`../../results/running_column_export_L40_halfdepth_20261109/`. The green and
red curves show unchanged above-bar and corrected below-bar weighted column
contributions on a single fixed scale; they are raw per-frame profiles, not
independently normalized indices. Purple is the probability-weighted motion
by image row without an added vertical ramp. The black tick and numeric value
show the unsmoothed probability-weighted mean height relative to the detected
bar top using 700/1201 mm/pixel. Flagged invalid pairs show no profiles or
height. The 678-frame video plays at 30 fps; source frames 685–1362 correspond
to the 160 fps source. All corrected below-bar column sums were checked
against NewBelowRaw, and each valid height was checked against the saved index.
The MP4 is ignored by Git by default. To regenerate it, run
`prepare_run_tracking_demo.m` in MATLAB, then
`python3 render_run_tracking_demo.py`; this uses two small files in the system
temporary directory and the repository's example row-profile MAT and export.


The revised local movie `TMCS2_S18-D14-trial2-tail-tracking-overlay-5frame.mp4`
places all overlays on the crop: purple extends left from the right edge, and
the corrected red profile is anchored to the bottom of the detected bar. The
black marker and numeric height use a centered five-frame moving mean within
contiguous valid segments; the purple profile remains instantaneous, so the two
need not coincide exactly. Invalid pairs are marked with a red cross. The
height describes weighted motion, not a tracked anatomical tail point. For
reproduction, run `prepare_run_tracking_overlay.m`, then
`python3 render_run_tracking_overlay.py`. The MP4 is ignored by Git.

`TMCS2_S18-D14-trial2-tail-tracking-mean-vs-median-5frame.mp4` compares
the original weighted mean (black) with the weighted median (orange). Both
use the same full-height, probability-weighted row motion profile; the median
is the first row, scanning from high to low, whose cumulative motion reaches
half the total. Both markers and displayed numbers use a centered five-frame
mean within contiguous valid segments. The accompanying
`run-example-mean-median-motion-height.csv` contains the unsmoothed and
smoothed estimates, including missing values for invalid frames. Run
`prepare_run_tracking_overlay.m` then `python3 render_run_tracking_mean_median.py`
to reproduce the comparison; the MP4 remains ignored by Git.

`TMCS2_S18-D14-trial2-tail-position-weighted-median.mp4` is the median-only
presentation version. The marker and label use the same five-frame smoothed
weighted median as the comparison; below-bar values are labeled accordingly.
The label is a shorthand for the position of weighted motion, rather than an
anatomically tracked tail point. Run `prepare_run_tracking_overlay.m` and then
`python3 render_run_tracking_median_only.py`; the renderer compiles the macOS
Core Text helper `render_tail_label.c` to create the conventional text overlay.
The MP4 is a local output ignored by Git.

`TMCS2_S18-D14-trial2-tail-position-median-scalebar.mp4` crops the presentation
to the video image, removes the changing numeric readout, and adds a vertical
20 mm scale bar below the beam. Its length uses the approximate 700/1201
mm/pixel calibration and is rounded to the nearest displayed pixel. The black
marker still shows the five-frame-smoothed weighted median motion height.
Generate it with `prepare_run_tracking_overlay.m` followed by
`python3 render_run_tracking_median_scalebar.py`; the movie is ignored by Git.

### Example sensitivity to excluding the near-bar band

`compare_weighted_median_exclude_5mm.m` uses the same original per-row motion
profiles and frame validity for the two example crossings. It recalculates
weighted means and medians after excluding rows from 0 to <5 mm above the bar;
below-bar rows remain included. It writes frame values, a descriptive summary,
and `example-median-height-exclude-0to5mm-D14` figures (PNG, FIG, SVG). The
curves use a centered five-frame mean within each valid segment; the summary
compares unsmoothed paired frames. Frame-level values are not independent mice.
The sedentary example has previously observed tracking problems, so it is not
evidence of a group effect. `render_run_median_exclude_5mm.py` produces the
local ignored comparison movie after running the MATLAB script and
`prepare_run_tracking_overlay.m`: black is all rows, orange excludes the band,
and the purple trace still shows the original unblanked profile.

Decision: retain the full row profile for the weighted-median motion-height
demo, without excluding the 0 to <5 mm band. In the runner example the
overall shift from blanking was small, though individual frames can differ,
particularly when little tail motion is visible and near-bar motion contributes.
This is a decision based on example crossings, not a validation across the
dataset. The marker measures the height of detected motion, so a largely still
tail can sit higher than the marker; near-bar movement may include a hind paw.

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
`ScaleBarMM`, and `DisplayScale`. Defaults are 700/1201, 30, 20, and 2.
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
