# Current balance-beam figure: handoff, 2026-11-11

> **Latest continuation:** Read [STATISTICS_HANDOFF_20261111_EVENING.md](STATISTICS_HANDOFF_20261111_EVENING.md) before continuing. It documents everything since commit `d29bb45`: prioritized comparisons, D14/change differences, ANCOVA and mouse-independent sensitivities, ordered-trend tests, the seven-panel figure, and unresolved main-figure choices. Historical “uncommitted” notes below are superseded by Git history.

## Plot cleanup update

After this handoff was written, the user requested keeping only current-figure plots plus recent CDFs.145 unused plot assets were checksum-archived outside the repo to `/Volumes/ShosaiData/DATA/Tara/RESULTS/figure_plot_archive_20261111`. Data/statistics/scripts remain. See [CURRENT_PLOT_INDEX.md](CURRENT_PLOT_INDEX.md) and [PLOT_CLEANUP_20261111.csv](PLOT_CLEANUP_20261111.csv). Historical plot paths below may now refer to the same relative path in that archive. No commit/push yet.

## Read this first

This is the panel-by-panel continuation record for the user's Illustrator figure shown in chat on 2026-11-11: methods and D0 characterization above, paired D14−D0 outcomes below. Paths below are relative to `BEAMCROSS/DRAFTFIGS/` unless stated otherwise. This updates the presentation decisions in the older `HANDOFF.md` without replacing its useful data/movie provenance.

**The screenshot is a manually assembled Illustrator layout, not a verified export of one repository script.** We have made editable source panels, tables and reproducible scripts; we have not edited or validated the complete Illustrator master. Its exact file path is not established here. Some labels/scale lengths have been manually changed: do not assume the screenshot equals an unmodified source SVG.

Current repository HEAD: `60d5756`. Many figure assets and scripts are untracked or modified; this work has NOT been committed or pushed in this session. Check `git status` before syncing. Do not overwrite or discard any local work. No source video or original analysis pipeline was modified for these figures.

## Biological question and current presentation choice

Does treadmill experience alter balance-beam behaviour, alongside the separately studied IO neuropil changes? WALK was included as an active control for lower-intensity activity/handling/treadmill experience, to distinguish those from intensive RUN training. SED is sedentary. WALK is not a pure control for one psychological variable. Pooling WALK and RUN loses this distinction and has NOT been adopted. No new primary testing hierarchy has been settled. Do not retrospectively remove multiplicity correction because a particular contrast looks promising.

Current main figure: explain the method and baseline D0 behaviour, then show paired **D14−D0 changes** consistently across outcomes. Keep D14-only results and alternative CDF analyses available as supplements. This choice follows the biological question, not significance. D7 exists and was explored; preserve it in the broader project, but it is not the current main figure focus. Analyses and choices are exploratory, not preregistered.

## Canonical locations and environment

- Code: `/Users/yoe/Documents/REPOS/PROJECTS/mousePerformanceAnalysis`.
- Videos, read in place: `/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved`.
- Persistent results root: `/Volumes/ShosaiData/DATA/Tara/RESULTS`.
- Original validated L40 rerun: `balance_beam_events_traces_L40_20261106` under that root.
- Corrected whole-tail results: `balance_beam_whole_tail_reweight_L40_halfdepth_20261110` under that root. Distinguish from the earlier below-only reweighting.
- Bulk scratch root remains unconfirmed. Do not create bulk outputs elsewhere or copy videos implicitly. Read `AGENTS.md`.
- MATLAB CLI: `/Applications/MATLAB_R2024b.app/bin/matlab -nodisplay -batch "addpath('tests'); FUNCTION"` (requires normal sandbox approval).
- Figure Python used: `/Users/yoe/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`; NumPy/Pillow, direct SVG, Arial. SVG text/paths are editable; PNGs are previews.
- Existing Proton locations are documented in older `HANDOFF.md`; availability and synchronization of these NEW panels were not verified. Do not claim they are on the Air/Proton/GitHub.

## Design, counts and statistical conventions

42 retained mice: SED12, WALK12, RUN18. Fifteen cohort-specific cages: SED4, WALK4, RUN7. No cage in the retained data has members in different groups. Cohort TMCS2: SED C08/C10; WALK C02/C03/C06; RUN C01/C04/C05/C07/C09. TMCS3: SED C03/C05; WALK C02; RUN C01/C04. These assignments were checked in `analysis-data/pooled-exposures.csv` across days. This establishes retained membership, NOT allocation randomization or excluded cage-mate history.

