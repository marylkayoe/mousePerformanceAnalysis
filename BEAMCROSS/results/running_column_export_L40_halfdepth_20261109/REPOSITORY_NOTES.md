# Running-example export available through Git

This user-approved repository copy contains the new per-column contributions,
clean videos, frame mappings, sample images and validation for
`TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4`.
After pulling the repository, all these files are available locally on the
MacBook Air; ShosaiData is not needed to inspect them. Ordinary Git stores the
files, with no Git LFS dependency. Total size is about 19 MB.

Canonical originals remain unchanged at:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_running_column_export_L40_halfdepth_20261109`.
The original source video is not included in this export.

## Start here

- [Clean MP4 crop](post_mouse_crop_clean.mp4): convenient viewing copy.
- [Lossless grayscale MKV crop](post_mouse_crop_lossless.mkv): exact pixels;
  use a compatible player such as VLC or decode with FFmpeg.
- [MATLAB contributions](column_contributions.mat): structure `E`, with
  `aboveContributions` and `newBelowContributions`, each **678 frames × 226
  crop columns**, plus exact weights, crop coordinates, timing and masks.
- [Above-bar CSV](above_contributions_frame_by_column.csv) and
  [corrected below-bar CSV](new_below_contributions_frame_by_column.csv):
  headerless matrices with the same orientation.
- [Frame mapping](frame_mapping.csv): original frames **685–1362**, encoded
  timestamps, original tail-bad flags and stricter invalid-pair flags.
- [Methods](README.md) and [validation](video_and_csv_validation.json).

Both movies are **226 pixels wide × 356 pixels high**, with 678 frames and
**30 fps inspection playback**. Use the mapping CSV for source-video timing.
All 678 decoded lossless frames match the MATLAB crop hashes. The MP4 is lossy
but clean; neither movie is the old striped debug export.

Above-bar weights are unchanged. Corrected below-bar weights start at **1**,
rise linearly to **2 at half-depth**, then stay at 2. Contributions use the
saved destination-frame probability-squared weights and are raw, before
smoothing/normalization. Every below-bar column sum matches `NewBelowRaw`
within `1e-6 + 1e-6*abs(reference)`; maximum absolute error is 4.21562e-6.
Invalid frames are retained and flagged. The first zero contribution row is a
legacy no-predecessor placeholder, not a measured absence of motion.

`repository_manifest.json` verifies each copied file's SHA-256 against the
canonical export. The copied `README.md` describes the external layout; its
references to scripts/checksums are resolved here by repository `tests/` and
`repository_manifest.json`. Transient logs and duplicate scripts were omitted.
Reproduction scripts are `tests/exportRunningTailColumns.m` and
`tests/validateRunningTailColumns.py`; rerunning requires canonical source
inputs, although inspecting the committed outputs does not.
