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

# Candidate supplementary-video trace extraction (2026-11-06)

`extractCandidateBeamTraces(outputDir)` captures 12 explicitly selected trials
through a renamed, instrumented top-level copy; original analysis code is unchanged.
Canonical results: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_candidate_traces_20261106`.
That folder includes MAT/CSV traces, status, reference comparisons, code/input hashes,
and a README describing timing, nonfinite values, and unverified reference settings.
This historical candidate run used LOCOTHRESHOLD=150. Use the subsequent full
L40 rerun for Tara's confirmed settings; do not treat the candidate run as equivalent.
Reference: three `BB_*_261105_2.mat` files in `/Users/yoe/Downloads` (hashed in results).
No video matrices or debug movies are saved. No bulk scratch is required.

Reproduce with `python3 tests/prepareCandidateBeamTraces.py OUTPUT_DIR`, then
MATLAB `extractCandidateBeamTraces(OUTPUT_DIR, trialIndex)` for indices 1–12
(one fresh process per trial limits retained memory), then
`verifyCandidateBeamTraces(OUTPUT_DIR)`. Add `tests` to the MATLAB path.
Existing successfully saved trials are skipped. Use a new output directory
for a different analysis configuration. The preparation helper requires ffprobe
at `/opt/homebrew/bin/ffprobe`; reference filenames and roots are explicit in
these helpers. Only metadata and small traces are written, not video matrices.

Final outcome: 12/12 saved and verified. Four VideoReader frame rates disagree
with encoded 160-fps timestamps; CSV/MAT time axes use verified encoded timing.
S18 D14 trial 2 retains the pipeline's rounded 159-fps analysis scaling.
All reference mean-speed/posture/tail summaries match, but stopping and slip
metrics differ. See canonical `VALIDATION_REPORT.txt` before using these traces.

# Full Tara event/trace and row-profile recovery (2026-11-06)

Canonical outputs: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106`.
The user confirmed locomotion/slip/mouse-size thresholds **40 / 2.5 / 2** and
approved up to 3 GB including compressed row profiles. No bulk scratch is used.
`METHODS.txt` and `run_manifest.json` in the result folder describe exact code,
settings, grouping evidence, timing, instrumentation and limitations.

- `prepareTaraBeamRerun.py` initializes a new output directory, freezes original
  analysis source and an instrumented copy, joins group metadata, and prepares
  independently decoded frame timestamps and SHA-256 hashes.
- `computeBeamRowProfiles.m` captures unweighted and destination-frame
  probability-squared weighted row sums from the post-mouse region. Its new
  motion-height indices are separate from the existing verticalMotionTrace.
- `auditBeamRowProfiles.m` exports paired debug-video frames/profile sheets.
- `rerunTaraBeamDataset.m` writes one trial at a time, preserving small stage
  checkpoints, partial failures, nonfinite values, original frames, event positions,
  compact indices, and compressed row profiles. It never saves video matrices.
- `launchTaraBeamRerun.py OUTPUT_DIR --batch-size 12` restarts MATLAB between
  serial batches and skips any trial with a status record, including failed/partial
  outcomes. Inspect those records explicitly before planning a retry.
- `finalizeTaraBeamRerun.m` validates saved events/profiles, aggregates comparisons,
  and plots D0/D14 event counts per crossing visiting each common position bin.

Initialize by exporting the struct from
`/Users/yoe/Downloads/groupingMetadata_TMCS2_TMCS3.mat` as `grouping_metadata.json`
in the new result folder, then run `prepareTaraBeamRerun.py OUTPUT_DIR`.
Copy `rerunTaraBeamDataset.m`, `computeBeamRowProfiles.m`, and
`auditBeamRowProfiles.m` to that folder's `code_snapshot` before launching.
The launcher requires a `storage_approval.json` with the explicitly approved
`maxNewBytes` (3,000,000,000 for this run); never infer future approval from it.
Finalization: MATLAB `addpath('tests'); finalizeTaraBeamRerun(OUTPUT_DIR)`.
All thresholds, source roots and reference filenames are explicit in the code.

