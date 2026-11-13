# Full-traversal underbar column-motion pilot

Canonical pilot: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_underbar_column_movie_20261112/runner_D0_trial2. Original TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4 read in place; original frames856–1822 inclusive,967frames. Playback30fps (32.23s), analysis/source160fps; movie is slowed presentation, not real-time. Full1280×356source image plus32px header, no spatial crop or resizing. No tracking rerun or source-result modification. No bulk scratch.

BEAMCROSS/exportUnderbarMotionColumns.m reconstructs frozen L40 ratio images using uint8 mean of ALL original frames within saved beam crop; threshold0.6 yields column probability over full beam crop. Underbar band round(barAnalysis+thickness/2)+3 through round(barAnalysis+1.5*thickness)+3. Raw column contribution=sum_r(abs(ratioFrame_k-ratioFrame_previous)*rowWeight)*probability(column,k)^2. Row weight=normalized sigmoid steepness20,midpoint0.2. Destination-frame probability weighting retained, not tail no-mouse weights. First frame0placeholder/no predecessor is marked. Probabilities and raw columns saved separately. Frozen snapshot hashes checked for subsequent invocations; first pilot hashes recorded after successful trace validation.

Sum columns, multiply160/log1p(forwardSpeed), smooth10 and apply frozen finite-nonstop baseline MAD normalization/clamping reproduces saved MovementTrace over all967frames; maxerror3.55e-14, tolerance1e-6+1e-6*abs(reference). Internal nonfinite speed-adjusted samples retained in frame_mapping.csv, not silently imputed. Saved normalized NaN-to-zero behavior reproduced for validation only. Source centroids/full original frame mapping retained. No final normalized slip-score decomposition is claimed: displayed profile is RAW weighted motion before speed/smoothing/MAD.

Renderer draws only nonzero mouse-probability column support, orange with white outline beneath original bar bottom. Fixed whole-trial raw-column max4.25566462027422 mapped to80display pixels, no per-frame gain/no smoothing. Overlay depth is arbitrary display amplitude, NOT paw depth. Streamed source frames, no full video matrices saved. Full output decode and967frames/30fps verified; sample raw decoded-frame SHA256 saved. PNG previews rendered and decoded checked. Optional --centroid-trail provides saved centroids and preceding0.3analysis-seconds (48frames), fixed size/color; pilot leaves it off, and has no slip highlights or speed encoding. The optional trail has not yet been visually validated. Generic file input supported by exporter; one trial validated so far. Current script title generalized after pilot render; pilot header has equivalent hardcoded mouse/day text.

Run MATLAB addpath('BEAMCROSS'); exportUnderbarMotionColumns(originalFilename,freshExternalFolder), then Python with NumPy/Pillow: tests/renderUnderbarMotionMovie.py freshExternalFolder. Existing folders/movies refused. Do not interpret a completed process as equivalence; scalar validation required before rendering. Check canonical validation.json, metadata.json and movie_validation.json.

## Speed-adjusted variant

Same trial/source/weights and original frames856–1822 as parent raw pilot. Each raw column multiplied by160/log1p(forwardSpeed), using original pixel/s speed, matching detector; negative logarithms replaced by eps. Stops retained. No temporal smoothing or MAD normalization. Summed adjusted columns checked against saved reconstructed scalar SpeedAdjusted with1e-6 absolute+relative tolerance, including nonfinite values. One frame has nonfinite adjustment and is explicitly labeled with no curve, not rendered as zero. First no-predecessor frame also labeled.

Fixed finite whole-trial column max228.9053153805653 maps to120pixels downward (raw pilot used80pixels and raw max4.25566462027422). Thus this is a stage-specific display gain, not identical amplitude units to raw pilot. No per-frame rescaling or clipping. Source data unchanged; raw movie retained.967frames,30fps,1280x388 including32px header; full decode validated. movie_validation.json and speed_adjustment.csv preserve details. Reproduce tests/renderUnderbarMotionMovie.py PARENT --speed-adjusted --display-depth120 --output FRESH_FOLDER (space between option and120 required).

