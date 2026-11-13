# Marked tail presentations — 2026-11-12

Canonical root:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_D14_examples_marked_20261112`

Six selected sources: `tail_candidate_pairs.json`. Selection rationale and
limitations: `TAIL_CANDIDATES.md`. No original results or measurements overwritten.

## Reproduction
1. R2024b: `addpath('tests'); prepareMarkedTailExamples` (fresh root required).
2. Python with numpy/Pillow/ffmpeg: `tests/renderMarkedTailExamples.py`
   (fresh presentations subfolder required).
3. Preparation reconstructs source crops, original destination-frame probabilities
   and unchanged above / corrected half-depth below contributions, using frozen L40
   rules. No tracking rerun. All six row-profile, scalar-trace and lossless crop
   validation checks pass. Absolute errors of several e-6 pass the established
   mixed tolerance 1e-6 + 1e-6*abs(reference), not absolute1e-6 alone.
4. Rendering independently checks every lossless gray-frame SHA256, original-frame
   mapping, full-profile weighted median and five-frame mean against finite cached
   motion-height samples (tolerance1e-8). Checks full decode/count/FPS/dimensions.

## Tail slips
Exact existing exploratory peak definition is reused for these selected filenames:
NewBelowRaw; joint finite motion height/raw-motion and !TailBadFrame and
!InvalidFramePair; per-trial1.4826×MAD; prominence5×scale; nominal0.1s separation
within contiguous valid runs, with historical short-run distance capping.
Undefined scale retains NaN count. Detection uses the untrimmed full trial.
SED D0 and RUN D0 detected original-frame lists exactly match saved D0-first
events. Other selected trials did not have corresponding prior first/last event
tables, so are newly evaluated using the same detector, not independently
visually confirmed physical slips.

Counts D0→D14: SED5→4; WALK9→4; RUN4→3. Selection was based on D14 whole-tail
score and motion height, not these counts.

At each event peak, marker x is the argmax corrected-below column contribution
(first maximum if tied); y is the red display curve at that column. An orange
circle remains at those screen/crop coordinates thereafter, with overlap allowed.
These are not fixed beam coordinates or tracked tail-tip locations. Positions,
original frames, raw amplitude/prominence and source column are saved separately.
No border pulses or counters, per the user's correction.

## Display
Raw green/red traces are linear, unsmoothed and not MAD-normalized, with one
maximum across all valid frames of each mouse's two full trials, before trimming.
No log transform from the under-bar movie is silently applied here.
Purple profile retains a per-trial maximum. Black marker is the full-profile
motion weighted median with contiguous five-frame mean; no5mm blanking.
Invalid/no-motion frames retain red X and suppress current measurement overlays;
prior event markers remain. Tail-bad and invalid-pair masks remain distinct.
Initial invalid frames are trimmed through the first valid motion frame, consistent
with the prior tail presentations. Full mapping is retained; internal invalid
frames are not removed. All six start together at their first valid frame.
30fps playback; shorter panels hold the final frame.
All source crops are shown at2× nearest-neighbor scale; centered horizontal
padding and vertical padding align bar tops across every panel. No stretching.
One20mm scale bar and legend below composites, using inherited700/1201mm/pixel.
The individual image-only videos omit the shared legend/scale bar; paired and
3×2 presentations include them.

Outputs: six individual marked MP4s, three paired MP4s, one3×2 MP4; event tables,
marker positions, per-frame presentation mapping and manifest. Canonical
preparation artifacts retained for restart/review; no bulk scratch.
Motion-score differences in selected candidates are modest; raw displayed
contributions are not the normalized scalar score, and per-mouse scales do not
support cross-row amplitude comparisons.

## Horizontal log-below variant
User requested a single horizontal row of six panels, grouped by mouse.
Run `tests/renderMarkedTailExamples.py --log-below --horizontal`.
Fresh output: `presentations_log_below_horizontal` under the same canonical root.
Order: SED D0,D14;32px black gap; WALK D0,D14;32px gap; RUN D0,D14.
No image resizing; each panel and the common bar alignment remain unchanged.
Red depth is150×log1p(rawBelowColumn)/log1p(sharedPairColumnMaximum) display px.
Green remains150×rawAboveColumn/sharedPairColumnMaximum. Therefore red and green
trace heights are no longer on the same linear amplitude scale; legend states
the difference. Same unsmoothed, full-trial maximum is retained before trimming.
No temporal or spatial smoothing added. Marker y follows transformed red curve;
peak time, x, event values and marker size are unchanged. New marker-coordinate
sidecars and frame mappings are written into the variant folder, preserving
the earlier linear version and its sidecars. Original scalar measurements,
profiles, statistical summaries and detector are unchanged.
