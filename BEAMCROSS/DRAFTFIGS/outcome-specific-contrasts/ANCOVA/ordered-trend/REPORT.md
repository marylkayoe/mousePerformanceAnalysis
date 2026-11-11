# Exploratory ordered-trend ANCOVA — 2026-11-11

## Question

Null: equal adjusted SED, WALK and RUN means. Alternative: SED ≤ WALK ≤ RUN for speed, or SED ≥ WALK ≥ RUN for stopped percentage, slip count and tail-motion score, with at least one inequality strict. Unequal steps and plateaus are allowed. A positive result does NOT establish RUN differs from WALK, nor prove both steps nonzero. Other outcomes were not assigned arbitrary directions after failing to show an ordered pattern. Both these four outcomes and their directions were selected after examining data; the analysis is exploratory, not confirmatory.

## Model and calibration

Uses the same 15 cage inputs as ../cage_inputs.csv. Independent cage means with additive cohort effect, common linear baseline slope and common group effects across cohorts. No mouse-level independence assumption. Two group coefficients are constrained to an order cone. Exact least-squares solution enumerates interior, both rays and all-equal vertex; nuisance intercept/cohort/D0 terms are projected out. No 0/1/2 dose or equal-spacing assumption. Test statistic is improvement over the equal-group null divided by unrestricted residual variance (10 df). No ordinary chi-square or ordinary regression p-value is substituted for the constrained distribution.

200,000 standard-normal response simulations conditional on each fixed design calibrate the null. The statistic is invariant to nuisance fitted means and common scale, so this Gaussian Monte Carlo calibration requires no estimated null nuisance parameters. It is a finite-sample model calibration under independent homoscedastic Gaussian cage errors, not a randomization test and not a guarantee when errors are heterogeneous. Add-one Monte Carlo p-values and their simulation SEs are saved. Numerical checks verify cone feasibility, objective ordering and nuisance/scale invariance.

Sensitivity: fit the equal-group null, adjust residuals by sqrt(1-null leverage), multiply each cage residual by a Rademacher sign, and refit the statistic for all 32,768 sign patterns. This exhaustive *wild-bootstrap* calculation is still approximate (residuals are estimated), not an exact permutation/randomization p-value. Few cages and influential observations limit its reliability. It addresses unequal variability imperfectly and does not repair allocation confounding.

Because directions were data-informed, an additional calibration uses the maximum statistic over increasing and decreasing cones for both observed and simulated data. This either-direction sensitivity accounts for choosing direction between these two cones, but NOT selection of four outcomes, exploratory metric changes, or all prior analyses. All p-values are per outcome; no across-outcome correction is claimed.

## Results

| Outcome | Direction | Directional Gaussian p | Directional wild sensitivity p | Either-direction Gaussian p | Either-direction wild p |
|---|---|---:|---:|---:|---:|
| speed | increasing | 0.0436 | 0.0292 | 0.0865 | 0.0583 |
| time_stopped | decreasing | 0.0317 | 0.0110 | 0.0639 | 0.0220 |
| slip_count | decreasing | 0.1092 | 0.0920 | 0.2162 | 0.1840 |
| tail_score | decreasing | 0.0048 | 0.0062 | 0.0101 | 0.0124 |

## Interpretation limits and reproducibility

Retain all calibrations rather than selecting the favorable one. Existing ANCOVA concerns remain: small cage sample, nonrandom allocation, common slope/cohort-effect assumptions, and influential tail-score cage TMCS2_C10. Lower tail score means less of this weighted detector measure, not automatically better balance or less physical tail movement. Background: order-restricted inference has nonstandard null distributions; see https://pmc.ncbi.nlm.nih.gov/articles/PMC2955899/ and https://doi.org/10.1371/journal.pone.0084778 . The implementation here is the documented cone/Monte Carlo procedure, not a claim to reproduce either paper's exact method.

Reproduce with tests/testOrderedCageANCOVA.py using NumPy. Fixed seeds and simulation counts in results.csv/json. No video reads, new tracking, original-result modifications, or bulk scratch. Existing analyses remain intact.
