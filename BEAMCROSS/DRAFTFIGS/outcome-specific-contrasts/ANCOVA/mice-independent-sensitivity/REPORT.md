# Mouse-independent ANCOVA sensitivity — 2026-11-11

Requested hypothetical comparison, NOT a replacement for cage-aware inference. Same paired mouse sets, metric definitions, conversions, D0 adjustment, cohort fixed effect, common slope and additive group effects as the cage-level ANCOVA. Here each mouse is a separate equally weighted observation, and cage dependence is deliberately ignored. There are 42 mice/37 residual df (speed, posture, tail) or 41/36 df (slipping/stopped percentage). All p-values are two-sided, outcome-specific and unadjusted; RUN–WALK remains primary. HC3 allows unequal variance between mice but DOES NOT repair dependence between mice sharing cages.

Comparing the analyses changes both independence assumptions and aggregation/weighting: cage-level means weight cages equally; this model weights mice equally and estimates a mouse-level baseline association. Differences cannot be attributed solely to an arbitrary penalty for cages. Neither model resolves nonrandom group allocation. This check cannot establish that the study would have succeeded under another design, nor that nonsignificant results demonstrate no effect.

| Metric | RUN–WALK p, mice independent | RUN–WALK p, cages | RUN–SED p, mice independent | RUN–SED p, cages | WALK–SED p, mice independent |
|---|---:|---:|---:|---:|---:|
| speed | 0.2093 | 0.3134 | 0.0225 | 0.0478 | 0.3168 |
| time_stopped | 0.1693 | 0.2754 | 0.0302 | 0.0374 | 0.3992 |
| posture | 0.0616 | 0.1080 | 0.5030 | 0.4017 | 0.2812 |
| slip_count | 0.2424 | 0.3912 | 0.0281 | 0.1257 | 0.2963 |
| slip_score | 0.8986 | 0.9837 | 0.7677 | 0.8682 | 0.8745 |
| motion_height | 0.7242 | 0.6153 | 0.7646 | 0.8192 | 0.9727 |
| tail_score | 0.3330 | 0.2380 | 0.0097 | 0.0049 | 0.1252 |

Reproduce: tests/analyzeMouseIndependentANCOVA.py. Full estimates, standard 95% intervals, HC3 sensitivity and baseline slopes are in results.csv/json; exact inputs in mouse_inputs.csv/json. Original cage ANCOVA and canonical source data preserved. These are small repository sensitivity outputs, not new canonical measurement results.
