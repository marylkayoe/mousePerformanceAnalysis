# Project facts

- This repository is part of Tara's project (confirmed by the user).

- Code repository: `/Users/yoe/Documents/REPOS/PROJECTS/mousePerformanceAnalysis`.
- Verified balance-beam source videos: `/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved`. Read these in place.
- Tara project persistent-results root: `/Volumes/ShosaiData/DATA/Tara/RESULTS`. The stop-exclusion comparison is recorded in `tests/README.md`. Retain this established location rather than inventing a replacement under the global `/Volumes/ShosaiData/PROJECTS` default.
- Agent scratch root for this behavioral-analysis repository remains unconfirmed. `/Volumes/ShosaiData/AGENT_WORK/TARA_IO_PLASTICITY` was explicitly designated for the IO project; do not assume it applies here. Confirm the scratch destination before creating bulk temporary outputs. Do not move existing source data or results implicitly.
- Source filenames encode cohort, subject, trial/session, camera, beam day, recording date, and trial number. Preserve complete original filenames in result tables.
- Paired parameter comparisons must use identical source files and all other parameters unchanged. Preserve numerical failures and nonfinite results explicitly; successful function return does not establish valid scientific output.
