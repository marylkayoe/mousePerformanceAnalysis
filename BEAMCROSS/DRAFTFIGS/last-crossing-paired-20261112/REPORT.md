# Paired last-crossing performance — 12 November 2026

**Speed provides the clearest evidence that the RUN–SED D14 difference reflects additional separation from D0. Stopped time and detected slip count already differ at baseline; their D14 differences do not represent larger RUN improvements. Tail-motion change is suggestive but sensitive to cohort, inclusion and inferential assumptions. RUN–WALK remains uncertain for all four selected outcomes.**

These are exploratory associations, not a demonstration of mechanism or a causal training-specific effect. The four outcomes were selected by the user **after exploratory inspection of nine outcomes**. Raw estimates, confidence intervals and p-values are the main presentation; Holm-four is a labeled sensitivity, not correction for the full selection history. All nine-outcome results are preserved separately.

## Figures and sample

- **A_four_selected_outcomes.svg/png:** D0/open versus D14/filled last-crossing values paired within mouse; cage/cohort labels, group colours and equal-mouse group means.
- **B_four_selected_outcomes.svg/png:** paired D14−D0 changes; mouse dots, cage diamonds and equal-mouse group means. Both figures show speed, stopped percentage, slip count and corrected whole-tail score. Cage `2_C01` is TMCS2_C01.
- `FOUR_OUTCOMES_TABLES.md` contains every selected-outcome model contrast, including D0 and the restricted sample. `OTHER_FIVE_OUTCOMES.md` and `NUMERICAL_TABLES.md` retain supplementary descriptive and inferential results. The earlier duration-containing A/B exports from this task are retained as supplementary alternatives; use the **four_selected_outcomes** figures for review.

The primary sample is **42 paired mice / 15 cages**: SED 12/4, WALK 12/4, RUN 18/7. All four selected outcomes are observed for all 42 mice. Last means the highest **retained original trial number**, not necessarily trial 3 or the last attempted crossing. `selected_crossings.csv` records both filenames, selected trial numbers, full retained trial-number sets and exact-1/2/3 eligibility. The two-crossing D0 mouse TMCS2_S10 remains included.

Equal-mouse descriptive means, **D0 → D14 (paired change)**:

|Outcome|SED, n=12|WALK, n=12|RUN, n=18|
|---|---:|---:|---:|
|Locomoting speed, mm/s|108 → 123 (+15.0)|117 → 147 (+29.1)|120 → 168 (+48.3)|
|Time stopped, %; change pp|16.9 → 9.76 (−7.13)|7.85 → 5.67 (−2.19)|8.06 → 3.39 (−4.67)|
|Detected slip count|11.3 → 5.50 (−5.83)|6.92 → 3.50 (−3.42)|6.67 → 2.89 (−3.78)|
|Corrected whole-tail score, a.u.|0.406 → 0.489 (+0.083)|0.480 → 0.418 (−0.063)|0.465 → 0.321 (−0.144)|

## Three different questions

**1. D14 endpoint differences.** The existing cage-permutation analysis is preserved, not regenerated. Its RUN–SED estimates/raw p-values are speed +43.20 mm/s / .00794, stopped time −7.14 pp / .0238, slip count −2.50 / .0317, and tail score −0.180 / .0317. Holm-four sensitivities are .0317, .0714, .0714 and .0714. RUN–WALK raw p-values are .351, .125, .202 and .149. These endpoint tests do not assess changes from D0. Matching cage-regression endpoint estimates and CIs are in `FOUR_OUTCOMES_TABLES.md`; their weighting differs from the permutation statistic.

**2. Do paired changes differ between groups?** The table below uses cage-level change ~ group + cohort, with HC3 pointwise 95% confidence intervals. Positive speed differences favour greater speed increases in RUN. Positive stopped-time/slip-count differences mean a **smaller reduction** in RUN.

