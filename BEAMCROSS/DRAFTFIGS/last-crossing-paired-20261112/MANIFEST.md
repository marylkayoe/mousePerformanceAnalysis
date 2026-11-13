# Storage and restart manifest

- Code repository and root for relative source-checksum paths: `/Users/yoe/Documents/REPOS/PROJECTS/mousePerformanceAnalysis`.
- Canonical source video root (not read in this task): `/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved`.
- Canonical validated L40 measurements: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106`; corrected whole-tail source: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110`.
- This task reads the established small measurement tables in the repository; exact paths and SHA256 values are in `SOURCE_SHA256.txt`. No tracking or source-video reads.
- New canonical review package: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_last_crossing_paired_20261112`.
- Repository review copy: `BEAMCROSS/DRAFTFIGS/last-crossing-paired-20261112`.
- Main figures: `A_four_selected_outcomes` and `B_four_selected_outcomes`, each SVG plus PNG. Earlier duration-containing figures remain supplementary.
- Primary full retained sample; exact original 1/2/3-both sensitivity. Definitions, estimates and selection-history/multiplicity notes: `REPORT.md`.
- Source scripts: `tests/analyzeLastCrossingPairedBB.m`, `tests/summarizeLastCrossingBB.m`, `tests/focusLastCrossingBB.m`. Canonical package includes standalone copies for provenance; run them from the repository's tests folder with source paths intact.
- MATLAB R2024b and Statistics and Machine Learning Toolbox. No RNG, worker pool or new dependencies.
- Approximately 2.6 MB review outputs in each location. Source scripts, small tables/reports, checksum manifests and review figures fit the established small figure-workflow repository policy. Not committed or pushed.
- No bulk scratch, copied videos, large binaries or files intended for deletion. Approximately 2.6 MB task output on internal SSD; free space remained about 31 GiB at completion.
- Existing Illustrator master and all files directly under `last-crossing-D14` were hash-verified unchanged against `EXISTING_FILES_BEFORE.sha256`. Existing local modifications were preserved, not reverted.
