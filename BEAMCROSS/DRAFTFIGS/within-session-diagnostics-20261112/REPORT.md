# Within-session balance-beam diagnostics — 12 November 2026

Exploratory review only. The Illustrator master and its existing panels were not modified. No tracking, video processing or event detection was performed.

## What the diagnostics show

**The clearest descriptive pattern is speed maintenance at D14:** SED and WALK slow between their first and last retained crossings, whereas RUN has little average change. This direction persists with original trials 1/2/3 only. However, uncertainty about the group difference—and especially about its development from D0—is substantial. The requested analyses do **not** establish a robust general deterioration at D0, a training-specific maintenance effect, or fatigue.

- **A_progression.svg/png:** original trial numbers, individual mouse trajectories and available-mouse mean dots. Numbers above each column give contributing mice. Mean dots are deliberately unconnected: later original trial numbers have changing membership, often only one or two mice. Thin lines connect retained observations, not reconstructed failed attempts.
- **B_changes.svg/png:** first-to-last changes at D0/open and D14/filled, paired by mouse within labeled cages; right column shows each mouse's `(last−first at D14) − (last−first at D0)`, with cage means as diamonds. SED black, WALK green, RUN blue. Cage label `2_C01` means TMCS2_C01, not TMCS3_C01.

The displays use speed, detected slip count and corrected whole-tail motion score to represent distinct measurement domains. This choice preceded the new calculations and was not selected by p-value. Duration, stopping and total slip score remain in all numerical tables.

## Inclusion and definitions

All **42 mice, 15 cages** contribute complete first/last pairs for all six outcomes at both days: SED 12/4, WALK 12/4, RUN 18/7 mice/cages. There are 125 D0 and 126 D14 retained crossings. TMCS2_S10 contributes its two D0 crossings, original trials 2 and 3; a third crossing is unnecessary for the first/last contrast.

First/last means minimum/maximum **retained original trial number**, not necessarily trials 1 and 3 or the first/last attempted crossing. Missing attempts and reasons for replacements cannot be reconstructed from these measurements. `retained_trial_inventory.csv` preserves all original numbers and endpoint filenames; `nonstandard_trials.csv` explicitly lists all 23 nonstandard mouse-days (17 at D0, 6 at D14). These patterns are not automatically invalid trials.

| Outcome | Single-crossing definition, identical at both days |
|---|---|
| Locomoting speed | Saved `meanSpeedLoco × 700/1201`, mm/s; excludes detected stopped frames |
| Crossing duration | Validated traversal `Frames / AnalysisFrameRate`, seconds |
| Time stopped | `100 × CorrectStoppedFrames / Frames`; change in percentage points |
| Detected slip count | Saved `nSlips`, including slips overlapping stops |
| Total slip score | Saved `totalSlipMagnitude`, sum of detected event scores, a.u. × frames; not normalized by traversal duration |
| Tail-motion score | Corrected whole-range `sumLegacy/nLegacy` per crossing; established Legacy mask, not Strict/CDF mask; a.u. |

All six outcomes are finite for every retained crossing. Tail score is a normalized image-motion measure, not anatomical tail position or a direct measure of tail control. Its known Legacy invalid-pair inclusion is preserved; no new mask or normalization was introduced. Duration and stopping share information; slip count and score also measure related properties.

## Numerical results

These are **equal-mouse descriptive mean changes, last minus first**, not the cage/cohort-adjusted inferential estimates below.

| Outcome | D0 SED | D0 WALK | D0 RUN | D14 SED | D14 WALK | D14 RUN |
|---|---:|---:|---:|---:|---:|---:|
| Speed, mm/s | −6.43 | −7.06 | −1.81 | −28.87 | −26.17 | −1.21 |
| Duration, s | +1.60 | +0.52 | +0.26 | +0.84 | +0.63 | +0.05 |
| Stopped, pp | +6.53 | +0.92 | +0.77 | +3.62 | −0.63 | −0.99 |
| Slip count | +4.42 | +0.75 | +0.72 | 0.00 | −0.42 | −0.72 |
| Total slip score, a.u. × frames | +1084 | +330 | +358 | +148 | +83 | −981 |
| Tail-motion score, a.u. | +0.027 | −0.018 | +0.067 | −0.015 | +0.028 | −0.073 |

