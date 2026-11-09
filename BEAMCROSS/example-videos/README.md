# D14 trial-2 tail-motion examples

These are copies, not moved originals. Group assignments come from the validated
L40 rerun identifiers, not from interpreting the filename's T3 token.

| Original filename | Group | Bytes | Traversal original frames |
| --- | --- | ---: | --- |
| TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4 | Sedentary | 3,712,607 | 659–1509 |
| TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4 | Run | 3,433,544 | 685–1362 |

Canonical source collection:
`/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved`.
Full source paths and matching source/copy SHA-256 checksums are in
`source_manifest.json`. The originals remain in place.

The repository's `*.mp4` ignore rule excludes both copies from Git. This README,
manifest and helper scripts can be tracked; cloning the repository will not
retrieve these videos. No Git LFS configuration or binary force-add was made.

## Repository debug movies

The two approved debug movies are copied into `debug/`, with their full source
stems followed by `_tail_debug_weights.mp4`. Exact-path exceptions in
`.gitignore` allow these two movies to be committed; the raw source-video
copies remain ignored. `debug/manifest.json` records canonical paths, sizes and
verified SHA-256 checksums. Canonical results on ShosaiData remain unchanged.

These movies show the **existing L40 weighting**, including the below-bar cubic
ramp that starts near zero beneath the beam. That weighting is under review;
these are not outputs of a corrected reanalysis.

## Debug views and screenshot selection

Canonical outputs:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_examples_L40_20261109`.
Open `index.html` there for the crop/weight movies, original-frame controls and
selected lossless stills. Each video has a folder named with its full filename,
containing `tail_debug_weights.mp4`, `post_mouse_crop.mp4`, `frame_mapping.csv`,
and compact `weights_and_mapping.mat` (no full video matrix).

Both source previews and actual post-mouse crops were visually inspected. They
are useful measurement illustrations, not selected as representative group
comparisons. Suggested original frames: sedentary 1101, 1170 and 1254; run 854,
1103 and 1216. Frame 1170 has a particularly clear sedentary tail silhouette;
run frame 1103 shows a clear arch and a strong tail-shaped frame difference.
See the external methods report for limitations and frame-level flags.

## Reproduction

Use the frozen code snapshot in
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/code_snapshot`.
The additive helpers are `tests/prepareTailExamples.py`,
`tests/exportTailExampleData.m`, `tests/runTailExamples.m`,
`tests/renderTailExamples.py`, and `tests/documentTailExamples.py`.
Prepare the instrumentation, run `runTailExamples` using MATLAB R2024b, render
with Python + NumPy + Pillow and ffmpeg, then build the documentation. These
scripts use explicit established paths; choose a new output folder in all of
them before rerunning if preserving this result set. The existing analysis
functions are unchanged. Parameters are L40 / S2.5 / M2, with stop exclusion off.
All captured centroids, speeds, under-bar motion, tail traces and tail bad-frame
flags were asserted exactly equal to the saved validated rerun for both trials.
