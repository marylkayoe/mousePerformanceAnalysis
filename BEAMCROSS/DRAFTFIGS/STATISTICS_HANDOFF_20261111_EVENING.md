# Evening continuation: statistical explorations and figure decisions

This extends FIGURE_HANDOFF_20261111.md after commit `d29bb45`. User requested preserving the work, documenting it, and committing/pushing before stopping for the night. Do not restart analysis or continue searching for significance without a new request. Original measurements, canonical results, tracking and videos were not changed. New material is about 1.6 MB of figures, tables and reports, plus scripts. The user-edited `figMaterials/BBfigure.ai` changed during the session and is preserved in this commit; do not regenerate over it. No bulk scratch or Proton/Taildrop transfer was performed.

## Experimental question and communication

The paper's main question is whether locomotor behavioral exposure changes IO neuropil. Significant balance-beam improvement is not required for that question. User wants the novel behavioral measurement method and tail measurements visible because of two prior papers on tail function in balance. Do not treat behavioral nonsignificance as invalidating separate neuropil results, whose statistics were not reexamined here.

WALK is approximately 15 seconds of walking, intended to match daily rhythm, handling and treadmill smells/sounds/context without demanding high-speed running coordination. RUN–WALK therefore addresses additional demands beyond the routine. RUN–SED addresses the overall protocol; WALK–SED characterizes the control routine. Neither isolates motor learning from exertion/stress. Do not pool WALK and RUN without a justified new question.

User was frustrated by advice changing repeatedly and by unsolicited manuscript prose. They will write the text themselves. Prioritize concrete figures/results and direct answers. Main versus supplemental figure scope is NOT settled. Suggestions to reduce to two panels or keep four summaries were not accepted decisions. The novel method and tail link matter independently of significance. Tara's older screenshot had D7/D0 and D14/D0 duration/posture ratios and D7−D0/D14−D0 slip/stop counts; no significant D14 omnibus result was visible. Those old tests were not independently reconstructed here.

Tara observes mice sometimes behave differently from one day to another. Weather and moon phase were not recorded and cannot be invoked as established explanations. Motivation, arousal and ceiling effects remain hypotheses, not demonstrated mechanisms.

## Analysis inventory and order

All paths below are relative to `BEAMCROSS/DRAFTFIGS/`; scripts are relative to repo root. All analyses are exploratory after viewing data, not retrospectively prespecified. Cohort and cage structure remain important; single-group cages and nonrandom allocation mean exchangeability/causal interpretation are uncertain. No method repairs allocation confounding.

1. **Three-panel prototypes:** `contrast-layout-examples/` (all seven metrics) and `tail-metrics/contrast-layout-example/` (initial tail prototype). Scripts `tests/plotAllMetricContrastPanels.py`, `tests/plotTailContrastPrototype.py`. D0 scatter, change scatter, RUN–WALK/RUN–SED effect panel. These initially retained the original Holm correction across three pairs. User correctly pointed out this did not implement the revised priority. Preserve them as historical alternatives, not the final prioritized analysis. Bootstrap intervals are descriptive, not test-inverted; sparse cells (one TMCS3 WALK cage) can make them too narrow.

2. **Outcome-specific change contrasts:** `outcome-specific-contrasts/REPORT.md`, `results.csv/json`, seven `*_prioritized_contrasts.svg`; `tests/analyzeOutcomeSpecificContrasts.py`. RUN–WALK primary per outcome, others secondary, direct two-sided exact cage permutations within cohort. Cage means and equal-cohort averaging unchanged; all 21 underlying estimates/p-values independently matched prior results. No three-pair correction in main display, no across-seven-outcome control claim. Original Holm values retained. Optional within-domain primary-test correction is a sensitivity column, not the adopted main inference. Domains: locomotion (speed, stopping, posture), slipping (count, score), tail (height, score). Domain grouping alone does not remove multiplicity if a claim is based on whichever outcome is significant. None of the change RUN–WALK direct tests is below .05; tail RUN–SED p=.00794.

