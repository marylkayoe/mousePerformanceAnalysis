# D14-only outcome-specific comparisons

Same exploratory question priority as ../REPORT.md: RUN–WALK primary per outcome; RUN–SED and WALK–SED secondary context. Direct two-sided exact cage-permutation p-values, without a three-pair adjustment or across-outcome error-control claim. Previous Holm values retained in results.csv/json. No omnibus gate or selection of favorable comparisons.

These are D14 levels, not paired changes and not baseline-adjusted estimates. All seven outcomes have 42 mice (12 SED,12 WALK,18 RUN), 15 cages, two cohorts; the three-crossing filter is retained for slip outcomes and the stopped-percentage source. Unlike the change analysis, D14 slipping/stopping includes the mouse with only two D0 crossings. Calculations use within-cage mouse means, group cage-mean differences within each cohort, and equal averaging across cohorts. Permutations preserve cage counts within each cohort and compare only the two groups. Nonrandom allocation leaves exchangeability uncertain. Outcome definitions/units and original input files are recorded in results.csv/json. Negative difference means lower D14 value in the first named group.

| Domain | Metric | RUN–WALK difference | Unit | RUN–WALK p, primary | RUN–SED p, secondary | WALK–SED p, secondary |
|---|---|---:|---|---:|---:|---:|
| Forward locomotion | Locomoting speed | 11.56 | mm/s | 0.6726 | 0.0238 | 0.2333 |
| Forward locomotion | Time stopped | -3.077 | % | 0.1310 | 0.0159 | 0.3333 |
| Forward locomotion | Posture height | 0.5197 | mm | 0.0476 | 0.2540 | 0.7333 |
| Slipping | Slip count | -3.672 | count | 0.0714 | 0.0238 | 0.5667 |
| Slipping | Total slip score | 142.4 | a.u. × frames | 0.9405 | 0.9286 | 1.0000 |
| Tail | Motion height | 0.1742 | mm | 0.9405 | 0.9841 | 0.9667 |
| Tail | Tail-motion score | -0.0653 | a.u. | 0.0298 | 0.0238 | 0.3333 |

Reproduce: tests/analyzeD14OutcomeSpecificContrasts.py. Existing outputs preserved; no canonical data modified. Do not select D14 rather than change because its p-value is smaller: the former asks about final levels, the latter about differences in changes. Nonsignificance does not establish equivalence.
