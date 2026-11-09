# Post-hoc below-bar tail-motion reweighting

User-approved definition: weight 1 at the first below-bar image row, rising
linearly to 2 halfway from that row to the image bottom, then constant at 2.
For relative depth d in [0,1], w(d)=1+min(2*d,1). This meets the above-bar
maximum of 1 at the boundary. The old below-bar weight was min(2*d,1)^3
(with the original epsilon/max normalization). Above-bar and full-height
total-tail measures are unchanged. No new combined above/below measure is
introduced. This is a new below-bar measure, not a correction retroactively
applied to the old results. Weight depth is based on recorded image geometry,
not calibrated physical distance.

## Inputs and reproducibility

Source results: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106`.
Original source videos remain at the source path recorded in that result set;
none were read or copied for this calculation. No tracking was run.
Inputs were `trials/<original filename>.profiles.mat` and the corresponding
trial MAT. Each profile is row-by-frame, containing sum_x(abs(I_k-I_(k-1)) *
croppedNoMouseProbValues(:,k)^2), with the original 0.85 cutoff already applied.
Weights therefore use destination frame k. Profiles are compressed float32,
converted to double for row summation; tiny differences from recomputing video
pixels are expected. Original L40/S2.5/M2 parameters and trial identifiers are
retained in every output MAT. Original code/data and prior results are unchanged.

Run `tests/reweightTaraTailProfiles.m` in MATLAB R2024b, then
`tests/reportTailReweight.py` in Python 3. Choose a fresh destination in both
scripts before another run. The MATLAB script refuses an existing destination.
The code is copied into `code/`; environment, git HEAD and checksums are recorded.
No bulk scratch was required. Calculations process one small profile at a time.

## Validation

Trials: 377. Status counts: {'complete': 377}.
Reconstruction passes (absolute tolerance 1e-6 plus relative tolerance 1e-6):
{'OldTotalMatch': 377, 'OldAboveMatch': 377, 'OldBelowMatch': 377}.
Maximum absolute normalized errors: {'OldTotalMaxError': 1.00957860027506e-06, 'OldAboveMaxError': 4.31138461820524e-07, 'OldBelowMaxError': 4.00059454719326e-06}.
Reconstruction uses the OLD vertical weights and compares all three tail
traces with the saved validated rerun. NaN locations and infinity signs must
also agree. Frame counts, exact original-frame/timestamp mapping, bar geometry,
row coordinates and original bad masks are asserted; no trimming or padding.
The new ramp is checked for endpoints, monotonicity and the half-depth plateau.
Per-file mismatches, zero/nonfinite normalization scales and exceptions remain
explicit in `comparison_by_file.csv`; completion alone is not validation.

## Output semantics

Each `trials/<original filename>.mat` stores R with exact applied row weights,
raw old/new below-bar motion, new smoothed and normalized traces, original
above/total/below traces, reconstruction diagnostics, identifiers and timing.
Matching CSVs contain one row per traversal frame. First raw sample is zero
solely to retain the existing algorithm's no-predecessor convention; the
invalid-pair flag remains true. This does not mean observed absence of motion.
No full row profiles or video matrices are duplicated in this result set.

Normalization retains smooth(raw,5), median centering and 1.4826*MAD scaling.
As in the original code, normalization is computed before applying the original
tail bad-frame mask, and normalized NaNs are converted to zero before that mask.
The pre-replacement normalized array, replacement flags and scale are preserved
in MAT; pre-replacement values also appear in CSV. Nonfinite values are not
silently discarded. The stricter invalid-frame-pair mask is saved separately;
it is used for raw-mean comparisons but is not newly applied to the legacy-style
trace. Thus this rerun changes the vertical weights only, not masking policy.

Raw weight values are comparable across the bar boundary. Independently
normalized above/below values are NOT directly comparable physical magnitudes.
Higher raw weighted motion does not imply a uniformly higher normalized trace.
Motion can include residual paw/body/background contributions and moving-crop
effects; this analysis does not newly validate biological specificity.

## Inspection

`weight_comparison.svg` shows the old/new ramps. The two example
`*.comparison.svg` files show raw and normalized old/new traces versus original
frame number. These are exploratory algorithm comparisons, not group inference.
Previously generated debug videos still show the old weights and were not
replaced; they must not be labeled as views of this reweighting.