These are provenance-specific workflow scripts, not an automatic startup suite.
Review hardcoded paths and choose a new output destination before reproducing a
completed review; some figure/report helpers replace files in their configured
review folder. Preparation and launch commands perform work when executed.
`finishTaraBeamRerun.py` additionally sends Taildrop messages/files using an external
`delivery_plan.json` after its visual-review gate; run it only with explicit delivery
authorization. No device credentials or delivery plans are stored in this repository.


## Exploratory D0 entrance review (2026-11-07)

Canonical review: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_entry_review_20261107` (about 28 MB). Read `FINDINGS.txt`, `METHODS_AND_RESULTS.txt`, or open `review.html`. Original videos and the prior canonical rerun remain unchanged. No bulk scratch was used.

The post-hoc camera-field bin is `[0.90,0.95)`. Reviewed 37 events and 10 non-event windows from 13 mice, 11 cages and 21 trials, with both cohorts in every group. Intermediate detector captures exactly match saved traces, speeds, centroids, frame mappings and event intervals for all 21 trials. All 124 eligible D0 crossings contribute to exposure/speed summaries. Preserve mouse/cage identifiers: frames/events are not independent replicates.

The analysis separates pre-speed unweighted/weighted under-bar movement, speed adjustment, smoothing and trial baseline normalization. Low-speed exposure differs across groups; common-speed reweighting is a descriptive frame-exceedance calculation, not corrected slip counts. Exactly zero speed can cause Inf/NaN intermediates subsequently converted to zero. Original code/settings were not repaired or changed. See the report for visual uncertainty and sampling limitations.

Reproduction uses Python with NumPy/Pillow, `/opt/homebrew/bin/ffmpeg` and `ffprobe`, and MATLAB R2024b. Scripts have explicit canonical paths; adapt only with documented provenance. Run from repository root, in order:

1. `reviewBeamEntrance.py` (primary sample, frame sheets, slow clips and exposure)
2. `addLowSpeedEntranceControls.py` (four additional controls; refuses duplicate addition)
3. `summarizeEntranceReview.py` (joins the preserved observation JSON; camera checks and clip validation)
4. MATLAB `checkEntranceNumerics` (exact saved crop geometry and isolated numerical check)
5. `illustrateEntranceDetectorBand.py` (source-frame band overlay and continuous target clip)
6. `prepareEntranceDetectorAudit.py`, then `launchEntranceDetectorAudit.py` (serial batches; original frozen dependencies; only compact intermediates)
7. `analyzeEntranceDetectorStages.py`
8. MATLAB `plotEntranceDetectorStages`
9. `buildEntranceReviewReport.py`

The recorded observations are qualitative source-sequence judgments, not automatically regenerated biological ground truth. The instrumented detector validates exact agreement before saving successful output. The first diagnostic batch had a capture-code placement error; failed attempt records were preserved and all four retries passed after correcting instrumentation. Current preparation code contains that correction.

Keep only these small helpers, observation/report source and instructions in Git. Clips, figures, MAT/CSV products, logs, and all generated result folders belong in the canonical external review folder. No new bulk scratch is safe-to-delete by implication. Internal free space was about 35 GiB before and 31 GiB after; products were external, with transient OS/MATLAB memory/swap activity on the internal disk.

## Running-example per-column export (2026-11-09)

Canonical export:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_running_column_export_L40_halfdepth_20261109`.
For `TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4`, this contains
678-by-226 frame-by-column above-bar and corrected below-bar raw contribution
matrices in MAT/CSV, exact destination-frame probability weights and crop column
coordinates, frame mapping and invalid masks. Below weights are 1 at the first
below-bar row, linear to 2 at half-depth, then constant. All below sums reproduce
the saved `NewBelowRaw` within `1e-6 + 1e-6*abs(reference)`; maximum absolute
error is 4.21562e-6. Above contributions match the original export exactly.

Run MATLAB `exportRunningTailColumns`, then Python
`validateRunningTailColumns.py` (NumPy/Pillow, FFmpeg required). Select a fresh
destination before rerunning. Saved crop coordinates and probabilities are
reused; tracking is not run. Source frames are decoded with the original MATLAB
reader convention and streamed directly to FFmpeg, avoiding MATLAB's problematic
MPEG-4 export. The FFV1 grayscale MKV is lossless and all 678 decoded frame hashes
match the analysis crops. The H.264 MP4 is a clean lossy viewing copy. Both are
226 wide by 356 high, original frames 685–1362, 30 fps playback; original source
timestamps are in the mapping CSV. Existing source/results are unchanged.
This separate external export is approximately 19 MB and uses no bulk scratch.

