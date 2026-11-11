# Why D14 and change tests differ — 2026-11-11

Exploratory diagnostic using the same scalar sources, fields, conversion factors and exclusions in ../ and ../../contrast-layout-examples/*_baseline_changes_contrasts.json. Pair D00 and D14 within mouse. For slipping/stopping use the 41-mouse paired set; other outcomes use 42. This is not a causal attribution or a new significance test.

For each time point, subtract its cohort × group cell mean from mouse values before calculating the D0–D14 Pearson correlation. Separately average paired mice within cage, subtract cohort × group means of cage means, and calculate the residual SD of D14−D0 divided by residual SD of D14. Cell-centering removes group/cohort mean shifts. Ratios are descriptive, not standard-error ratios for the permutation tests. Few cages and a single TMCS3 WALK cage make these diagnostics uncertain.

| Outcome | Within-cell mouse D0–D14 r | Within-cell cage r | Cage residual SD(change)/SD(D14) |
|---|---:|---:|---:|
| Speed | .399 | .137 | 1.150 |
| Time stopped | .164 | −.214 | 2.098 |
| Posture | .479 | .184 | 1.674 |
| Slip count | −.063 | .111 | 1.652 |
| Slip score | −.229 | .079 | 1.360 |
| Motion height | .125 | .042 | 1.199 |
| Tail-motion score | .343 | .660 | .892 |

Matched-set effects: cage-mean group differences within cohort, averaged equally across cohorts, matching the test statistic. Numbers below are RUN minus comparator, in the original metric units. Stopped percentage differences are percentage points. The 41-mouse D14 slipping/stopping numbers differ slightly from the full 42-mouse D14 analysis.

| Outcome | Comparator | D0 difference | D14 difference | Difference in changes |
|---|---|---:|---:|---:|
| Speed | WALK | −1.9060 | 11.5645 | 13.4705 |
| Speed | SED | 8.2446 | 30.8707 | 22.6261 |
| Time stopped | WALK | −.7412 | −2.9354 | −2.1942 |
| Time stopped | SED | −5.7675 | −6.2276 | −.4601 |
| Posture | WALK | −.0313 | .5197 | .5510 |
| Posture | SED | .3601 | .3993 | .0392 |
| Slip count | WALK | −2.9333 | −3.2222 | −.2889 |
| Slip count | SED | −7.2667 | −6.8333 | .4333 |
| Slip score | WALK | 20.5584 | 223.5844 | 203.0260 |
| Slip score | SED | −1511.6411 | 209.7015 | 1721.3426 |
| Motion height | WALK | .5251 | .1742 | −.3509 |
| Motion height | SED | 4.0476 | .0387 | −4.0089 |
| Tail-motion score | WALK | −.0126 | −.0653 | −.0527 |
| Tail-motion score | SED | .0147 | −.1383 | −.1530 |

Both baseline group differences and added variability matter. For stopped time and slip count versus SED, most of the D14 separation already exists at D0. For posture versus WALK, the effect is similar but change variability is larger. Tail score is a counterexample: cage-level change variability is smaller than D14 variability. D0 is not therefore uniformly an unsuitable control. Weather, arousal, habituation, recording conditions and measurement error are possible explanations for weak repeatability, not identified mechanisms in this calculation.

Variance identity: Var(D14−D0) = Var(D14) + Var(D0) − 2 Cov(D14,D0). A baseline-adjusted D14 model can estimate the baseline association rather than imposing the coefficient of one implicit in a change score. Such an analysis should preserve cage/cohort structure, check assumptions and be reported transparently as an additional exploratory analysis, not selected because of its p-value. Baseline adjustment cannot remove all confounding from nonrandom group allocation.