|Outcome|RUN–WALK change difference [95% CI]|Raw p / Holm-four|RUN–SED change difference [95% CI]|Raw p / Holm-four|
|---|---:|---:|---:|---:|
|Speed, mm/s|+18.00 [−8.42, +44.43]|.162 / .647|+31.10 [+8.54, +53.67]|.0114 / .0454|
|Stopped, pp|−2.16 [−9.14, +4.82]|.510 / 1.000|+3.17 [−4.88, +11.23]|.404 / .404|
|Slip count|−0.61 [−2.60, +1.37]|.509 / 1.000|+2.35 [−0.34, +5.05]|.0809 / .243|
|Tail score, a.u.|−0.090 [−0.419, +0.239]|.559 / 1.000|−0.250 [−0.585, +0.086]|.130 / .260|

**3. Baseline-adjusted D14 differences.** Cage D14 ~ cage D0 + group + cohort compares expected D14 values at a common baseline under a common linear slope. It is not the difference in observed improvement.

|Outcome|RUN–WALK adjusted difference [95% CI]|Raw p / Holm-four|RUN–SED adjusted difference [95% CI]|Raw p / Holm-four|
|---|---:|---:|---:|---:|
|Speed, mm/s|+19.42 [−6.87, +45.71]|.131 / .497|+34.63 [+8.99, +60.26]|.0131 / .0525|
|Stopped, pp|−2.04 [−5.81, +1.74]|.256 / .513|−5.68 [−11.65, +0.28]|.0598 / .179|
|Slip count|−0.78 [−1.82, +0.26]|.124 / .497|−0.90 [−2.46, +0.65]|.223 / .223|
|Tail score, a.u.|−0.092 [−0.329, +0.145]|.407 / .513|−0.200 [−0.438, +0.039]|.0913 / .183|

### What was already present at D0?

- **Speed:** model RUN–SED difference was +11.05 mm/s at D0 [−3.86, +25.95], versus +42.15 at D14. The +31.10 increase in separation is supported nominally and by the four-outcome sensitivity in the full sample. This is stronger evidence of differential change than the other selected outcomes, but is not equally supported for RUN–WALK.
- **Stopped time:** RUN–SED difference was already −9.56 pp [−18.19, −0.92] at D0, versus −6.38 pp at D14. The descriptive gap **narrows**, rather than growing. Its paired-change CI is broad; the conditional ANCOVA result is also uncertain with HC3.
- **Slip count:** RUN–SED difference was already −4.71 [−8.50, −0.91] at D0, versus −2.35 at D14. Again the descriptive gap narrows. D14 fewer slips do not establish a larger reduction in RUN.
- **Tail score:** model RUN–SED baseline difference was +0.046 [−0.189, +0.281], versus −0.203 at D14. The aggregate direction is a developing difference, but the uncertainty and cohort inconsistency below prevent a robust general conclusion. Baseline nonsignificance does not establish baseline equality.

## Sensitivity and robustness

**Cage permutations of paired changes:** existing-style exact enumeration within cohort gives RUN–SED speed +32.10 mm/s, raw p=.00794 / Holm-four .0317; RUN–WALK +21.80, p=.280 / .839. For RUN–SED stopped time, slip count and tail score, raw p=.357, .0873, .0317 and Holm-four .357, .175, .0952. The tail result is therefore method-sensitive: raw permutation p=.0317 versus HC3 p=.130. Equal-cohort permutation estimates and additive-regression estimates are not identical estimands. No ANCOVA permutation test was performed or called exact.

**Cohorts and individual cages:**

- RUN–SED speed change contrasts are +30.64 mm/s in TMCS2 and +33.57 in TMCS3. Leaving out each cage in turn keeps the model change estimate positive (+23.96 to +36.42); raw p ranges .0053–.0416. Its effect direction is stable, while corrected significance is less stable. ANCOVA speed remains +29.34 to +43.84, with raw p up to .0552. TMCS3_C01/C04 and TMCS2_C03 are influential for speed contrasts; no cages were excluded from the primary analysis.
- RUN–WALK speed change is +13.87 in TMCS2 versus +29.73 in TMCS3, where WALK consists of **one cage**. Omitting that cage leaves an additive-model estimate +14.22, p=.321; it does not provide evidence of a clear intensity-specific effect. Such deletion removes a cohort/group cell and is diagnostic, not a replacement analysis.
- RUN–SED tail change is **−0.472 in TMCS2 versus +0.043 in TMCS3**. Thus the pooled tail pattern is not consistent across cohorts. Leave-one-cage-out model estimates remain negative but raw p ranges .053–.504. RUN–WALK cohort contrasts are both approximately −0.095 but have wide uncertainty.
- All cage-wise leverage, Cook's distance, deletion estimates and raw/corrected p-values are retained. ANCOVA leverage reaches .715 for tail score, underscoring sparse-data uncertainty. We do not choose a favourable deletion or variance estimator.

