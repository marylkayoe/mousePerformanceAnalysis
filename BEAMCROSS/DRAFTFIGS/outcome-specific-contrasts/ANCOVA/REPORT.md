# Exploratory cage-level ANCOVA — 2026-11-11

## Model and interpretation

D14 cage mean = intercept + WALK + RUN + cohort(TMCS3) + estimated coefficient × D0 cage mean. Baseline centered/scaled internally for numerical stability, then slope converted to original units. The same paired mice contribute both cage means. Each of 15 cages receives equal weight. Speed/posture/tail use 42 mice; slip count/score/stopped percentage use 41 paired mice. RUN–WALK is the primary contrast for each outcome; RUN–SED and WALK–SED are secondary. These are outcome-specific, two-sided unadjusted p-values. No correction across three pairs or seven outcomes, and no study-wide false-positive control claim. This is exploratory analysis after results were examined.

This is a cage-level ANCOVA, NOT a mouse-level random-intercept model. It preserves independence at cage level but does not estimate the within-cage mouse-level baseline association. There are five fitted coefficients and ten residual degrees of freedom. Standard estimates assume a linear baseline relationship, common baseline slope and group effects across cohorts, independent cages, and homoscedastic approximately Gaussian errors for the t-based intervals/tests. Nonrandom allocation remains a limitation. The analysis estimates adjusted association, not an isolated causal effect of training/learning.

The earlier exact permutations averaged group contrasts equally across cohorts. This additive ANCOVA assumes common effects across cohorts and uses regression weighting; it also uses parametric t inference rather than exact permutations. Consequently changes in p-values cannot all be attributed to baseline adjustment. results.csv includes D14-only and change tests under the SAME additive regression model, plus an ANCOVA sensitivity allowing group × cohort interactions (equal-cohort contrast averaging, eight residual degrees of freedom).

## Results

| Metric | RUN–WALK adjusted difference | 95% model interval | RUN–WALK p | RUN–SED p | WALK–SED p | RUN–WALK HC3 sensitivity p |
|---|---:|---|---:|---:|---:|---:|
| speed | 12.02 mm/s | [-13.21, 37.24] | 0.3134 | 0.0478 | 0.2801 | 0.3884 |
| time_stopped | -2.456 percentage points | [-7.199, 2.287] | 0.2754 | 0.0374 | 0.2638 | 0.3870 |
| posture | 0.453 mm | [-0.1188, 1.025] | 0.1080 | 0.4017 | 0.5073 | 0.1429 |
| slip_count | -2.435 count | [-8.488, 3.618] | 0.3912 | 0.1257 | 0.4238 | 0.5047 |
| slip_score | 17.68 a.u. × frames | [-1869, 1904] | 0.9837 | 0.8682 | 0.8923 | 0.9858 |
| motion_height | -1.335 mm | [-7.071, 4.401] | 0.6153 | 0.8192 | 0.8718 | 0.6828 |
| tail_score | -0.05468 a.u. | [-0.1517, 0.04239] | 0.2380 | 0.0049 | 0.0709 | 0.3683 |

## Sensitivity and model concerns

No primary RUN–WALK test is below .05 in standard, HC3, or cohort-interaction sensitivity models. This does not establish absence or equivalence.

HC3 allows unequal error variance and reduces leverage-related variance bias; here it uses the same t distribution with 10 df as a small-sample sensitivity, not an exact robust procedure. All contrasts and intervals are retained. RUN–SED speed changes from standard p=.0478 to HC3 p=.0923; stopped percentage .0374 to .1441; tail score .0049 to .0670. Do not present only the favorable standard p-values.

Tail-score baseline slope differs across groups suggestively (diagnostic p=.064, low-powered); one sedentary cage TMCS2_C10 has Cook's distance 1.24. Dropping one cage at a time yields RUN–SED p ranging .0009–.0551 and RUN–WALK .0282–.5947. These are influence diagnostics, not a license to exclude a cage. All cages remain in the main result.

Slip score has a quadratic baseline diagnostic p=.026; a simple linear model may be inadequate, and a few large scores make Gaussian assumptions questionable. It has no convincing group contrast in this model. No transformations or nonlinear alternative were chosen to optimize significance. Counts and bounded stopped percentages are also modeled on their existing scalar scale here; this is an exploratory Gaussian comparison, not a final count/beta model.

Slope and quadratic checks are unadjusted exploratory diagnostics with very low power (15 cages); nonsignificant checks do not validate assumptions. Seven SVGs show actual cage baseline/end-point pairs, colored by group and marked by cohort. Mouse variation is not represented in those cage-point plots. diagnostics.csv records slopes, influence and model checks; results.json contains every leave-one-cage-out fit. No cage removed and no original analysis overwritten.

## Reproduction and verification

Run tests/analyzeCageANCOVA.py with NumPy. Sources, fields, conversions and filters are taken from contrast-layout-examples/*_baseline_changes_contrasts.json; original source CSVs are read in place. cage_inputs.csv is the exact model input. Least squares uses NumPy lstsq, with rank checks; baseline standardization avoids unit conditioning problems. Student t/F probabilities use regularized incomplete beta via a convergent continued fraction. Self-checks verify t(1df) at 1, the 10df .975 quantile, its numerical inversion, and F(2,2) at 1. Outputs are small repository reports/tables/editable diagnostic SVGs; canonical data and previous analyses are untouched.

Background: Vickers & Altman, BMJ 2001, https://www.bmj.com/content/323/7321/1123.full . The standard baseline-adjustment rationale is relevant, but randomized-trial causal claims do not automatically transfer to this nonrandom cage allocation.
