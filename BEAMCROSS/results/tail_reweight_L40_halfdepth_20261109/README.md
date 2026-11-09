# Corrected below-bar tail traces — all 377 retained trials

This is the explicitly requested Git copy of the post-hoc reweighting results.
Canonical results remain unchanged at:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109`.
This folder contains approximately 88 MB of results, including both MAT and CSV
formats. No source videos, full video matrices or row-profile matrices are
included. These results use ordinary Git, not Git LFS.

## What changed

Below-bar weight starts at **1 immediately below the beam**, increases linearly
to **2 halfway to the image bottom**, and stays at 2 below that point:
`w(d) = 1 + min(2*d, 1)` for relative depth `d` from 0 to 1.
Above-bar and original full-height total-tail traces are unchanged. This does
not introduce a new combined above/below total. The original L40/S2.5/M2
tracking, frame mapping, mouse-column weights and masking policy are retained.
No video decoding or tracking was repeated for this calculation.

## Files to use

- `trials/<full original filename>.csv`: per-frame results. Use `NewBelowRaw`,
  `NewBelowSmoothed` and `NewBelowNormalized` for the revised measure.
  `OriginalFrame`, `EncodedTimeSeconds`, `TailBadFrame` and `InvalidFramePair`
  retain alignment and flags. The first raw zero is a legacy placeholder for
  an unavailable preceding frame, not evidence of no motion.
- `trials/<full original filename>.mat`: MATLAB structure `R` with equivalent
  traces, exact row weights, identifiers, original parameters, timing and
  reconstruction/normalization diagnostics.
- [comparison_by_file.csv](comparison_by_file.csv): per-trial validation and
  old/new summary values, including raw means over valid frame pairs.
- [validation_summary.json](validation_summary.json): all 377 trials completed;
  all three original measures reconstructed within the declared tolerance;
  388,616 CSV frame rows audited.
- [METHODS.md](METHODS.md): detailed definitions, normalization and limitations.
- [weight_comparison.svg](weight_comparison.svg) and two `*.comparison.svg`
  files: old/new weights and example-trial traces.
- `repository_manifest.json`: canonical root, SHA-256 checksums and sizes for
  every copied result file. These were verified against the canonical manifest
  before copying, and each destination was checksum-verified afterward.

**Raw and normalized quantities have different meanings.** Each normalized trace
uses its own median/MAD scale; normalized above/below amplitudes are not directly
comparable physical motion magnitudes. Preserve nonfinite values and consult
the masks and normalization diagnostics.

## Debug-video caveat

The videos in `BEAMCROSS/example-videos/debug/` show the **old weighting**.
The sedentary crop/debug movies also contain confirmed export corruption
(diagonal stripes); they must not be used as measurement input. Source frames
1169–1170 and the lossless analysis crops are clean and pixel-identical after
recropping. Their motion profile and height reproduce the saved measurements.
The new traces here come from those saved analysis profiles, not the movies.

`stripe_audit/` contains the numerical audit and report. Its referenced images
and probes remain in the canonical external audit folder:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_stripe_audit_S09_f1170_20261109`.
The existing movies have not been replaced.

## Reproduction

Repository scripts: `tests/reweightTaraTailProfiles.m`,
`tests/reportTailReweight.py`, and `tests/auditTailStripe1170.m`.
The reweighting requires the original saved profile/trial MAT files under
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106`.
Those bulk inputs are not duplicated here. Select a fresh destination in the
scripts before rerunning; the MATLAB reweighting refuses an existing output
folder. `environment.json` records MATLAB details. The canonical result's
git HEAD predates these added scripts; their committed versions and source
paths provide the accompanying reproduction record.