**Exact original trials 1/2/3 on both days:** only **21 mice / 13 cages** remain: SED 4/3, WALK 7/4, RUN 10/6. This can select on behaviour/retention, not just reduce precision. Speed RUN–SED change is +35.74 [+1.44, +70.05], raw p=.0428 / Holm-four .128; RUN–WALK +14.56 [−20.94, +50.07], p=.378. Tail differences strengthen: RUN–WALK −0.196 [−0.380, −0.011], p=.0402 / .161; RUN–SED −0.342 [−0.622, −0.063], p=.0217 / .0866. Neither survives HC3 Holm-four. Conventional OLS would give restricted RUN–SED tail Holm-four .00959, illustrating inferential sensitivity rather than a reason to prefer it. Stopping/slip-count change comparisons remain uncertain.

The full-sample speed result is therefore the most consistent **effect pattern**, not a uniformly robust significance claim across every sensitivity. Narrowing the multiplicity family from nine to four changes its Holm result (.102 to .0454 for the change model); this reflects the user's revised conceptual focus after inspection, not new data or independent confirmation.

## Methods, definitions and reproducibility

Mouse pairing precedes aggregation; only paired finite values for a given outcome enter its cage means. Cages are equally weighted. Main estimates use additive group/cohort regression with HC3 covariance and residual-df t reference (11 df for full-sample changes; 10 for ANCOVA). Conventional homoscedastic OLS intervals/p-values are supplementary. Both are approximate small-sample inference; HC3 does not guarantee calibration with 15 cages. ANCOVA assumes a common linear baseline slope and common group effects across cohorts. Cage-label permutation validity requires within-cohort exchangeability; allocation/randomization is not verified. None removes allocation confounding.

Holm-four is applied **separately per planned contrast, model/period and inclusion set**; pointwise CIs correspond to raw p-values. It does not control the complete history of outcome selection, models, sensitivities or previous analyses. RUN–WALK addresses intensive running versus the active treadmill control; RUN–SED addresses the overall protocol. No group interaction is inferred from separate within-group significance.

Definitions unchanged: speed=`meanSpeedLoco ×700/1201`, excluding stopped frames; stopped percentage=`100×CorrectStoppedFrames/Frames`; count=`nSlips`, including events overlapping stops; tail=`sumLegacy/nLegacy` from corrected **whole-range** normalized motion with the established Legacy mask. Tail score is an image-motion measurement, not necessarily anatomical tail control. Other definitions are retained in `OTHER_FIVE_OUTCOMES.md`. Mean slip-event score is undefined for two zero-slip D14 RUN crossings (TMCS2_S05, TMCS2_S27), retained as NaN; that supplementary paired outcome has 40 mice, and 20 in the restricted sample.

Reproduce using MATLAB R2024b with Statistics and Machine Learning Toolbox:

```matlab
addpath('tests'); analyzeLastCrossingPairedBB
```

This calls `summarizeLastCrossingBB` (influence summaries / independent fitlm validation) and `focusLastCrossingBB` (amended presentation, no new tests). All 378 D14 source rows, including missingness, match the previous export; all 36 full-sample change/ANCOVA contrasts match independent MATLAB fitlm coefficient and conventional-p calculations within 1e-9. All selected filenames are unique and pairing/group/cage identities checked. Source checksums and manifests accompany the outputs. Figures were visually inspected. No `.fig`, tracking, video processing or event detection was used.

Canonical review package: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_last_crossing_paired_20261112`. Repository review copy: `BEAMCROSS/DRAFTFIGS/last-crossing-paired-20261112`. Source code, small tables/reports, checksums and compact review figures are reproducibility material; no bulk scratch exists. Existing nine-panel figures, measurements, local uncommitted changes and `BBfigure.ai` were preserved. No commit or push. **Stop for figure-structure review.**