D0 retained crossings: SED36, WALK36, RUN53 (125 total). D14:36/36/54 (126). `TMCS2_S10` has only two retained D0 crossings. Count, total-slip-score and stopped-time percentage analyses require three crossings per included day: D0/change have41 mice (RUN17); D14 has42. Tail and speed/posture summaries generally retain42 mice, including the two-crossing mouse. Earlier direction-filtered spatial studies sometimes have52 RUN D0 crossings; do not use that count universally.

Standard scatter: mouse dots, cohort-specific cage-mean diamonds, equally weighted mouse group-mean bars. Black SED, green WALK, blue RUN; mean curves often #232323/#00B226/#002BFF; scatters use existing darker green/blue with translucent coloured mouse dots. Preserve that established style. No statistics paragraphs under scatter axes; significance bracket only when the relevant Holm-adjusted pair is <.05.

Statistical implementation: `tail-metrics/whole-motion-reweighted/cage_tests.py`. Aggregate mouse values to cage means; exact cage-label permutations within cohort. Pairwise statistic is equally cohort-weighted cage-group difference, two-sided. Omnibus uses cohort-adjusted group regression statistic. Holm over THREE group pairs within each outcome/period, NOT across outcomes, days, alternative definitions or exploratory tests. Displayed mouse-weighted means and SEM are not the cage/cohort-balanced tested estimand.

Nonrandom allocation was raised by the user. Exchangeability of cages within cohort is an assumption, not established by design; clustering correction cannot remove allocation confounding. Whole-cage groups are not inherently a design failure. Do not say nonsignificance establishes equivalence/no effect. Raw vs Holm p-values must be identified. Positive overall test does not identify a specific pair.

## Methods panels: upper left

### Beam apparatus and group counts

User-built schematic: 70 cm between tape marks, start on left in final presentation. The apparatus art itself was not generated/validated this session. Group-count table should be4/12/36,4/12/36,7/18/53 for cages/mice/D0 crossings; not every analysis uses all125 crossings. Explain exclusions in caption/methods.

### Example image, centroid and detection regions

Methods example is **TMCS2_S18 D0 trial2**, full filename `TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4` (RUN). Clipped/traversal frame514 = original frame1369, traversal original856–1822,967 frames,160fps. Do not confuse it with runner D14 demo trial2 or D14 presentation trial1.

Assets: `figMaterials/TMCS2_S18_D0_T2_f514_centroid_trajectory.svg`; current region illustration `TMCS2_S18_D0_T2_f514_slip_gradient_tail_weightbar_purple.svg` and companion JSON/source variants. White centroid, editable black trajectory. Image contrast was enhanced for illustration; source preserved. Slip-region boundary/depth is a **schematic**, approximately body-height deep, NOT a hard detection mask or literal algorithm crop. Read weights/schematic JSONs. The detector uses gradual mouse probability and distance weighting. Tail rectangle shows relevant post-mouse region; purple side strip encodes vertical weights.

Parameters: LOCOTHRESHOLD40, SLIPTHRESHOLD2.5, MOUSESIZETHRESHOLD2. Calibration700/1201 mm per original pixel, used approximately vertically too; common tape calibration, not per-trial physical recalibration.

### Example forward speed, stopping and slip-event score

`figMaterials/TMCS2_S18_D0_T2_forward_speed_stops.svg` and CSV/JSON. Forward speed mm/s vs time since traversal start; blue spans mark saved stops, not slips. Below it: `TMCS2_S18_D0_T2_under_bar_motion_slips_downward_areas.svg`. Detector trace plotted downwards for illustration, threshold2.5, orange event-peak dots and event-area shading. Score per event = sum(max(MovementTrace−2.5,0)) over inclusive detected event frames. It is a.u. × frames, not a physical paw depth or an integral in seconds. Scores combine weighted under-bar movement, speed adjustment, normalization and duration. Do not call them unqualified anatomical slip severity. Main counts/scores include slips overlapping stops. No duration normalization has been adopted.

### Tail example traces and two stills

`figMaterials/TMCS2_S18_D0_T2_tail_height_with_score_bottom.svg` is a source for black motion-height trace + purple score below; user manually arranged it. Sources/definitions in `TMCS2_S18_D0_T2_tail_example_traces.json`, CSV and median-source CSV. Earlier coloured-line and slip-marker versions are alternatives, NOT the selected design. User removed slip markers here.

