# Inputs, outputs and provenance

Repository-relative paths are resolved by `bbtail.repositoryRoot`.

|Resource|Location|
|---|---|
|Original validated profile/trace results|`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106`|
|Corrected below-bar results|`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109`|
|Corrected whole-tail results|`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110`|
|Repository corrected below-bar copy|`BEAMCROSS/results/tail_reweight_L40_halfdepth_20261109`|
|Trial identity/group/cage manifest|`BEAMCROSS/DRAFTFIGS/analysis-data/trial_manifest.csv`|
|Scalar corrected whole-tail summaries|`BEAMCROSS/DRAFTFIGS/tail-metrics/whole-motion-reweighted/trial-values.csv`|
|Scalar motion-height summaries|`BEAMCROSS/DRAFTFIGS/tail-metrics/height-exploratory/trial-motion-height.csv`|
|Frame cache/index|`BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/frame-values.csv` and `trial-index.csv`|
|Spatial bins|`BEAMCROSS/DRAFTFIGS/tail-metrics/D0-spatial-motion-and-height/trial-position-bins.csv` and corresponding `D14-minus-D0-spatial-motion-and-height/`|
|Retained D0 trial selection|`BEAMCROSS/DRAFTFIGS/D0-first-trial-panels/trial_values.csv`|
|D0-first/D14-last peak counts and events|`BEAMCROSS/DRAFTFIGS/tail-metrics/below-bar-episodes/peak-pilot-strict/`|
|Final-figure provenance index|`BEAMCROSS/DRAFTFIGS/CURRENT/README.md`|

`extractTailHeight` takes the historical dataset MAT file explicitly; it expects `dataset.trials`, with `fileName` and `rowProfiles`. No new dataset path is assumed. The function still writes the original height-summary folder.

All filename joins preserve complete original filenames. Temporal validation uses original-frame indices, traversal-frame indices, saved timestamps, invalid-pair and tail-bad flags. The fixed calibration is700/1201mm per pixel; spatial bin exports use the existing tape bounds and10mm bins. No source data were copied into this package.
