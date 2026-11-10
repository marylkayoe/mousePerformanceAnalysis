# On-demand tail-metrics debug movies

From the repository root in MATLAB R2024b, supply a full original filename and
a **new output folder** under Tara's results root:

```matlab
addpath('BEAMCROSS');
info = createTailMetricsDebugForTrial( ...
    'TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL1_gray.mp4', ...
    '/Volumes/ShosaiData/DATA/Tara/RESULTS/my_new_trial_debug');
```

Outputs include `<original filename>.tail_metrics_debug.mp4`, lossless FFV1
crop and viewing MP4, raw frame-by-column MAT/CSV contributions, exact crop
coordinates/probabilities, mapping/masks, provenance and validation. The exact
raw and displayed median heights are in `render_inputs/motion_height.csv`.
Rendering inputs remain under the chosen external folder. No full video
matrix, repeated tracking or bulk scratch copy is needed. Existing output
folders are refused; failures retain diagnostic JSON and any partial outputs.
A partial movie is not proof of validation.

For preparation alone, use `prepareTailMetricsTrial(filename,newFolder)`.
For an existing successful preparation, use `createTailMetricsDebugVideo` with
its matching saved profile and a fresh movie path. Set `WorkFolder` to a new
directory under the result folder to retain renderer inputs there. The older
`tests/exportRunningTailColumns.m` remains a historical reproduction script.

## Available inputs and reconstruction

Defaults use the verified source collection, original L40 rerun and corrected
reference under `/Volumes/ShosaiData/DATA/Tara`. SourceRoot, RerunRoot,
CorrectedRoot and ExampleRoot can be overridden. The per-trial C, P and
corrected R files must have matching identifiers, timestamps, frame numbers,
masks, geometry and L40/S2.5/M2 parameters.

The 2026-11-09 inventory found all **377 source videos and row-profile inputs**.
Original C files retain beam crop ranges, centroids, traversal and direction,
but not per-column probabilities or post-mouse crop columns. P retains row
profiles, not those column inputs. Only two separate example weight files exist.

Where available, the saved example D is reused and validated. Otherwise the
missing inputs are reconstructed. `ReconstructWeights=true` forces reconstruction
and, when an example reference exists, requires exact equality of columns,
probabilities and squared weights.

Reconstruction reproduces the frozen uint8 background mean over **all original
frames** within the saved beam crop, ratio mask threshold 0.6 without morphology,
column mask fractions, median mouse-width estimate, original centroid
interpolation/clamping, cutoff 0.85 and squared destination-frame probabilities.
Saved centroids/traversal/direction are reused; no tracking, stops or slips are
recomputed. This requires three sequential source-decoding passes, keeping only
individual frames and compact probability matrices in memory. Frozen-function
SHA-256 hashes are checked; unsupported implementations are refused.

## Checks and semantics

- Every reconstructed weighted row profile must match P within
  `1e-6 + 1e-6*abs(reference)`.
- Original total/above/below traces must reconstruct from P. Newly decoded
  above/corrected-below contributions, after original smoothing/normalization,
  must match the saved scalar traces too.
- Corrected below raw sums must match `NewBelowRaw`. An exact per-column
  reference is available for the runner, but not assumed for other trials.
- Every lossless-video frame is decoded and hash-checked against its MATLAB
  crop; the renderer checks these hashes again.
- First-frame placeholders, invalid flags and nonfinite values remain explicit;
  no silent trimming/padding or invented replacement coordinates. Unresolved
  crop indices are refused. Original missing-X/invalid masks remain preserved
  even when the frozen tail function's interpolation policy is reproduced.

Below weights are `1+min(2*d,1)`: 1 just below the beam, 2 at half-depth, then
constant. Above weights are unchanged. Contributions are raw, before smoothing
and independent median/MAD normalization.

## Display

The handoff renderer's in-image legend, **20 mm scale bar**, full-profile
probability-weighted median and centered five-frame mean smoothing are retained.
Smoothing stays within contiguous valid segments. There is **no 5 mm exclusion**.
Invalid/no-motion/nonfinite frames retain the image with a red cross and no
measurement overlays. Movies play at 30 fps; original timing stays in MAT/CSV.

Default `MillimetersPerPixel=700/1201` is the inherited **approximate** horizontal
calibration applied vertically, not a per-trial physical calibration. Supply a
justified override if available. The marker locates motion, not a stationary
tail point.

## Verification and limits

Fresh results are under
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_debug_ondemand_20261109`:

| Trial | Frames | Validation |
| --- | ---: | --- |
| TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4 | 678 | Forced reconstruction exactly matches saved columns, probabilities and contributions |
| TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL1_gray.mp4 | 929 | No example-specific weights; reconstructed profiles and raw/normalized traces pass |

Both lossless videos and rendered frame counts passed. Independent MATLAB
calculations matched all raw/displayed median values and validity decisions.
Decoded movie frames were visually inspected. Overwrite, missing-source and
wrong-trial-profile checks were exercised and refused. The small failure folder
is an intentional negative test. `tests/validateTailMetricsOnDemand.m` records
the checks; use fresh negative-test destinations if running it again.

This validates **two trials, not all 377 movies**. Each requested trial must
pass its own checks. Requirements: MATLAB R2024b with original dependencies,
Python 3, FFmpeg/ffprobe, and macOS clang/Core Text for labels. Preparation
currently uses `/opt/homebrew/bin/ffmpeg`. Different decoders/code versions,
unresolved centroids, missing corrected references, normalization failures or
unsuitable display geometry need investigation rather than silent repair.
No bulk regeneration or new Git upload of movies was performed.

## Selected-crossing batch extension

The subsequent nine-crossing request (plus a walk D0 comparison) is recorded in
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109`.
See its final report for per-crossing results and any retry records. The batch
uses forced source reconstruction, and all final movies remain post-mouse crops.

This broader sample exposed odd crop widths (219 and 229 pixels) that the
yuv420p H.264 **viewing-copy** encoder initially rejected. Preparation now pads
only that optional MP4 to even dimensions at the right/bottom edges, without
rescaling. `viewingVideoWidth` and `viewingVideoHeight` record its size. The FFV1
lossless crop, per-column contributions and debug renderer retain exact crop
dimensions; the renderer uses its original integer display scale. This is not
near-bar blanking and does not change measurements. The independent video
validator checks each format against its appropriate dimensions.
