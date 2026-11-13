# Tail-motion analysis

This is the maintained home for the extracted tail-motion MATLAB calculations. It contains code and provenance, not duplicate datasets or rendered figures. Existing measurements and scientific definitions are unchanged by this extraction.

From the repository root in MATLAB R2024b:

```matlab
addpath('BEAMCROSS/TAIL');
setupTail;
% Inspect an implementation without executing a batch job:
help bbtail.countD0FirstBelowBarPeaks
```

Adding the folder runs no analysis. Do not use `addpath(genpath(...))` to load historical scripts. Old function locations delegate to the package, preserving existing callers. `migration_manifest.json` records original and extracted implementation hashes. The original functions are also recoverable from the pre-cleanup working-state archive recorded in `../DRAFTFIGS/CURRENT/cleanup_result.json`.

## Implementations

|Stage|Package entry point|Purpose|
|---|---|---|
|Legacy video measurement|`bbtail.getTailMotionTrace`|Probability-weighted frame differences, temporal smoothing and robust normalization. Original vertical weighting and nonfinite behavior preserved.|
|Legacy crop/region measurement|`bbtail.getTailMotionMetrics`|Behind-centroid crops; whole/above/below-bar legacy calls. This is not the corrected whole-tail reweighting implementation.|
|Corrected below-bar trace|`bbtail.reweightTaraTailProfiles`|Reweight saved row profiles with the half-depth ramp; validate original trace reconstruction.|
|Corrected whole-tail trace|`bbtail.reweightTaraWholeTailProfiles`|Combine unchanged above-bar weights with corrected below-bar weights; independently normalize the whole trace.|
|Scalar motion height|`bbtail.extractTailHeight(datasetFile)`|Full-profile probability-weighted median motion location, contiguous-run five-frame smoothing, crossing summaries.|
|Frame-level export|`bbtail.exportTailCDFValues`|D0/D14 indexed frame cache with explicit frame mapping, validity and motion measurements. Retained as a shared input despite its historical CDF name.|
|Spatial exports|`bbtail.exportD0TailSpatialProfiles`, `bbtail.exportD14TailSpatialProfiles`|Per-trial10mm entry-relative bins, coverage and alignment checks.|
|Selected-trial peak measurement|`bbtail.countD0FirstBelowBarPeaks(day,selection)`|D0 first or D14 last retained crossing; below-bar raw-motion peaks, saved counts/events and full original filenames.|
|Below-bar episodes|`bbtail.countBelowBarMotionEpisodes`|Historical alternative based on motion-height episodes; distinct from the peak count labelled “tail slips”. Retained for its definitions and shared trial summaries, not an endorsement of this alternate endpoint.|

## Scientific definitions that must remain separate

- **Motion height is the location of image motion**, not a tracked anatomical tail position. Whole-tail score is also an image-motion measure, not a direct assay of tail control.
- Corrected below-bar weights rise from1 at the first below-bar row to2 at half depth, then stay2. Above-bar contributions are not redefined. Whole and below-bar normalizations are separate.
- The legacy video functions retain their original weighting and handling of degenerate data. They must not silently replace corrected saved-profile measurements. Existing comments/TODOs are historical implementation notes, not evidence that all cases have been validated.
- Scalar motion height preserves its existing invalid-pair mask. Spatial/frame exports additionally use the saved tail-bad mask where implemented. Do not unify these masks during code organization.
- Scalar score uses the established finite-frame sum/count (`sumLegacy/nLegacy`) from the corrected whole-tail summary. Spatial scores use their saved per-bin validity rules. A spatial curve is not necessarily a decomposition of the scalar summary.
- Peak count (“tail slips” in the assembled figure) uses `NewBelowRaw`, joint valid raw-motion/height samples, scale `1.4826*median(abs(x-median(x)))`, prominence5×scale and nominal0.1s separation within contiguous valid runs. Short-run distance capping and undefined zero-scale counts are preserved. This outcome was chosen exploratorily and is distinct from the primary slip detector. `tests/compareBelowBarPeaks.m` and the archived pilot preserve development history.
- First/last means minimum/maximum original **retained** trial number, not necessarily1/3. Selection and full source identifiers remain in saved tables.

## Data and execution policy

Read `DATA_SOURCES.md` before executing batch routines. This extraction deliberately preserves the existing output locations and workflow signatures; several exporters overwrite their historical CSV outputs. Reweighting routines refuse an existing output folder. They are not a safe “run everything” command. No batch analysis, video decoding, tracking, event redetection or measurement overwrite was performed for this extraction.

The next development step is explicit input/output configuration and fresh-output execution, followed by frozen-result parity checks. Do not change algorithms at the same time. This package is a consolidated implementation, not a claim that every batch stage has been rerun after migration.

## Validation

```matlab
addpath('BEAMCROSS/TAIL/tests');
checkTailExtraction;
```

This lightweight test checks package discovery, repository resolution, legacy wrapper equivalence and zero-motion shape. Extraction-time comparison also checks against the pre-extraction trace function on fixed synthetic input. It does not validate new biological measurements or rerun the full dataset. `VALIDATION.md` records what actually ran.

## Related code kept outside this package

- `BEAMCROSS/prepareTailMetricsTrial.m`, `validateTailMetricsPreparation.m`, `createTailMetricsDebugForTrial.m`, `createTailMetricsDebugVideo.m` and `private/` support data reconstruction/debug rendering; see `../TAIL_METRICS_WORKFLOW.md`. They are not relocated because their private-file dependencies need a separate extraction.
- `DRAFTFIGS/tail-metrics/whole-motion-reweighted/analyze.py` aggregates corrected scalar scores; `cage_tests.py` is shared behavioral inference, not a tail-specific detector. These remain linked rather than duplicated.
- `tests/analyzeWithinSessionBB.m` and `analyzeLastCrossingPairedBB.m` consume the saved tail metrics alongside other behavior.
- Tail plot, Illustrator layout and example-image scripts remain presentation utilities under `tests/`.
