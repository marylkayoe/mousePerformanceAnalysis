# Running example: per-column tail motion and clean crop video

Source: `TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4`. Group: run. No tracking was repeated. The original source
and existing results were read only; this is a new, separate export.

## Data files and alignment

- `column_contributions.mat`: MATLAB structure E. `aboveContributions` and
  `newBelowContributions` are **678 frames × 226 crop columns**. Rows correspond
  exactly to `frame_mapping.csv`; columns follow the saved crop's order.
- `above_contributions_frame_by_column.csv` and
  `new_below_contributions_frame_by_column.csv`: the same raw matrices, no
  headers. These are before temporal smoothing and median/MAD normalization.
- `source_columns_frame_by_column.csv`: original decoded-image column number
  for every crop column/frame (MATLAB 1-based coordinates).
- `destination_probability_squared_frame_by_column.csv`: the exact probability
  weights multiplied into the contributions at destination frame k. MAT also
  retains the unsquared probabilities.
- `frame_mapping.csv`: export frame, original frame, encoded timestamp, flags,
  above/below sums, reference NewBelowRaw, per-frame numerical errors and hashes.

Original frames **685–1362 inclusive**, 678 frames. Crop dimensions are
**226 pixels wide × 356 pixels high**, retaining original video rows.
Original timing is stored without substitution: VideoReader fps
159.4768829345703, encoded rate 160.0000000000091, analysis rate
159. Use `EncodedTimeSeconds`, not movie playback time, to
align with the source. Flags: 118 original tail-bad frames and
119 invalid pairs. The original tail mask, preceding tail mask,
stricter invalid-pair mask, and original missing-tracking-X mask are preserved.
Contributions at flagged frames are retained, not silently zeroed or removed.
The first row is zero only to reproduce the existing no-predecessor convention;
its invalid-pair flag is true. No length trimming or padding was performed.

## Exact contribution definition

For transition k-1 → k and crop column x:
`contribution(k,x) = sum_r(abs(crop_k(r,x)-crop_(k-1)(r,x))/255 * rowWeight(r)) * probability(x,k)^2`.
The saved `croppedNoMouseProbValues` already have the original 0.85 cutoff.
Coordinates and weights come from the validated L40/S2.5/M2 rerun capture.
The source is decoded sequentially with the same MATLAB VideoReader/rgb2gray
procedure; every reconstructed weighted row profile is checked against the
saved profiles. Crops move as in the original analysis, so differences can
include crop movement and residual non-tail motion.

Above rows are 1:barTop with the original normalized cubic row ramp
`(linspace(0,1)+eps)^3`. Below rows start at barTop+barWidth. Their new weight is
`1+min(2*d,1)`, where d is 0 at the first below-bar row and 1 at the last image
row. Thus weight starts at 1, reaches 2 at half-depth, then remains at 2.
The beam-gap rows are excluded from both regional measures. Exact row lists,
bar position/thickness and weights are stored in MAT. The full-height total
measure is not changed or recomputed in this export.

## Numerical validation

All above-bar contributions match the previous per-column export, with maximum
absolute difference **0**. All corrected below-bar column
sums reproduce saved `NewBelowRaw`. Criterion for every frame is
`abs(export-reference) <= 1e-6 + 1e-6*abs(reference)`; maximum absolute difference
is **4.215617e-06**. The reference was computed from compressed
single-precision row profiles, whereas this export sums directly from decoded
crop pixels; small rounding differences are expected. All reconstructed weighted
row profiles pass that same absolute-plus-relative tolerance. CSV sums are
independently checked after serialization. See `numerical_validation.json`,
`video_and_csv_validation.json` and `frame_mapping.csv`.

## Clean videos

- `post_mouse_crop_lossless.mkv`: FFV1, 8-bit grayscale, exact 226×356 pixels.
  **All 678 decoded frames match SHA-256 hashes of the MATLAB analysis crops**.
  Use this file for lossless pixels (e.g. with FFmpeg or VLC).
- `post_mouse_crop_clean.mp4`: H.264 viewing copy, grayscale content encoded
  as yuv420p, same dimensions/frame count. No overlays, resizing or border
  padding. It is lossy and should not replace the measurement arrays.
  Worst-frame mean absolute error is
  1.25917/255; maximum pixel error
  44/255. Pixels with error >50:
  0 across all frames.

Both videos play at **30 fps for inspection**, not source speed. All frames,
including invalid ones, remain present and are identified in the mapping CSV.
Raw grayscale frames stream directly from MATLAB to FFmpeg; the problematic
MATLAB MPEG-4 writer and old crop movie are not used. There is no saved full
video matrix or bulk temporary file. Five existing lossless sample PNGs were
matched exactly; fresh sample PNGs are included for visual inspection.

## Provenance and reproduction

`provenance.json` identifies and hashes source inputs. MATLAB version:
24.2.0.3361896 (R2024b) Update 10. Scripts `exportRunningTailColumns.m` and
`validateRunningTailColumns.py` are copied here and live in repository `tests/`.
Choose a new output path before rerunning; MATLAB refuses an existing directory.
Python validation needs NumPy/Pillow and ffmpeg/ffprobe. `artifact_checksums.json`
records output checksums. Original videos/results remain unchanged.
