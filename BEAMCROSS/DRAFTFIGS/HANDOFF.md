# Balance-beam figure handoff

> **Current figure update (2026-11-11):** Read [FIGURE_HANDOFF_20261111.md](FIGURE_HANDOFF_20261111.md) first for the current Illustrator panel map, corrected whole-tail definitions, paired-change presentation, statistics, alternatives and unresolved checks. The historical notes below remain useful but some presentation choices are superseded.

This is Tara's project. The main paper is about IO; the intended main-figure
behavioral comparison is baseline D0 versus D14, when IO was measured.
Behavior was also measured at D7: report testing on all three days in Methods
and retain D7 results in the supplement. This presentation choice followed
exploratory inspection and was not preregistered. Current statistical figures
may still contain D7; they have not yet all been revised to the main-figure
layout. Do not imply a steady change between D0 and D14.

## Editable presentation material

- `speed-presentation/`: D0/D14 group and within-group trajectory SVG/FIG/PNG,
  locomoting-speed statistics and selected D0/D14 CSV tables. Earlier summary
  tables are in `speed-presentation/exploratory-tables/`.
- `posture-presentation/`: uncentered centroid-height trajectories by day and
  centroid-height statistics. Uncentered group-specific D0/D14 trajectories
  have not yet been made. Centroid height is referenced approximately to the
  detected bar top; consult the calibration caveats in `README.md`.
- `SLIPS&STOPS/`: retained pooled position histograms, slip- and stop-count
  statistics, D0/D14 tables, and sensitivity data. Main slip counts include
  slips overlapping stops; the combined slip/stop location histograms omit
  overlapping slips for display clarity. Positions are centroid positions.
- `tail-metrics/`: above-bar motion profiles and descriptive histograms;
  `tail-metrics/height-exploratory/` contains exploratory motion-height
  statistics and source summaries. Motion height is a weighted image-motion
  location, not an anatomically tracked tail point.

For trajectory shading, the reviewed versions use SEM; earlier SD and
trial-centered posture figure exports were removed. Do not show the three
crossings concatenated as separate beams; the main presentation uses pooled
daily crossings. Selected D0/D14 speed/posture tables remain in pixels or
pixels/s and are drafts, despite the spatial figures using mm. Do not silently
mix units. Holm corrections are across the three group-pair comparisons within
an outcome and period; analyses of different outcomes and days are exploratory
and not jointly multiplicity-adjusted. Review the methods and labels before
publication.

## Data and videos outside the repository

Proton Drive `WORK/DATA/Tara_balance_beam_combined_results_L40_20261109.mat`
contains one `dataset` structure with 377 trials, original rerun information,
row-motion profiles and corrected below-bar traces. SHA-256:
`24a0b824e8b4cbacdd2890076cc9fb258354b30b36df052647f2d7abf629186e`.
New motion-height trial and mouse-day summaries are in this repository under
`tail-metrics/height-exploratory/` but have **not yet** been added to that MAT
file. The full rerun ZIP is also in Proton Drive; original videos and canonical
results remain on the Mac mini at the paths in the project instructions.

The selected individual and composite movies are in Proton Drive
`WORK/DATA/Tara_selected_tail_metrics_debug_MP4_20261109/`. The preferred
three-panel outputs are under `Per_mouse_shared_scale_presentations/`: each
mouse's D0, D7 and D14 panels use one shared scale for the green/red spatial
profiles. The purple line and black weighted-median motion-height marker show
other quantities. The green/red spatial curves are weighted image differences,
not the per-trial MAD-normalized scalar traces used in the analysis. Background
signal remains visible and must not be described as proven tail motion.

The source video, full row-profile archive, movies and full combined MAT are
not generally stored in Git. Confirm Proton sync and the Mac mini's existing
local files before relying on them. The Mac mini generated newer shared-scale
video code and validation outputs locally; they were not on the remote branch
at this handoff and should be inspected and reconciled with the Mac Air's
`createTailMetricsDebugVideo.m` / `private/renderTailMetricsDebug.py` changes
before either version is overwritten. The Mac Air added an optional five-column
display-only smoothing test; the preferred shared-scale movies do not require it.

## Mac mini integration, 2026-11-10

Local workflow changes were preserved in commit `bcd89aa` before integrating
Mac Air handoff `64abcd0`. The merged single-trial renderer retains WorkFolder,
preparation-status checks, motion-height CSV and progress reporting, plus the
Air's optional DisplaySpatialWindow (default 1, no spatial smoothing). The
shared-scale presentation workflow remains raw and unsmoothed. Python syntax
and window-1/window-5 display-function checks passed; no new MATLAB render was
run during integration.

The combined MAT in the local Proton Drive folder matched the SHA-256 above,
and all three preferred shared-scale movies matched their canonical manifests.
This verifies local availability through the Proton folder, not remote-cloud
sync status. All 17 retained SVGs are present under DRAFTFIGS and parse as vector
files without embedded raster images. Some SVG labels are outlines; originals
were retained without conversion. No PDF export was made.

## Mac mini integration, 2026-11-10

Local workflow changes were preserved in commit `bcd89aa` before integrating
Mac Air handoff `64abcd0`. The merged single-trial renderer retains WorkFolder,
preparation-status checks, motion-height CSV and progress reporting, plus the
Air's optional DisplaySpatialWindow (default 1, no spatial smoothing). The
shared-scale presentation workflow remains raw and unsmoothed. Python syntax
and window-1/window-5 display-function checks passed; no new MATLAB render was
run during integration.

The combined MAT in the local Proton Drive folder matched the SHA-256 above,
and all three preferred shared-scale movies matched their canonical manifests.
This verifies local availability through the Proton folder, not remote-cloud
sync status. All 17 retained SVGs are present under DRAFTFIGS and parse as vector
files without embedded raster images. Some SVG labels are outlines; originals
were retained without conversion. No PDF export was made.