Tail height: full probability-weighted row-motion median relative to detected bar top; NO vertical-distance ramp in the height index. Centered five-frame mean only within contiguous valid runs, shrink at edges, never bridge invalids; no5mm blanking. It measures where image motion occurs, not position of a stationary anatomical tail.

Motion: corrected whole-range `NewWholeNormalized`. Above-bar original cubic ramp rises to1 at bar; beam interior1; below-bar starts1, rises to2 halfway to bottom, then stays2. Destination-frame probability weighting, original five-frame smoothing and trial median/MAD normalization retained. Negative normalized values are valid. Post-mouse motion can contain paws/body/crop/background contributions.

Stills: `figMaterials/tail_motion_example_stills/nine_frame_averages/contrast_variants/strong_center_emphasized_f1186_20mm.svg` and `strong_center_emphasized_f1639_20mm.svg`. Centres: original1186 = traversal331 =2.0625s; original1639 = traversal784 =4.89375s. Nine-frame composites centre±4, .5 centre + .5 nine-frame average (effective centre5/9, each other1/18). Strong identical contrast mapping110–225 to0–255; no generation/background fabrication.20mm scale. Caption must say temporal composite, not single raw frame. These illustrative high/low examples are not proof of group effects.

## Baseline D0 panels: upper right

### Posture and speed trajectories + scatters

Retained source families: `posture-presentation/posture-by-day-uncentered-mm.*`, `posture-height-statistics-mm.*`; `speed-presentation/speed-by-day-mm.*`, `speed-by-group-mm.*`, `locomoting-speed-statistics-mm.*`; compact D0 speed scatter in `figMaterials/forward_speed_D0_group_comparison_illustrator.*`.

Spatial profiles describe position-dependent behaviour; scatter exposes individual/cage variation. These complement each other; CDFs were NOT chosen to replace them in main figure. Uncentered centroid height, no trial centering; SEM bands. Spatial speed profiles include stops; scalar locomoting speed excludes stopped frames. Thus screenshot label “Locomotion speed” on a spatial curve may need “Forward speed.” Spatial profiles and scalar summaries differ in weighting, not exact decompositions of each other.

Source MAT/JSON: `analysis-data/speed-absolute-position-data.mat`, `speed-presentation/speed-profile-source.json` (`speedRelative`/`trialSpeedRelative` names misleading: absolute px/s); `analysis-data/posture-by-position-data.mat`, `posture-presentation/posture-profile-source.json`. Scalar tables under `analysis-data/weighted-speed/` and `analysis-data/posture-statistics/` (legacy filenames `tail-days.csv`/`tail-changes.csv` there actually mean POSTURE). Convert px or px/s by700/1201.

### D0 slips and stopping

`SLIPS&STOPS/slip_count_D0_mouse_cage_comparison.svg`, `stop_time_percentage_D0_mouse_cage_comparison.svg`. Count total over3crossings; percent stopped =100*sum validated stopped-frame seconds / sum tracked traversal seconds. Prefer percent stopped to stop count because brief intervening motion can split a stop. Keep stop count for table/supplement. Percent denominator includes all traversal time, not locomoting time.

CDF in middle is EVENT-score distribution, NOT total mouse score: `figMaterials/D0_slip_score_CDF_reference_fraction_log10.svg`, exact user95.04×85.54 geometry. Earlier source `D0_slip_magnitude_group_CDF_mouse_weighted.*`; adapted by `tests/restyleD0SlipCDFReference.py`. Mean of each mouse's event CDF, equal mouse weight (not equal cage/event weight); all900 D0 events including stops/outside tape,42mice. x shown as exponents should say log10(slip-event score), y fraction0..1. No clipping. Baseline overlap is not equivalence.

### D0 tail spatial profiles and scatters

`tail-metrics/D0-spatial-motion-and-height/`: Height/Score spatial plots, group/mouse/trial bin tables; `tests/exportD0TailSpatialProfiles.m`, local `plot_profiles.py`.10mm bins; within-crossing finite-frame means, equal crossing means within mouse, group mouse mean±SEM. At least halfgroup contribution to show bin. Blank entry region is missing valid tail coverage, not zero. No new spatial smoothing/tests. Height bin summary is a MEAN, unlike scalar median-based height.

Scatters: `tail_height_D0_mouse_cage_comparison.svg` and `tail_score_D0_mouse_cage_comparison.svg` in `tail-metrics/`, script `tests/plotD0TailStandalonePanels.py`. Height uses `height-exploratory/mouse-day-motion-height.csv:medianHeight`: mean across crossings of each crossing's median valid smoothed motion-height values. Score uses `whole-motion-reweighted/mouse-day-values.csv:meanLegacy`: corrected whole-range normalized score pooled across finite samples, thus crossing frame-count weighting.

