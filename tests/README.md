# Validation helpers

These are manual integration checks using the canonical videos, not MATLAB unit tests.
Add this folder to the MATLAB path with `addpath(fullfile(pwd, 'tests'))` from the repository root.
Results stay in the external project results directory; no videos are copied into `tests/`.

# Stopping-frame exclusion comparison (2026-10-15)

Persistent result directory (created under the existing Tara results root):
`/Volumes/ShosaiData/DATA/Tara/RESULTS/stop_exclusion_comparison_20261015`

Source videos:
`/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved`

Run with MATLAB R2024b Update 10. `compareStoppingFrameExclusion(outputDir)`
selects 12 videos from the sorted source filenames using MATLAB twister seed
20261015 and runs each with `EXCLUDE_STOPPING_FRAMES=false` and `true`.
Mouse-size threshold = 2; slip threshold = 2.5; locomotion threshold = 150.
Plots/video display disabled; only scalar results retained. The local working
changes in BBanalysisSingleFile, detectSlips, and getTailMotionMetrics were used.

- `comparison.csv`: all 24 results, original filenames, stop counts, overlap counts, errors.
- `comparison.png` / `comparison.pdf`: paired scatter plots, with numerical issues noted.
- `run.log`: MATLAB output and per-run resource checks.
- `README.txt`: parameters and plotting notes.

Total result size approximately 300 KB; persistent, not disposable scratch.
No copied videos or saved video matrices. The two scripts in this directory
are reproducibility material suitable for Git; the outputs remain external.
`plotStoppingFrameComparison(outputDir)` regenerates the final plots from CSV
without loading videos. The count panel uses 12 pairs, the finite-magnitude
panel uses 10, and the explicitly labeled zoom uses 9 pairs below 1e10.

All 24 calls returned, but exclusion produced two infinite magnitudes and
one magnitude around 1.85e35. Preserve these observations; do not interpret
successful execution as proof of numerical validity. Median slip counts were
6.5 with stops included and 2 with stops excluded (all 12 pairs).

The 40-video normalization check is implemented in `validateMovementNormalization.m`; its parameters, results location, and code hashes are recorded in `movement_normalization_validation_20261015.json`.
