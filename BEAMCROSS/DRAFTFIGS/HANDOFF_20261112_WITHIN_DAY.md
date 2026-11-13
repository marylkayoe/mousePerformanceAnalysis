# Continuation handoff — within-day crossings, 2026-11-12

## Start here: user intent and stopping point

User asked to stop plot iteration and update the handoff for another agent. Latest example first/last spatial speed overlay **did not work for their purpose**. Do not keep polishing it or treat it as an accepted main-figure panel.

The current question is methodological: **does baseline performance change over the session, explaining why the choice of crossing matters?** User wants to investigate deterioration, not manufacture significance, compare three future treatment groups at baseline, or claim stamina. At D0 there has been no treadmill exposure, so user explicitly requested pooling SED/WALK/RUN. Cages/cohorts still matter for uncertainty. They want first versus LAST retained crossing, not “trial3”: mice sometimes refused/failed intervening attempts. Original trial numbers and retained order differ. Last retained is not verified to be the last attempted trial when failed attempts are absent from data.

We initially showed crossings1/2/3, then simplified to First/Last at user's request. Current panels still use **41 mice with exactly3 retained D0 crossings**, not all42 with at least2; the two-crossing mouse was excluded to match earlier analyses. Now that the target is first/last, revisit that inclusion rule explicitly if appropriate; do not silently retain it as scientifically necessary. D0/D14 matched comparisons similarly use41 mice, despite42 eligible D14-only mice. No final figure design accepted.

## Git and storage

HEAD checked: **e52c789**. There are37 untracked status entries (directories count as entries), including substantial figure work since that commit. **Nothing from this continuation has been committed/pushed.** User requested only handoff now, not commit. Preserve everything; check status before syncing. Main code/source data unchanged. New small SVG/PNG/CSV/code outputs are in repo under user-requested figure workflow. ShosaiData canonical data/results locations unchanged, no bulk scratch or copied source videos. New files are not verified available via Proton/Air.

Read AGENTS.md and previous FIGURE_HANDOFF_20261111.md / STATISTICS_HANDOFF_20261111_EVENING.md for earlier scientific decisions. Older docs mention outdated HEAD/commit state. Group allocation/randomization descriptions conflict across historical notes: do not assume randomization verified.

## Current files: all relative to BEAMCROSS/DRAFTFIGS/