**Important mask distinction:** Legacy scalar score includes443 invalid pairs not tail-bad across the full dataset (documented in whole-motion README). Strict/raw sensitivity outcomes exist. New spatial/CDF analyses explicitly exclude invalid pairs AND tail-bad frames. Do not claim their source sample selection is identical. Do not silently switch the main scalar outcome to Strict, or transfer its p-value to another definition. Main screenshot's “Tail motion mean above bar” on the height scatter is misleading: use “Motion height, D0” (mm relative to bar); it is neither above-only motion nor mean anatomical tail position.

## Change panels: bottom of current figure

### Posture and speed, paired spatial profiles + scalar scatters

Latest reference-style posture: `posture-presentation/posture_D14_minus_D0_profile_and_scatter_reference_style.svg`; related `*_clean`, `*_scalebars` are earlier layouts. Standalone reference scatter `posture_change_scatter_reference_style.svg`. Scripts `tests/plotPostureChangeClean.py`, `plotPostureChangeReferenceStyle.py`; original combined composition was inline, not a dedicated reproducible composer. `tests/joinSpatialProfileSVGPaths.py` repaired original segmented paths. All future curves should be ONE path per contiguous finite run, round joins/caps; don't create visible wedges between short segments.

Speed latest: `speed-presentation/speed_D14_minus_D0_profile_and_scatter_reference_style_tight.svg`; script `tests/plotSpeedChangeReferenceStyle.py` calls `plotSpeedChangeClean.py`. Profile lower space tightened, all SEM bands preserved. Scatter−55..100mm/s with ticks−50/0/50/100. Script vertical scale50mm/s, horizontal10cm. User screenshot appears to relabel vertical speed scale25mm/s: verify actual rescaling; changing label alone is wrong.

Spatial changes: within each mouse subtract D0 from D14 at the same bin, then mean±SEM; require at least halfgroup paired finite coverage; no bridging missing bins. Source camera x35..1255; distance=(1255−x)*700/1201, entry-side profile boundary rather than independently detected tape mark. Scalar paired changes use saved whole-crossing summaries. Posture scatter±3mm ticks±3/±1.5/0; statistics omitted for square layout. Mean bars are mouse-weighted. Main figure shows descriptive profiles, not significant spatial regions.

Speed renderer currently can add one significant-bin strip from `speed-presentation/spatial-change-tests/binwise_tests.csv`; user did NOT find this compelling and current screenshot omits it. Preserve results but don't reintroduce silently: exploratory full-beam max-absolute-difference test +3-pair correction yielded one bin around414mm (p=.047619), not a whole central region. Bin width~5.83mm, not1mm.

### Slips/stopping change triptych (most recent request)

**Use `SLIPS&STOPS/D14_minus_D0_slip_count_score_time_stopped_three_panels.svg`**; PNG alongside. Standalone `slip_count_D14_minus_D0_mouse_cage_comparison.svg`, `slip_magnitude_D14_minus_D0_mouse_cage_comparison.svg`, `stop_time_percentage_D14_minus_D0_mouse_cage_comparison.svg`.

Scripts under repo `tests/`: `plotD14SlipCountIllustratorPanels.py change`, `plotD14SlipMagnitudeIllustratorPanels.py change`, `plotStopTimePercentageChangePanel.py`, then `combineSlipStopChangePanels.py`.

41 paired mice; require3crossings/day; include stop-overlapping slips. Sum slip count or event scores within day then subtract D0. Score display×10³ a.u. (underlying event sum has frame units). Time-stopped change is **percentage points**, not relative percentage change. Grey zero line; no significant pairwise brackets. Means: slip count SED−7.17,WALK−8,RUN−8.71; total score−2102.19,−843.41,−786.42; stopped%−3.54,−0.83,−4.18pp.

Earlier D14 endpoint triptych `D14_slip_count_score_time_stopped_three_panels.svg` remains for supplement. Its stopped-time SED–RUN star must NOT be copied to the change plot.

### Tail change scatters

`tail-metrics/tail_height_D14_minus_D0_mouse_cage_comparison.svg` and `tail_score_D14_minus_D0_mouse_cage_comparison.svg`; script `tests/plotD14TailStandalonePanels.py height|score change`.42paired mice. Height unitsmm; scorea.u.; same scalar definitions as D0 above. Current figure places HEIGHT then SCORE. `tail_motion_height_D14_and_change_four_panels.svg` has motion above/height below, D14left/change right and is a convenient donor, not the final full-figure layout.

