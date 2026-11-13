# First-retained D0 group comparisons

One omnibus test per panel, for any SED/WALK/RUN difference. Same selected first trials as figures. Scalar outcomes: existing cage_tests.test; mean mice within cage, cohort-adjusted group sum of squares, exact whole-cage group-label permutations within each cohort preserving cage counts. Pairwise comparisons with Holm3 retained in JSON, not displayed.

Trajectory: finite complete support across all42mice fixed before permutation, average mice within cage. Integrated cohort-adjusted group regression sum of squares over spatial bins; entire cage profile permuted together. Inference excludes incomplete bins while descriptive figure retains half-group coverage. Support listed in JSON. No pointwise tests.

CDF: mean within-mouse ECDF then within cage; exclude one zero-slip mouse only from conditional size distribution. Integrated cohort-adjusted group regression sum of squares over exact log10score intervals; whole cage CDFs permuted together. Event scores reused from validated first_last_slips_event_values.csv; all first-trial event counts checked. 41CDFmice/15cages versus42scalar/profilemice/15cages.

All tests assume exchangeability of group cage labels within cohort under null; this does not establish randomized allocation. Descriptive means weight mice equally, inference cages. Display exploratory raw omnibus p-values; Holm across5paneltests saved as sensitivity, not outcome selection correction. No independent-event/bin replication. No new tracking or measurement changes. Reproduce tests/testD0FirstTrialReferencePanels.py after figure generator; original figures preserved.