Main new folder: **D0-within-day-trials/**. Figures remain editable SVG plus PNG previews, accompanying CSVs and methods. Scripts in repository tests/.

### Pooled baseline first/last (most recent overall panel)

- `D0_pooled_first_last_speed_and_slips_with_stats.svg/png`
- Unannotated counterpart `D0_pooled_first_last_speed_and_slips.svg/png`
- Older3crossing version `D0_pooled_three_crossings_speed_and_slips[_with_stats].svg/png`
- Sources/summary/exclusions named alongside stems.
- Generators `plotD0PooledTrialOrder.py`, `plotD0PooledFirstLast.py`, `testD0PooledFirstLast.py`, `annotateD0FirstLastOnly.py`.

Three metrics: locomoting speed (stops excluded), slip count, total slip score. Gray paired mice, black equal-mouse mean and pointwise95% whole-cage bootstrap intervals. Stratify resampling by cohort, resample whole cages carrying all mice and observations, ratio of sums to sampled mouse count.10000 draws, seed20261112. 41mice/15cages; no group colors or group comparisons. Means first→last: speed120.0818→115.7687mm/s; count6.4390→8.0976; total852.804→1300.801a.u.×frames. Total plotted in thousands. Slips during stops retained.

### **Statistical issue requiring review before reuse**

`D0_pooled_first_last_statistics.csv/json` and `D0_POOLED_FIRST_LAST_STATISTICS.md`:

| Metric | Last−first | bootstrap95% CI | paired cage sign-flip raw p | Holm3 |
|---|---:|---|---:|---:|
| Speed | −4.3131mm/s | −8.2094,−0.5293 | .16693 | .23425 |
| Slip count | +1.6585 | .1395,3.4146 | .06995 | .20984 |
| Total slip score | +447.997 | 6.136,928.014 | .11713 | .23425 |

Tests enumerate all32768 signs of15 cage SUMS of within-mouse changes, divide by41, compare absolute mean. Joint cage sign symmetry assumed; independent cages; not randomized trial-order inference. Test does **not** model cohort mean differences, whereas CI resamples within cohort. Thus bootstrap CIs all exclude0 but sign-flip p-values are all>.05. This was reported to user as different approximations/assumptions, **but should be reconciled carefully, not dismissed or presented as settled**. Examine cohort-specific means, weighting, model/estimand, coverage/calibration and robust paired inference. Do not select a test to obtain significance. Current displayed p-values belong to this specific method, not previous regression.

Earlier `analyzeD0WithinDayTrials.py` / `statistics.json/csv`, `REPORT.md` fits cage contrast vectors(trial2−1,trial3−1) on group+cohort, estimates equal-group/equal-cohort marginal effects. Omnibus Hotelling F; separate t first/last and HC3. Speed−7.51mm/s raw first/last p.01098; overalltrial p.0413. Count overall.1187; total overall.01217. Those are DIFFERENT weighting/model than pooled means. Do not transfer p-values to pooled figure uncritically. User has been confused by changing statistics; avoid further unmotivated test switching.

### Spatial speed correction — critical

User explicitly: **exclude stops**. Initial spatial speed plots reused `speed-presentation/speed-profile-source.json`, which includes stops. Those figures are NOT correct for the requested locomoting-speed comparison.

Corrected generator `tests/plotStopExcludedFirstLastCDFs.py` reads164 canonical L40 `.trace.csv` files in place, removes StopMask=true **before spatial bin means**, checks all counts and whole-trial mean against asset meanSpeedLoco within1e-7px/s. Also excludes nonfinite speed/centroid values. Existing10camera-pixel bin edges, tape bounds42..1243, mmconversion700/1201. NaNs/empty bins preserved, no extra smoothing. Matched valid bins across all4crossings(first/last D0/D14) within each of41mice;113–120bins/mouse. Equal bins within mouse, equal mice within group. Support can differ between mice.

Corrected files:
- `D0_first_last_speed_spatial_STOP_EXCLUDED_CDFs.svg/png/csv`
- `D14_first_last_speed_spatial_STOP_EXCLUDED_CDFs.svg/png/csv`
- `D0_stop_excluded_spatial_source.csv`, `D14_stop_excluded_spatial_source.csv`
- `stop_excluded_CDF_validation.csv`, `STOP_EXCLUDED_CDF_README.md`

First dashed,last solid, three group panels. D0 little shift; D14 SED/WALK visibly slowerlast, RUN lessshift. No correctedCDF significance tests performed. Descriptive distributions of spatial-bin mean speeds, not independent frames/animals. Earlier `D0_first_last_speed_spatial_CDFs` and `D0_speed_along_beam_last_minus_first` include stops and are superseded for current question. Earlier whole-D0/D14 spatial speed CDFs also used stop-including profiles; assess if rest of figure needs consistent correction.

Scalar mean-speed CDFs (`D0_first_last_locomoting_speed_mouse_CDFs`) were another misinterpretation: ECDFs of one scalar/mouse. User wanted spatial CDFs instead. Keep as historical alternative only.

### Rejected example overlay (last task)

`TMCS2_S18_D0_first_last_spatial_locomoting_speed.svg/png/csv/md`, script `plotExampleFirstLastSpeedProfile.py`.
Full original filenames:
- TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL1_gray.mp4
- TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL3_gray.mp4

First gray dashed,last blacksolid. Stop-excluded existing spatial bins, no extra smoothing, finite bins independently for each crossing(gaps preserved), startleft0–700mm. Whole-crossing locomoting speed133.369→129.459mm/s. Last crossing is fastermuch ofmiddle,slowernearfinish; not uniform deterioration. **User said “no, this isn't working” and requested handoff.** Do not choose a different mouse just to amplify decline without making selection transparent.

### Grouped scalar/paired plots and slip CDFs

Speed:
- `D0_locomoting_speed_last_minus_first_scatter` (change)
- `D0_locomoting_speed_first_and_last_paired` (absolute first/last, groups)
Scripts `plotD0WithinDaySpeedScatter.py`, `plotD0FirstLastSpeed.py`.

Slips:
- `D0_D14_first_last_slip_metrics.svg/png` and `_with_stats`
- `D0_D14_first_last_slip_event_CDFs_with_stats.svg/png/csv`
- `first_last_slips_statistics.csv`, `_event_values.csv`, `_validation.csv`
- `FIRST_LAST_SLIP_STATISTICS.md`
Generators `plotFirstLastSlipMetrics.py`, `testFirstLastSlips.py`.

User said keep all3scatters AND add eventCDF, not replace total-score scatter. Scalar count, totalSlipMagnitude, meanperevent=total/count. Zero-slip mean/CDF undefined, neverzero. Complete first/last pairs per metric/day; D0 all41, D14 event-size outcomes11SED/12WALK/15RUN. Count/total include zeros. CDF uses individual event scores but equal-mouse weighting, log10score x-axis, firstdashed/lastsolid. Event scores reconstructed sum(max(MovementTrace−2.5,0)) over inclusive event frames;164trial counts/totals matched. Include slipsoverlappingstops. Raw paired sign-flip p-values within group displayed; groupcohort-average cage changes. Fourcages in SED/WALK → minimumtwo-sidedp.125;7RUN→.015625. D14RUN totalscorep.03125(Holm3.09375), meanperevent.0625, count.09375, CDF.515625. NoCDFtests significant. Small-cage signflip resolution explained to user; this is one reason within-group tests were not addressing user's pooledbaseline intent. Between-group scalar change tests saved separately in `slip_*_D*_between_group_trial_change.json`; not mainfocus.

## Earlier uncommitted continuation since e52c789

These also need preservation/review by next agent; they preceded current D0discussion:
- `D14-crossing-comparison/{first,last,all}/`: matching9metric figures with shared axes, standalonepanels,data/stats; `tests/plotD14CrossingComparison.py`. All daily count/total dividedby3 to per-crossing forcomparison; other establisheddailyaggregation retained. Firstminretained, lastmax. Contactsheet. User wanted visualcomparisonwithTara.
- `last-crossing-D14/`: nine metric lastretainedD14scatters and direct exactcagepermutationstats;42mice,meanperevent40. `plotLastCrossingD14.py`.
- `last-crossing-spatial/`: posture,speed,tailheight,tailmotion ×D0,D14,change12panels. `plotLastCrossingSpatialProfiles.py`. Speed includesstops (needs correction if reused forlocomoting).
- `last-crossing-D14/ordered-pattern-tests/`: orderedscalar tests. `testLastCrossingOrderedPatterns.py`. Speed eitherdirectionGaussianp.0037,wild.0034; not whole-spatial-curveinference.
- `speed-presentation/speed-maintenance-decomposition/`: descriptive first/later contribution todailymean. `decomposeSpeedMaintenance.py`; not causal fatigue/stamina.
- `speed-presentation/within_day_locomoting_speed_change_D14.*`:100*(last/first−1),42mice,meansSED−14.92%,WALK−12.79%,RUN−.074%. `plotD14WithinDaySlowing.py`. D14omnibus.0375;RSraw.0397,RW.0595,bothHolm.119.
- `D7-change-overview/`: nine metrics pairedD7−D0,scatter/statstable. `plotD7ChangeOverview.py`.
- `SLIPS&STOPS/mean-slip-event-score/`: D0/D14/change meanindividualslipsize(notmedian,totalperday/countperday). `plotMeanSlipEventScore.py`.
- `CDF-overview/`: five metric×D0/D14/change summary. `plotCombinedCDFOverview.py`;speedstopcorrectioncaveatabove. TailCDFweighting differsscalar(frame/mouseweight,strictpairvsLegacy masks); notsameestimand.
- `outcome-specific-contrasts/crossing-duration/`: `analyzeCrossingDuration.py`. Meansecs/crossing. D14SED6.32,WALK5.30,RUN4.61. DirectRS.01587,changesns,ANCOVAuncertain.

## Practical continuation guidance

Use richPython `/Users/yoe/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3` (NumPy/Pillow; noSciPy/statsmodels). DirectSVG editing, not imagegeneration. No new videos/tracking needed for these panels. Do not overwrite or delete exploratory outputs without approval. User tired/frustrated, wants agenthandoff not more plot proposals. Be precise about meanpertrial,totalperevents,meanperevent,spatialCDF,andtimeweighting. Retain exact original filenames and stopmask provenance. Do not conflate no groupdifference with no within-sessionchange. No fatiguecausality inferred. Next substantive step should resolve intended population(first/last available all42?) and consistent pooled inference before additional conclusions.

## Below-bar motion episode counts (2026-11-12)

User requested counts from negative vertical motion height. Implemented tests/countBelowBarMotionEpisodes.m; compact outputs in tail-metrics/below-bar-episodes/ (README, episodes.csv, trial_summary.csv, validation.json). All 377 trials, unchanged canonical sources. Strict height<0 on full-profile probability-weighted median motion height with original five-frame mean; invalid gaps never bridged. Distinguish negative segments, observed downcrossings, complete episodes; retain censoring, filenames and original frames. 1506 negative segments total; D0/D7/D14 449/658/399. 251 cached D0/D14 traces match all boundaries/counts exactly via tests/validateBelowBarEpisodes.py. D7 has no independent cache. Initial movmean near-zero rounding discrepancy resolved using exact original explicit mean loop. Not anatomical tail dips; no group inference or video review yet. Tables include valid-time-below-zero fraction and observed durations.