SED–RUN score-change star uses saved Legacy whole-motion pair Holm p=.0238095. Height no adjusted pair significant. Do not describe the score reduction as proven improved tail control. “Motion-score changes differed between runners and sedentary mice” is the measured claim under current exploratory tests/assumptions.

## Statistics quick reference (current scalar main panels)

Overall unadjusted; pairs Holm within three comparisons. Order SED–WALK / SED–RUN / WALK–RUN:

| Outcome | D14 overall | D14 adjusted pairs | Change overall | Change adjusted pairs |
|---|---:|---|---:|---|
| Slip count | .0276 | .5667 / .0714 / .1429 | ~.965 | 1 / 1 / 1 |
| Total slip score | .9897 | 1 / 1 / 1 | .4419 | .6429 / .6429 / .8393 |
| Stopped-time percentage | .04475 | .3333 / .04762 / .2619 | .63786 | 1 / 1 / 1 |
| Whole-tail score Legacy | .0188 | see source | .0154 | SED–RUN .02381; see source for other pairs |

Authoritative sources: `SLIPS&STOPS/slips-stops-D14-group-comparisons.csv`; original `slip-count-statistics.png` for count changes; `slip_magnitude_D14_and_change_statistics.json`; `stop-time-percentage/group-comparisons.csv`; `tail-metrics/whole-motion-reweighted/group-comparisons.csv`; `height-exploratory/group-comparisons.csv` filter `medianHeight`; posture/speed source statistics dirs listed above.

Mouse-only sensitivity was explicitly requested to understand cages: `SLIPS&STOPS/mouse_only_vs_cage_slip_stop_statistics.csv/json`, `tests/compareMouseOnlySlipStopStats.py`.100000 permutations, seed20261111, cohort retained but cage dependence ignored. D14 RUN–SED slipcount .069 mouse-only vs .071 cage; stopcount .035 vs .190; stopped% .010 vs .048. No change comparison significant either way. These are NOT a replacement for cage inference, nor necessarily the historical earlier test. Cages do not universally increase p-values.

## Exploratory alternatives (retain; not automatically main panels)

- Slip D0/D14 CDF by group: `SLIPS&STOPS/slip_score_CDF_D0_D14_by_group.svg` (D0grey,D14groupcolour). D14 three-group compact CDF `D14_slip_score_CDF_three_groups.svg`. Unexpected WALK shape prompted discussion, not exclusion or reinterpretation as direct anatomical severity.
- Slip paired CDF changes: `slip_score_CDF_change_D14_minus_D0.svg`. Equal mouse event-CDFs; positive means larger fraction <=score at D14. Counts are a separate question. Whole-curve cage test integrates squared CDF differences over LOG10score: `slip_score_CDF_change_whole_curve_statistics.json`; overall .2687, pair Holm .9333/.9333/.4821. `tests/testSlipCDFChanges.py`.
- Speed CDFs: `speed-presentation/speed_spatial_CDF_D0_D14_and_change.svg`. Posture analogous in `posture-presentation/`. `tests/plotSpatialSpeedCDFs.py`, `plotSpatialPostureCDFs.py`. Each crossing's CDF over equal-spaced **spatial-bin means**, then equal crossings within mouse, equal mice.114 common finite bins across251crossings,42mice; drop6near-entry bins, roughly first35mm; no interpolation. Not instantaneous-frame distributions. Change ribbons mouseSEM, NOT cage confidence. `tests/testSpatialCDFChanges.py` exact integrated squared differences over LINEAR mm/s or mm, Gram-matrix validated; `*_spatial_CDF_cage_statistics.json`. Speed change overall .09218, pair Holm .2667/.1429/.4345; D14 overall .07557, .4/.09524/.7024. Posture change overall .5146, .2/.8571/.8571; D14 .5873,1/1/.5893. No adjusted pair significant. Clear visual separation isn't proof of equal/no effects, and ribbons don't represent tested cage uncertainty.
- Tail spatial changes: `tail-metrics/D14-minus-D0-spatial-motion-and-height/tail_height_and_score_change_along_beam.svg`; scripts `exportD14TailSpatialProfiles.m`, `plotTailSpatialChanges.py`. Valid-frame bin means, equal-crossing then within-mouse paired changes. No spatial tests. Scalar height uses medians and scalar scoreLegacy uses different mask/weighting, so these curves aren't exact decompositions of scatters.
- Tail CDFs: `tail-metrics/CDF-D14-and-change/tail_CDF_D14_and_D14_minus_D0.svg`, `exportTailCDFValues.m`, `plotTailCDFs.py`. Full traversal valid frames, exclude tailbad+invalidpairs, equal crossings within mouse, equal mice; NO position weighting/tape restriction. Height full-profile median smoothing as above. Score signed-log display sign(x)*log10(1+abs(x)) preserves negatives.1601display thresholds, no inferential smoothing/clipping; frame values preserveNaNs and trial-index mapping. **Different from scalar Legacy.** `tests/testTailCDFs.py` tests exact empirical intervals with LINEAR score/mm integration (not signed-log display), same cage tests. Results `whole_CDF_cage_statistics.json`: scoreD14 overall .1094, pair .6905/.2143/.6905; scorechange .1799, .4/.1429/.4. HeightD14 .8831,1/1/1; heightchange .2218,.3333/.3333/.9226. None adjusted significant. Do not use scalar star on CDF.
- Middle-third speed saved in `speed-presentation/exploratory-tables/speed-metrics-summary.csv`: locomoting RUN–SED D14 raw .04762/Holm .14286; change .03175/.09524. Including stops D14 .03175/.09524; change .03968/.11905. Figures were previously removed; stats retained. No arbitrary central window selected as main outcome.
- No verified scalar above-bar-only group stats table was found in this session. Existing above-bar profiles were descriptive. Do NOT invent above-only p-values from corrected whole-motion results. Older tailREADME “main focus above-bar” is superseded for CURRENT figure by corrected whole-range score.

