# Outcome-specific, prioritized balance-beam comparisons — 2026-11-11

## Questions and scope

RUN–WALK is the primary comparison for each outcome: the additional demanding running protocol beyond the shared daily treadmill/control routine. RUN–SED describes the overall protocol difference; WALK–SED characterizes the control routine. Neither contrast isolates coordination learning from exertion, stress, or other protocol differences.

This exploratory prioritization was specified after inspecting results, motivated by the user's original active-control rationale. It is not a retrospective claim of a prespecified testing hierarchy. No gatekeeping procedure is used. All comparisons are reported, regardless of p-value. The main direct p-values have no three-pair or seven-outcome adjustment. They do not control the chance of any false positive across the study. Secondary findings cannot substitute for failure of the primary comparison. No effect is established as absent or equivalent by a nonsignificant test.

## Calculation and verification

Within-mouse D14 minus D0 changes; mean within each cage; difference between group cage means within each cohort; equal average across the two cohorts. Exact, two-sided permutations relabel whole cages between only the two compared groups within cohort, preserving group cage counts. All 21 direct p-values and estimates independently recomputed from the saved mouse-level CSVs match the previous analysis to numerical tolerance. The new analysis changes the inferential priority and multiplicity reporting, not the underlying estimates or permutation distributions. No global ANOVA gate is required for the chosen contrast.

42 paired mice for speed/posture/tail and 41 for slipping/stopped percentage (three-crossing requirement). Each domain still has 15 cages: SED 4, WALK 4, RUN 7. Cohort TMCS3 has just one WALK cage. Since allocation was not randomized, exchangeability is an assumption, not guaranteed by the experimental design; preserving cage/cohort structure does not eliminate confounding.

Outcome definitions remain those of the current figure. Speed is the locomoting-speed mean, posture is centroid height, slip score is accumulated above-threshold detector score (not anatomical slip severity), stopped time is percent traversal duration, motion height is the motion-weighted height index, and tail score is the corrected whole-range Legacy scalar. Tail height is not direct stationary-tail position. Original source definitions and provenance remain in contrast-layout-examples/*.json and FIGURE_HANDOFF_20261111.md.

## Results: direct two-sided p-values

Negative differences indicate RUN (or WALK in WALK–SED) decreased more/increased less.

| Domain | Outcome | RUN–WALK difference | Unit | RUN–WALK p (primary) | RUN–SED p (secondary) | WALK–SED p (secondary) |
|---|---|---:|---|---:|---:|---:|
| Forward locomotion | Locomoting speed | 13.47 | mm/s | 0.4464 | 0.1587 | 0.4667 |
| Forward locomotion | Time stopped | -2.194 | percentage points | 0.4405 | 0.8968 | 0.6333 |
| Forward locomotion | Posture height | 0.551 | mm | 0.1964 | 0.9127 | 0.1000 |
| Slipping | Slip count | -0.2889 | count | 0.9226 | 0.9603 | 0.9333 |
| Slipping | Total slip score | 203 | a.u. × frames | 0.8393 | 0.2143 | 0.3000 |
| Tail | Motion height | -0.3509 | mm | 0.8869 | 0.1746 | 0.2000 |
| Tail | Tail-motion score | -0.05274 | a.u. | 0.1964 | 0.0079 | 0.2000 |

## Domain-level sensitivity, not the main outcome-specific analysis

The user's three domains are locomotion (speed, stopping, posture), slipping (count, score), and tail (height, score). If a claim is that *at least one outcome within a domain* changes, there are respectively three, two, and two opportunities for that claim. As a sensitivity calculation only, the CSV supplies Holm across RUN–WALK outcomes within each domain. This is NOT Holm across the three group contrasts, NOT correction across seven endpoints, and NOT a joint multivariate domain test. None of the direct primary tests is below .05, so this sensitivity does not change that conclusion. Outcomes need not measure the same quantity for a family-level claim to create multiplicity. The domain grouping alone does not imply statistical independence or authorize selecting the best p-value.

## Figures and interpretation

The seven *_prioritized_contrasts.svg files retain D0, change scatters, and descriptive effect intervals, replacing the old Holm labels with direct p-values and explicit PRIMARY/SECONDARY roles. WALK–SED estimates are in results.csv/json. Bootstrap intervals were retained from the prototype (100,000 cage resamples within cohort/group); sparse cages can make them too narrow, they are unadjusted, and they are not inverted exact-permutation confidence intervals. Do not interpret interval exclusion of zero as significance of the displayed permutation test. Original figures remain untouched.

Reproduce: tests/analyzeOutcomeSpecificContrasts.py, after tests/plotAllMetricContrastPanels.py. No videos or canonical results modified; only small repository figure/report outputs created. General background on grouping/ordering endpoints: https://www.fda.gov/regulatory-information/search-fda-guidance-documents/multiple-endpoints-clinical-trials (clinical-trial guidance used for the general multiplicity principle, not as a regulatory requirement for this animal study).