**D0:** the pooled, equal-cohort cage estimate of speed change is **−7.04 mm/s (95% CI −12.15 to −1.93)**, raw p=.0107, Holm-six p=.0640. Thus there is nominal evidence of slowing under this model, but it does not survive the six-outcome correction or the exact-1/2/3 restriction. Crucially, cohort-specific cage means are **+0.54 mm/s in TMCS2 versus −14.62 in TMCS3**: baseline slowing is not consistent across cohorts. Equal-mouse cohort means are +0.92 and −14.62. Equal-cohort weighting therefore matters materially. Pooled slip count is +1.98 (−0.53 to +4.48); total slip score +653 (−56 to +1362); neither establishes a rise. SED has the larger descriptive increases in stopping/duration/slips. No full-sample RUN–WALK or RUN–SED D0 change comparison survives correction. A difference between one group's significant test and another group's nonsignificant test is not evidence of a group interaction.

**D14:** speed slowing is visually concentrated in SED and WALK, with a near-zero RUN mean. The model estimates are SED −28.87 (−52.55 to −5.20), WALK −25.00 (−55.35 to +5.34), RUN −1.02 (−17.93 to +15.89) mm/s. RUN–WALK is +23.99 (−6.09 to +54.06), raw p=.107; RUN–SED +27.85 (−3.37 to +59.08), p=.075. Existing-style exact cage permutation estimates/p-values are +34.09/.0476 and +30.24/.0317, respectively; Holm-six p=.238 and .190. This inferential sensitivity must remain visible. RUN–WALK duration change is −0.569 s (−1.121 to −0.017), raw p=.0443, Holm p=.266. Other measures do not establish group-dependent within-session changes after correction.

**Does the within-session change develop differently by D14?** This is the paired difference of changes, not a last-crossing D14 group test:

| Speed difference of changes | Model estimate, mm/s (95% CI) | Raw p | Holm-six p | Exact cage sensitivity p |
|---|---:|---:|---:|---:|
| RUN–WALK | +18.34 (−14.65, +51.32) | .247 | 1.000 | .125 |
| RUN–SED | +26.71 (−1.85, +55.27) | .064 | .384 | .0397 |

No full-sample between-group difference-of-changes contrast survives six-outcome correction under either approach. The pooled slip-count difference of changes is **−2.58 (−4.17 to −0.99)**, raw p=.00385, Holm p=.0231: the first-to-last slip increase is smaller at D14 overall. This does not establish a RUN-specific effect, and it is inclusion-sensitive (below). Tail difference-of-changes contrasts are RUN–WALK −0.199 (−0.570 to +0.173) and RUN–SED −0.144 (−0.516 to +0.228), both uncertain.

## Exact original trials 1, 2, 3 sensitivity

A day is eligible only when its complete retained trial-number set equals `{1,2,3}`. For the between-day comparison, **both days** must satisfy this rule; all four endpoints then belong to the same mouse. This avoids silently comparing different day-specific populations.

| Eligible sample | SED mice/cages | WALK mice/cages | RUN mice/cages | Total mice/cages |
|---|---:|---:|---:|---:|
| D0 | 5/4 | 9/4 | 11/6 | 25/14 |
| D14 | 10/4 | 10/4 | 16/7 | 36/15 |
| Both days | 4/3 | 7/4 | 10/6 | 21/13 |

- D14 equal-mouse speed changes remain SED −36.49, WALK −29.26, RUN +1.62 mm/s. The descriptive maintenance pattern persists. Restricted model RUN–WALK = +25.68 (−2.30 to +53.66); RUN–SED = +34.24 (+5.10 to +63.39), but neither survives Holm-six correction (.342/.152). Restricted difference-of-changes CIs are wider: RUN–WALK +23.23 (−35.51 to +81.96), RUN–SED +35.51 (−26.29 to +97.32).
- D0 pooled speed = −6.21 (−13.77 to +1.35), raw p=.099. General baseline slowing is therefore not robustly established across inclusion rules.
- The pooled slip-count difference of changes becomes −1.42 (−3.34 to +0.50), Holm p=.654. The full-sample adjusted result is not robust to the requested restriction.
- Restriction creates a strong D0 SED slip-count increase: model +5.38 (+3.78 to +6.97), and RUN–SED difference −4.29 (−6.32 to −2.26), model Holm p=.0050. The exact group permutation sensitivity has raw p=.0111, Holm p=.0667. Only five SED mice remain. This is **inclusion- and method-sensitive**, not evidence of general deterioration or justification to replace the full sample.