## Immediate publication/continuation checks

1. Locate the actual Illustrator master and preserve it; source panel paths are not proof of current placement/scaling. Do not recreate user art without reason.
2. Horizontal scale bars representing100mm must say100mm or10cm. Screenshot still shows10mm on some D0/posture/speed/tail profiles; user knows this. Verify actual lengths, not just labels. Speed change25mm/s vs script50mm/s needs geometry check.
3. Rename height scatter “Motion height” rather than “Tail motion mean above bar”; clarify mean-of-crossing-medians, not anatomical tail. Rename spatial speed “Forward speed” if it includes stops.
4. Figure caption must state mouse dots/cage diamonds/group means, SEM definition, exact n per panel, masked tail gaps, common calibration, pairing, inclusion of stop-overlapping slips, temporal composites, and correction family. Total-slip score has arbitrary detector scaling.
5. Do not cherry-pick endpoint vs change or mean vs CDF by significance. Current main choice is paired changes; retain endpoint tables and exploratory alternatives.
6. Review Legacy versus Strict tail scalar masks before publication. Any revised primary definition requires recomputation and an explicit provenance note, not silent editing.
7. Record allocation procedure from experiment records/user. Data show single-group cages; randomization not verified. Do not claim causal training specificity from RUN–SED alone; RUN–WALK is the intensity contrast.
8. These assets are mostly uncommitted. No push/Proton transfer has been done this session. Keep code/small provenance in Git; canonical expensive outputs external. CDF `frame-values.csv` is a reproducible local intermediate in the figure folder; assess size/retention before committing, do not blanket-add all generated files. No source data deletion authorized.

## Next-agent quick start

Read this file, `AGENTS.md`, and the original `HANDOFF.md`. Inspect status. Use existing SVGs rather than rerunning tracking. For the latest bottom triptych run `tests/plotStopTimePercentageChangePanel.py` and `tests/combineSlipStopChangePanels.py` after existing slip change panels exist. For tail scatters use `tests/plotD14TailStandalonePanels.py`. All current figure scripts read saved measurements, not new tracking. Most arrays/tables carry full filenames or map to a trial manifest; preserve identifiers, missingness and masks. Ask for the Illustrator master path only if actually editing the assembled figure.

## Git packaging update

Located Illustrator masters: `figMaterials/BBfigure.ai` and `figMaterials/BBfigure_D0.ai`; included in the figure commit. Their assembly is user-edited, not regenerated by the panel scripts. Illustrator `~ai-*.tmp` files remain local and ignored. Large reproducible CDF `frame-values.csv` and speed/posture `*_group_summary.csv` remain local and ignored; regenerate using the documented exporters/plotters. Editable CDF SVGs, source-value tables, analysis scripts and final statistics are included. The original Git-state notes above describe pre-commit status; consult Git for the current revision.