3. **D14 only:** `outcome-specific-contrasts/D14-only/`; `tests/analyzeD14OutcomeSpecificContrasts.py`. Same direct cage permutation method, no D0 adjustment. RUN–WALK p: speed .6726, stopped .1310, posture .0476, slip count .0714, slip score .9405, height .9405, tail score .0298. RUN–SED p: .0238, .0159, .2540, .0238, .9286, .9841, .0238 respectively. These are endpoint differences, not evidence of different changes. All D14 outcomes have 42 mice; paired slipping/stopping outcomes have 41 due to three-crossing criterion.

4. **Baseline diagnostic:** `D14-only/BASELINE_CHANGE_DIAGNOSTIC.md`. Both added noise and pre-existing group differences explain endpoint/change discrepancies. On matched mice, RUN–SED slip difference is −7.27 at D0 and −6.83 at D14; stopped-time difference is −5.77 and −6.23 percentage points. Thus little additional separation develops for those outcomes. Group/cohort-centered mouse correlations D0/D14 are modest; baseline is not useless. Tail score is a counterexample to universal added noise: cage change variability is lower than D14 variability. Diagnostic is descriptive and its calculations/definitions are documented, not a new significance test.

5. **Cage-level ANCOVA:** `outcome-specific-contrasts/ANCOVA/REPORT.md`, `results`, `diagnostics`, `cage_inputs` CSV/JSON and baseline/end-point SVGs; `tests/analyzeCageANCOVA.py`. Model on 15 equally weighted cage means: D14 ~ D0 + group + cohort. Five coefficients, 10 residual df. This is NOT a mouse-level mixed model. Common slopes/effects across cohorts; different weighting and parametric t inference from original equal-cohort permutations, so p changes cannot all be attributed to D0 adjustment. Also saved same-model endpoint/change tests, HC3 variance sensitivity, group×cohort sensitivity, slope interactions, quadratic diagnostic, leave-one-cage-out results. No main RUN–WALK p below .05. Standard RUN–SED speed .0478, stopped .0374, tail score .0049 become HC3 .0923, .1441, .0670. Tail score has influential SED cage TMCS2_C10 (Cook 1.24), slope interaction p=.064. Slip score quadratic diagnostic p=.026 suggests inadequate simple linear model. No cage removed. See report before using any star.

6. **Mice-independent hypothetical ANCOVA:** `ANCOVA/mice-independent-sensitivity/`; `tests/analyzeMouseIndependentANCOVA.py`. Requested to assess whether cages alone explain uncertainty. Deliberately ignores dependence, retains baseline/cohort, 41/42 observations. Not replacement inference. RUN–WALK still all nonsignificant: .209,.169,.062,.242,.899,.724,.333 in the metric order above. RUN–SED speed/stopped/slips/tail p=.0225,.0302,.0281,.0097. Aggregation, weighting and baseline association also change, not just SE. HC3 here does NOT fix cage dependence.

## Ordered patterns: keep endpoint ANCOVA and change tests distinct

Descriptive adjusted patterns SED→WALK→RUN: faster speed, less stopped time, fewer slips, lower tail score. User requested an unequal-step order test, not a 0/1/2 linear dose model. An order test allows plateaus and does not establish either adjacent contrast separately.

**Baseline-adjusted D14:** `ANCOVA/ordered-trend/REPORT.md`, `results.csv/json`; `tests/testOrderedCageANCOVA.py`. Tests equal group means against monotone order with cohort and D0 adjustment, 15 cages, unrestricted 10 df. Constrained regression solved by enumeration of the 2D cone interior/rays/vertex. Statistic: constrained improvement divided by unrestricted error variance. Gaussian finite-sample null calibrated using 200,000 simulations per outcome. Null nuisance/scale invariance, cone feasibility/objective bounds checked. All 32,768 null-residual HC2 Rademacher wild signs form an approximate heteroscedasticity sensitivity, NOT exact randomization inference. Sparse cages and influential observations still matter.