## S20 D0 trial1 full traversal with centroid (2026-11-12)
Canonical folder: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_D0_slip_example_review_20261112/S20_underbar_centroid`. Full original frames992–1926,935 frames,30fps playback; source untouched. Saved scalar detector reconstruction maximum absolute error2.4869e-14, all frames pass. Speed-adjusted column sum also passes; one undefined frame explicitly labeled. Fixed column maximum30.13675917959334 maps to120pixels downward. This display stage has speed scaling but no temporal smoothing or MAD normalization.

Renderer option `--centroid-trail --trail-length-pixels 150` uses saved source centroids, MATLAB one-based coordinates converted to image coordinates. White marker with black edge; black trail with white visibility outline. History is capped by cumulative 2D path length150sourcepixels (approximate body length, not an anatomical measurement), never bridges missing coordinates. Default time-based0.3s mode remains available without length option. Source-preview frames1206 and1459 visually inspected; full movie decoded,935 frames and30fps verified. Run renderer with `--speed-adjusted --display-depth 120 --centroid-trail --trail-length-pixels 150`. No slip highlights, exclusions or measurement changes. Tail contributions are not suppressed.

S20 speed-color variant: `S20_underbar_centroid/speed_color/` preserves original variant. Centroid radius7px (previous3), white2px outline. Linear blue–cyan–yellow scale0–300mm/s, saved ForwardSpeed*700/1201 mm/px, no added smoothing; display colors clamp outside range, nonfinite gray. Numeric speed and scale in expanded56px header. Black/white150px trajectory and underbar weights/gain unchanged. Options `--centroid-speed --centroid-radius 7 --speed-color-max 300`. Full935-frame30fps decode validated; sample215 visually checked. Color encodes instantaneous saved forward speed including stopped frames, not the locomoting-only trial mean.

Black/red variant in `S20_underbar_centroid/black_red_stops`: `--centroid-palette black-red --black-stops` gives linear RGB(0,0,0) to(255,0,0), same0–300mm/s scale. Saved StopMask overrides speed color to pure black, white outline retained. This particular S20 crossing has ZERO saved stop frames, so stop override is not exercised by this movie. No new stopping criterion introduced. All935frames decode verified; preview inspected. Earlier variants preserved.

Speed trail/slip-marker variant in `S20_underbar_centroid/speed_trail_slips_60fps`: all935frames at60fps (15.58s; twice earlier playback, still slower than acquisition). `--speed-trail` colors historical centroid segments by destination frame's saved speed, black for saved stopping frames, same0–300mm/s scale. `--slip-markers` reads existing events.csv without new detection or exclusions. Temporal peak is first maximum of saved final MovementTrace within each inclusive event interval; horizontal marker location is strongest speed-adjusted underbar column at that frame, vertical location is displayed column depth (NOT anatomical paw depth). Marker appears at peak and remains fixed to movie end. Five markers, original frames1174,1203,1230,1260,1466. Exact coordinates and detector values in slip_markers.json. These are detector event markers, not independently confirmed paw contacts. Existing weights and display gain unchanged. Full decode/framecount60fps verified; frame468 visually checked. Earlier movies retained.

Magnitude markers: `S20_underbar_centroid/magnitude_markers_60fps`, option `--slip-magnitude-size`. Event score=sum(max(saved MovementTrace−2.5,0)) within saved inclusive event boundaries, matching detectSlips area-above-threshold definition (a.u.×frames, not seconds). Circle area proportional to score; radius=12sqrt(score/largest score in trial), no size floor, fixed scale for entire movie. Largest circle radius12sourcepixels. Exact scores/radii in slip_markers.json; all five retained and appear at original peak times. This is final event magnitude displayed retrospectively from event peak, not an online detector. Other overlays,60fps and full935-frame traversal unchanged. Preview inspected and full decode/framecount checked.

Readable compressed magnitude variant: `compressed_magnitude_markers_60fps`, adds `--slip-size-compressed`. Radius=4+8*(score/maxScore)^0.25 pixels:4px lower bound,12px largest, monotonically compressed. Marker area is NOT proportional to score in this version; header explicitly says compressed. Exact radii retained in slip_markers.json; measurements and locations unchanged. All935frames60fps decoded and preview checked. Proportional-area version retained.

## Stacked S20 D0 T1 / D14 T2
`tests/createS20StackedComparison.py` creates fresh `balance_beam_D0_slip_example_review_20261112/S20_D0_T1_D14_T2_stacked` (12MB) plus validated D14 inputs in sibling S20_D14_T2_underbar. D0 top935frames992–1926; D14 bottom684frames683–1366. First saved traversal frames start together at60fps; no stretching. Bottom final frame held251frames; total935frames15.583s,1280x824. Shared maximum across both full trials for speed-adjusted columns30.13675917959334; shared slip-score reference255.36082979605706, compressed radius4+8*(score/reference)^0.25. Speed colors0–300mm/s,150px trail,7px centroid, stop override black. Five D0/three D14 event markers. All data validation and decode checks pass; D14 detector maxerror1.5099e-14. Composite frame300 visually checked. Matched scales prevent individually boosting D14. New renderer options --shared-column-max and --shared-slip-score-max. No underlying measures changed. Sources and preceding outputs retained; no bulk scratch.

Shared-footer layout: `tests/addS20SharedFooter.py` derives `TMCS2_S20_D0-T1_D14-T2_shared_bottom_legend_60fps.mp4` in the stacked folder. Removes duplicate legend rows (including instantaneous numeric speed) from both headers, retains trial/original-frame headings, places one static speed/stop/slip-size legend below bottom image. No source-image resize or overlay-scale/timing changes.1280x812,935frames60fps; decode/count verified and frame300 inspected. Original composite retained; H264 derivative reencodedCRF17.

Clean presentation headings: `tests/createS20CleanPresentation.py` creates `TMCS2_S20_D0-T1_D14-T2_presentation_clean_titles_60fps.mp4`. Headings only TMCS2_S20 | D0 and TMCS2_S20 | D14. Shared footer describes analysis-weighted/speed-adjusted underbar motion, speed colors, stops and compressed event-score marker sizes. Frame numbers/trial IDs retained in provenance manifests, not burned into images.935frames60fps,1280x836; decoded/count checked and preview inspected. No image scaling or timing changes; old versions preserved.

Brighter speed/trail presentation: `S20_D0_T1_D14_T2_bright_speed/TMCS2_S20_D0-T1_D14-T2_presentation_clean_titles_60fps.mp4`, generated by createS20BrightSpeedComparison.py and createS20BrightSpeedPresentation.py. Renderer --trail-width6 (previous2), white visibility outline8; --centroid-palette black-red-yellow: RGB anchors black at0,bright red at150,yellow(255,240,0) at300mm/s, piecewise linear, shared across days. Saved stops remain black. Full935frames60fps and original hold/alignment, underbar gain and marker sizing unchanged. Footer gradient updated to exact same palette; preview checked and full decode verified. Prior versions preserved. No measurement or statistical changes.
Final brighter version is in `S20_D0_T1_D14_T2_bright_speed_continuous` (same movie basename); outlines drawn as one path before colored segments to remove white segment seams. Reproduction scripts now target this final folder. Decode/framecount and preview rechecked. Earlier bright pilot retained.

Three-group presentation set completed: see DRAFTFIGS/slip-movie-example-review/GROUP_PRESENTATIONS.md for selection and limitations. Canonical group_presentations folder under existing review root contains final *_group_headings.mp4 movies and presentation_manifest.json. All individual and final outputs fully decode, expected counts60fps; SED/RUN/stack previews and final heading checked. Source data, original code and preceding movies preserved. Selection is exploratory and based on D14 group differences with D0 context; no statistical conclusions established by selected movies.
Per-mouse motion-scale option completed for three presentations: see GROUP_PRESENTATIONS.md and external group_presentations/per_mouse_motion_scale/manifest.json. SED348.6837466297799,RUN218.28188757971935,WALK30.13675917959334. Existing matching SED individual renders reused; new composites and RUN/WALK renders fully decode with correct counts60fps. RUN/WALK previews checked. Speed palette/slip-marker size scaling unchanged; original shared-scale movies retained.

### Sedentary logarithmic motion display (2026-11-12)
Separate presentation requested for TMCS3_S07, D0 trial 3 / D14 trial 2:
`group_presentations/sedentary_mouse_log1p_motion_scale/` under the canonical
`balance_beam_D0_slip_example_review_20261112` results folder.
Reproduce with `tests/createThreeGroupUnderbarPresentations.py --motion-scale mouse --motion-transform log1p --group sedentary`.
Display depth is amplitude × log1p(speed-adjusted column contribution) /
log1p(shared full-trial finite maximum), with maximum 348.6837466297799
shared across D0/D14. The implicit log1p reference is one raw contribution unit;
this is a display transform, not a new measurement or normalization.
Zero stays zero; invalid frames remain invalid. No changes to event detection,
event scores, speed colors, marker radii, timing, or source measurements.
Persistent marker vertical locations follow the transformed displayed trace;
horizontal locations and peak frames remain unchanged. Linear versions retained.

### Spatially softened log display and new change examples (2026-11-12)
The renderer now accepts `--motion-smooth-sigma 2`: a Gaussian over source
image columns (sigma 2 px, radius 6 px), applied after log1p display mapping.
Each contiguous positive-probability region is smoothed separately with edge
padding. No averaging across frames, no bridging invalid frames or inactive
regions. The normalization maximum is still taken from unsmoothed full-trial
finite contributions. Event peak frame/x, scores and marker sizes are unchanged;
marker y follows the softened displayed curve at the original peak x.
All original linear and unsmoothed log outputs remain.

Existing pairs: `group_presentations/log1p_smoothed_existing_pairs`.
New pairs: `group_presentations/log1p_smoothed_change_pairs`.
Both under the canonical review root documented above. Scripts:
`selectChangeMovieExamples.py`, `reviewChangeMoviePairs.py`,
`exportChangeMovieColumns.m`, and `createThreeGroupUnderbarPresentations.py`.

Change selection is exploratory: compute each mouse's daily means across retained
crossings, then D14 minus D0. Rank mice by equal-weight mean absolute deviation
from their group's median paired change in speed, stopped percentage, slip count,
and total slip score, standardized by the group's change MAD for each metric.
Exclude the three previously illustrated mice to provide new examples.
Choose each day's retained crossing nearest that mouse's daily mean using the
same metric scales. No optimization for p-values, largest improvement or monotonic
SED/WALK/RUN ordering. All candidates/ranks are retained in
`DRAFTFIGS/slip-movie-example-review/change_example_ranking.json`.
Selection filenames and export destinations are in `selected_change_movies.json`.
User explicitly chose daily-average-representative crossings, not last crossings.

Selected: SED TMCS2_S14 D0 T4 / D14 T1; WALK TMCS3_S05 T2 / T2;
RUN TMCS2_S18 T3 / T3. Six source contact sheets (16 evenly spaced original
frames each) reviewed: no obvious crop corruption or hand intrusion in sampled
frames; tails occasionally descend below the bar. This is not exhaustive
paw-event adjudication. Saved detector events remain detector events.
The actual selected-trial speed increases are 47.4, 57.5, 39.5 mm/s, respectively:
the individual movies do not reproduce an ordered group effect, nor should they
be described as doing so. Daily-mean speed changes for these mice are
33.6, 56.3, 49.9 mm/s. Example selection cannot establish population inference.
New change-set rendering command:
```
python tests/createThreeGroupUnderbarPresentations.py --motion-scale mouse --motion-transform log1p --motion-smooth-sigma 2 --selection BEAMCROSS/DRAFTFIGS/slip-movie-example-review/selected_change_movies.json --shared-slip-score-max 2935.15718005536 --output /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_D0_slip_example_review_20261112/group_presentations/log1p_smoothed_change_pairs
```
Both sets use the same speed colors and compressed marker score reference
2935.15718005536; motion display maxima remain per mouse. Selection metrics are
in `change_movie_selection_metrics.csv`. All six new exports matched the frozen
scalar trace (maximum absolute error 2.49e-13; tolerances 1e-6 absolute/relative).
Smoothing sanity checks passed for zero, constant, isolated peak and array length.

### Three-row, two-column triplet composites (2026-11-12)
`tests/stackUnderbarTriplets.py` rearranges the two smoothed-log triplets into
two movies in `group_presentations/three_rows_two_days`. Rows are sedentary,
walk, run; columns D0, D14. Each original 1280×388 panel, including heading,
is cropped without resizing; the shared legend appears once below all rows.
Output is 2560×1224 at 60 fps. All six starts align at traversal-relative frame 1;
shorter panels hold their last frame. Existing per-mouse motion scales,
speed colors, markers and smoothing are unchanged; motion heights should not
be quantitatively compared between rows. Inputs are preserved. Manifest records
input mappings, frame counts, output hashes, layout and checks. Full decode and
exact output dimensions/frame count/rate are verified.
