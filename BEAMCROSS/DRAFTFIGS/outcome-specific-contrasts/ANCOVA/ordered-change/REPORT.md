# Ordered-pattern tests of D14−D0 changes

These tests match the change-score panels: speed, tail-motion score and motion height. Same paired mice and cage inputs as ../cage_inputs.csv; average within-mouse D14−D0 changes within each cage. Fifteen independent cage observations, additive cohort term; no additional D0 predictor. Four parameters in the unrestricted model, 11 residual df. Common group effects across cohorts are assumed. This differs from the original equal-cohort permutation contrast analysis; these are model-based ordered-pattern tests, not replacements for its pairwise p-values.

Null: all three adjusted mean changes equal. Alternative: either SED ≤ WALK ≤ RUN or the reverse, with at least one strict inequality. Unequal steps and plateaus allowed. The either-direction Gaussian Monte Carlo p-value is the main reported result because direction was data-informed. Directional values (speed increasing, tail score and height decreasing) are saved only for transparency. Height direction was not previously specified; no directional claim is made for it. These tests do not establish both adjacent differences, or RUN versus WALK specifically.

Calibration: 200,000 fixed-design Gaussian response simulations; statistic is constrained improvement over equal-group null divided by unrestricted residual variance. Nuisance intercept/cohort projected out. Null distribution invariant to nuisance means and common scale. All 32,768 HC2 null-residual Rademacher wild-bootstrap signs supply an approximate unequal-variance sensitivity. Wild bootstrap is not an exact randomization test. Same cone fitting, feasibility and scale/nuisance invariance checks as tests/testOrderedCageANCOVA.py; see ../ordered-trend/REPORT.md for background. No across-outcome correction. Selection of outcomes and directions followed inspection; results are exploratory, not confirmatory. Nonrandom allocation, sparse cages and influential observations remain limitations.

| Change outcome | Either-direction Gaussian p | Either-direction wild p | Gaussian simulation SE (directional) |
|---|---:|---:|---:|
| speed | 0.2018 | 0.1526 | 0.00068 |
| tail_score | 0.0122 | 0.0352 | 0.00018 |
| motion_height | 0.2352 | 0.1755 | 0.00072 |

Reproduce: tests/testOrderedCageChanges.py. Existing sources, plots, ANCOVA tests and original results preserved. Use these change-test values only on matching D14−D0 panels; do not substitute ANCOVA p-values.
