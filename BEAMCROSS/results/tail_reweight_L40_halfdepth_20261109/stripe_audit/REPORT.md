# Stripe audit: S09 sedentary D14 trial 2, original frames 1169–1170

File: TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4. Original frames 1169 and 1170 correspond to traversal/debug frames
511 and 512. All inspection outputs are new files in this separate directory.

## Finding

The first observed corruption is in `post_mouse_crop.mp4`, written by MATLAB
VideoWriter during debug export. Both FFmpeg and MATLAB decode that movie with
the stripes and displaced image regions. `tail_debug_weights.mp4` inherits the
corrupted crop because its renderer reads the crop MP4. This is not merely a
viewer overlay or the plotted motion profiles.

Original source frames decoded independently with FFmpeg and MATLAB are clean.
Recropping MATLAB source frames using the exact saved column coordinates gives
pixel-identical matches to `crop_f1170_previous.png` and `crop_f1170.png`.
The analysis crops are clean. The earlier visual validation inspected lossless
stills and movie frame counts but missed corruption in the movies themselves.

## Export probes

Two-frame probes used the same lossless images with VideoWriter MPEG-4,
Quality=100, FrameRate=30. Width 234 reproduced the corruption with both grayscale
and explicit RGB input. Padding to width 240 by repeating the last column
removed the observed stripes. This isolates a width-dependent export problem;
it does not establish the precise internal codec/stride defect or a universal
alignment requirement. The images were not resized. Comparisons use the first
234 columns of the padded export. At frame 1170, mean absolute pixel error was
39.218 /255 for the gray234 probe versus
0.833 /255 for gray240; maximum error for
the latter was 6, consistent with lossy encoding.
Probes are separate files. No existing movie has been repaired or overwritten.

## Measurement checks

Both original tail bad flags and invalid-pair flags are false for these frames.
The clean PNG difference, multiplied by the exact destination-frame column
probabilities squared, matches the saved probability-weighted row profile at
1170: maximum absolute difference 4.73012875e-07, consistent
with float32 profile storage. Unweighted row-profile maximum error is
4.1512882e-07.

Motion-weighted height from the clean pair: 56.627570036436 pixels
above the bar; saved value: 56.627570036436. Difference:
7.11e-15 pixels. This is the location of detected motion,
not stationary tail position. Unweighted height also matches.

Raw above/below motion computed from the clean pair equals the saved debug
contributions to floating-point precision: above 96.793929153791,
below 24.421997737207. All three original scalar tail traces
for this trial reconstruct from the saved row profiles within absolute 1e-6
plus relative 1e-6 tolerance, including nonfinite locations. These traces were
computed before video export. The export corruption therefore did not generate
the saved values checked here. This audit directly validates source/crop pixels
for the requested pair; it is not an exhaustive pixel audit of every trial.

If measurements were recomputed from the corrupted movie, they would differ:
clean/moviedecoded weighted heights are
56.627570 /
49.210721 pixels. Never use
the corrupted debug MP4 as measurement input. The post-hoc below-bar reweighting
used the saved profiles, not the movie.

## Files and preservation

`source_frames_comparison.png`: two full source frames (FFmpeg).
`crop_stages_comparison.png`: lossless crop, crop MP4, debug MP4 crop panel,
and repeated lossless reference for each frame. Individual decoded frames are
also saved, including MATLAB source RGB/grayscale, exact recrops and independent
MATLAB decoding of the crop movie. `measurement_audit.json` records numeric
checks and saved tail values; `clean_vs_movie_pair.json` records hypothetical
movie-based contamination. `auditTailStripe1170.m` reproduces the MATLAB audit.
`index.html` provides a local review page with links to the original PNGs.

Source and five existing inspection artifacts were SHA-256 verified against
their prior manifests and remain unchanged. Paths are recorded in
`existing_artifacts_verified_unchanged.json`. Original results and source video
were read only; no full video matrix was saved. No bulk scratch was used.
