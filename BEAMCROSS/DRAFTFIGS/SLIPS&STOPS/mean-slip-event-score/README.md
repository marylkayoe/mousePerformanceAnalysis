# Mean slip-event score scatters

Each mouse/day: combinedSlipMagnitude / combinedSlips from analysis-data/pooled-exposures.csv. All detected slip events pooled across the three trials, including slips during stops. This is an event-weighted mean score, not the mean of three trial means, not a median, not total score per trial, and not a physical paw displacement. Score units are a.u. × frames from the original above-threshold accumulation. No-zero-slip days are treated as zero: they would be NaN and omitted from plotted estimates while retained in tables.

Retains the established three-crossing requirement for comparison with prior total-score panels: 41 mice D0,42 D14,41 paired. One two-crossing D0 mouse is excluded; full source filenames/counts/totals retained in mouse_day_values.csv; exclusions in validation.json. D14−D0 is difference of each mouse's mean event scores. Circles mice; diamonds arithmetic cage means; horizontal bars arithmetic mouse group means. No error bars or significance tests added. Full linear ranges, no clipping; same endpoint axes D0/D14. Changes use a separate range. Existing totals/CDFs unchanged.

Reproduce tests/plotMeanSlipEventScore.py. Combined and standalone editable SVGs and PNG previews, plus exact values and paired changes. Canonical source data read in place, no tracking or video outputs.