Directions/outcomes were identified after looking: speed up, stopped/slips/tail score down. Main presentation uses the maximum over both order directions in each simulation to acknowledge direction selection. This does NOT adjust for selecting outcomes or all prior analyses. No across-outcome correction claimed.

| Adjusted D14 outcome | Directional Gaussian p | Either-direction Gaussian p | Either-direction wild sensitivity p |
|---|---:|---:|---:|
| Speed | .0436 | .0865 | .0583 |
| Stopped time | .0317 | .0639 | .0220 |
| Slip count | .1092 | .2162 | .1840 |
| Tail score | .0048 | .0101 | .0124 |

**Seven-panel adjusted figure:** `ANCOVA/ordered-trend/seven_metrics_adjusted_D14_ordered_patterns.svg/png/csv`; notes `FIGURE_NOTES.md`; script `tests/plotAdjustedOutcomeTrends.py`. Each point is the UNCONSTRAINED adjusted group mean at common all-cage mean D0 and equal cohort averaging (TMCS3=.5). Bars are pointwise standard-model 95% t CIs, not SEM and not confidence based only on D0. Means as well as uncertainty are adjusted. Group labels spaced categorically; connecting lines do not imply equal doses. Four panels have either-direction p-values. Posture, total slip score and height say “Order not tested”; hypotheses were not invented to fill them. Intervals and overall-order tests address different questions. No pairwise brackets/stars.

**D14−D0 change tests (latest request):** `ANCOVA/ordered-change/REPORT.md`, `results.csv/json`; script `tests/testOrderedCageChanges.py`. User supplied change scatters for speed, tail score, then motion height, asking whether trend annotations could be added. These need change tests, NOT the adjusted-D14 p-values above. Response = cage mean paired change; nuisance intercept/cohort, no extra D0 adjustment; unrestricted 11 df. Same cone calibration, 200,000 Gaussian simulations and exhaustive approximate wild signs. Either-direction tests are the reported version, especially for height whose direction was not specified beforehand.

| Change outcome | Either-direction Gaussian p | Either-direction wild sensitivity p |
|---|---:|---:|
| Speed | .2018 | .1526 |
| Tail score | .0122 | .0352 |
| Motion height | .2352 | .1755 |

Suggested panel label: “Exploratory ordered-pattern p = …” using Gaussian column; retain sensitivity in methods. Existing tail-score star denotes a separate pairwise comparison and must not be relabelled as order significance. The supplied Illustrator SVGs were read only; no annotations were actually added to those pasted files or the master. Do not claim otherwise.

## Reproduction, storage and stopping point

Numerical helpers in `tests/analyzeCageANCOVA.py` use NumPy least squares and incomplete-beta t/F probabilities, with known-distribution/quantile self-checks. Mouse sensitivity and figure scripts extract only its function definitions through AST to avoid rerunning/overwriting fits. No scipy/statsmodels installation required. Use the existing rich Python interpreter `/Users/yoe/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3` (NumPy/Pillow). Run source scripts only if results need regeneration. Several interpretation notes are curated Markdown, not generated by every script; preserve them. Original model and cone scripts have explanatory reports alongside outputs.

All figures are SVG (editable), previews PNG where applicable, all statistical source/summary tables CSV/JSON. Canonical source measurements remain under the existing Tara RESULTS root and repository-approved copies. New work uses saved scalar values, no re-tracking. Internal disk remained ~34 GiB free; ~11 GiB swap was observed, so no new MATLAB process was started and unrelated sessions were left alone. Output sizes are small and no external bulk scratch was created.

No final statistical strategy or final main/supplement layout has been adopted for publication. Do not choose whichever endpoint/change/ANCOVA/CDF/order test gives the smallest p-value. Do not describe exploratory trends as proving training-specific learning or equivalence. In particular, RUN–WALK remains uncertain despite ordered patterns. The user explicitly requested stopping for tonight and preserving this state.