Original trial-number eligibility may itself relate to behaviour/refusals/retention. The restricted mice are not necessarily representative; reductions in n are not the sole reason results change. Full estimates, uncertainty, raw and adjusted p-values are in `inference.csv` for every outcome, group and contrast.

## Inference and the earlier CI/p-value discrepancy

The repeated-measures unit is the mouse: compute each mouse's within-day difference first and its paired between-day difference next. Average these within cage, retaining cohort-specific cage IDs. Cages, not trials or mice treated as independent, supply inferential replication.

For a single consistent estimate/CI/test set, fit **cage change ~ group + cohort**, equally weighting cages. Group estimates are evaluated at 50:50 cohort weighting; group differences assume an additive cohort effect. Use HC3 covariance and two-sided t reference with `nCages−rank(X)` residual df (11 in the full group model). For the pooled question, fit cage change ~ cohort, then average the two fitted cohort means (13 df). This pooled quantity weights cohorts equally and cages within cohort equally; it is not the mean of the 42 mouse dots and does not equally weight groups. The pooled between-day fit has the same pairing and membership in the full sample.

These are approximate small-sample model intervals/tests, **not exact mixed-model or randomization inference**. HC3 allows unequal residual variance but cannot guarantee calibration with 15 cages, a single TMCS3 WALK cage, or cohort×group heterogeneity. We retain the existing exact within-cohort cage-label permutations for RUN–WALK and RUN–SED as sensitivity, including their separate equally cohort-weighted estimates. Those allow differing cohort-specific observed contrasts but require cage-label exchangeability; allocation/randomization remains unverified. Differences from the additive model can reflect weighting and assumptions as well as variance estimates. Neither approach removes allocation confounding.

Earlier baseline plots used mouse-weighted stratified percentile-bootstrap CIs and a different cage-sum sign-flip test that did not model cohort means. Neither was the inversion of the other, and sparse cage/cohort structure and different null assumptions prevent treating their disagreement as a settled significance finding. The present table does not reuse those p-values or claim that the earlier interval was wrong: it replaces that juxtaposition with matching model-based raw tests and pointwise intervals, identifies the changed estimand, and preserves cohort-specific mouse/cage means in `cohort_descriptive_changes.csv`. No method was selected based on which produced significance.

**Multiplicity:** Holm across all six outcomes separately for each period × contrast × inclusion set, for both model and permutation columns. The two prioritized contrasts remain distinct (RUN–WALK: intensity versus active control; RUN–SED: overall protocol). This is not global correction across groups, periods, sensitivities or previous explorations. CIs are pointwise 95%, matching raw—not Holm-adjusted—tests. No equivalence, fatigue mechanism or causal training-specific claim follows from these exploratory comparisons.

## Provenance, verification and restart

Reproduce with MATLAB R2024b:

```matlab
addpath('tests'); analyzeWithinSessionBB
```

Script: `tests/analyzeWithinSessionBB.m`. Reads only saved measurements from `assets/Tara-BB-trial-data.csv`, `BEAMCROSS/DRAFTFIGS/analysis-data/trial_manifest.csv`, and `BEAMCROSS/DRAFTFIGS/tail-metrics/whole-motion-reweighted/trial-values.csv`; independent validation reads the existing `last-crossing-D14/last_crossing_values.csv`. Source measurements remain canonical in the established Tara RESULTS directories; full source-video filenames remain in every trial/endpoint manifest. MATLAB Statistics and Machine Learning Toolbox supplies t quantiles/probabilities.

Validated unique identifiers, manifest slip counts, all finite scalar values, mouse pairing and arithmetic identities; all 252 D14 endpoint values match the previous independently exported table within 1e-9. PNGs inspected for layout; SVGs are editable. No `.fig` was created. No source measurements, previous outputs or Illustrator masters changed.

Canonical review package: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_within_session_diagnostics_20261112`. Small figure-workflow review copy: `BEAMCROSS/DRAFTFIGS/within-session-diagnostics-20261112`. The MATLAB source, report, small CSVs, manifest and compact SVG/PNG diagnostics are reproducibility/review material suitable for the existing figure workflow; no bulk outputs, video copies or scratch were created. No commit/push performed. **Stop here for review before changing BBfigure.**