## Selected tail-metrics movies

`runSelectedTailMovies.m` processes the user-selected nine filenames and an
additional walk D0 trial 3, reading `selection_manifest.json` from
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109`.
Each trial uses `createTailMetricsDebugForTrial(...,ReconstructWeights=true)`.
`retrySelectedTailMovies.m` writes any failed trials to fresh retry folders;
initial logs remain intact. `reviewSelectedTailMovies.py` independently validates
complete movie decoding, frame counts, full-profile median and five-frame
smoothing, then builds a crop-only local gallery. `reportSelectedTailMovies.py`
writes the per-crossing findings and output checksums after visual inspection.
Scripts use fixed fresh destinations; adjust paths together before a new run.
No outputs are implicitly moved into Git or deleted. The existing runner D14
trial 2 comparison is retained by verified copy of its prior validated movie.

### Tracking-start presentation revision (2026-11-09)

`createTailTriptychs.py --trim-hold` starts each panel at the first saved
`InvalidOrUnusable=0` frame and holds its final image when shorter than the
other panels. Later invalid frames remain. `validateTrimmedTailTriptychs.py`
checks timing, first-frame validity, decoded final-frame holds and reference
images, and exports trimmed individual movies (including alternate walk D0).
Canonical outputs: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_triptychs_tracking_start_20261109`.
Original movies remain intact. Original frame/time mappings and held-frame flags
are in the presentation CSVs; per-trial start offsets are in the manifest.
MP4-only delivery: Proton Drive `WORK/DATA/Tara_selected_tail_metrics_debug_MP4_20261109/Tracking_start_presentations`.

Runner shared-scale comparison: `createTailTriptychs.py --shared-runner-scale` uses one green/red maximum across full valid D0/D7/D14 trials, preserving tracking-start timing and last-frame holds. Validation: `validateSharedRunnerScale.py`. Canonical results: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_runner_shared_scale_20261109`. Previous per-trial-scaled movies are retained.

### Per-mouse shared green/red presentation scale

Run `python3 tests/createTailTriptychs.py --shared-scale` with NumPy, Pillow,
FFmpeg and ffprobe available. This uses the selected-movie manifest's requested
D0/D7/D14 trials. `--source-root PATH` selects another prepared input root;
`--output PATH` requires a fresh external destination. Each group must select
exactly one mouse and one crossing per day. The default new destination is
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_mouse_shared_scale_20261109`.

For each mouse, the denominator is the maximum of both raw above- and corrected
below-bar column contributions across all columns and all renderer-valid frames
of all three full trials. It is computed before start trimming. Each panel's
stroke displacement is `150 * rawContribution / sharedMaximum` output pixels
at the existing 2x display scale, before raster rounding. No MAD normalization,
background subtraction, suppression or extra smoothing is applied. Invalid flags,
purple per-trial profile scaling, the five-frame-smoothed black height marker,
headings, padding, beam alignment and D0-only scale bar remain unchanged.
The option starts panels at their first valid frame, plays at 30 fps, and holds
shorter panels' last frames. It never overwrites old versions.

The manifest records the three original full-trial maxima and all three display
denominators. CSV mappings retain original frames/times, invalid and hold flags.
Validate with `python3 tests/validateSharedRunnerScale.py OUTPUT_PATH` (the legacy
filename now supports all three mouse presentations). It independently recomputes
maxima, verifies identical frame mapping and panel geometry, checks first-frame
validity and every held panel, fully decodes the movies, compares encoding against
reference images, and checks that reference pixel changes from the per-trial
version are confined to green/red strokes. Previous movie hashes are rechecked.

The original `--trim-hold` per-trial mode and legacy `--shared-runner-scale`
option remain available. `BEAMCROSS/createTailMetricsDebugVideo.m` remains the
single-trial renderer and is not modified by this option. No underlying results
or statistical analyses are changed. Alternate walk D0 trial 3 remains separately
available under the prior `Tracking_start_presentations/individual_tracking_start`
Proton folder and canonical tracking-start results. Only the three new MP4s are
copied to `Per_mouse_shared_scale_presentations` alongside prior Proton versions.
