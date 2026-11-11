# Stop-time percentage

Per mouse/day: 100 × sum(validated stopped frames / analysis fps) / sum(traversal frames / analysis fps), across three retained crossings. This is a duration-weighted percentage, not mean event duration or an unweighted mean of trial percentages. Uses CorrectStoppedFrames, not the inconsistent legacy total-stop-duration field. All 377 trial stop totals match summed saved event durations; traversal lengths match original-frame endpoints. No tape-position exclusions. Traversal means the tracked interval, not the full source video.

For consistency with count figures, TMCS2_S10 D0 (two crossings) is excluded, as is its paired D14−D0 change. D0/change: 41 mice; D7/D14: 42. Within-mouse changes are percentage points. Nonfinite values are not replaced with zero.

Statistics reuse ../.. /tail-metrics/whole-motion-reweighted/cage_tests.py (path without space): cage means, exact label permutations within cohort; three pairwise tests Holm-adjusted per panel. No correction across days/outcomes. Cohort-stratified permutation assumption follows existing analyses; confirm allocation stratification. Exploratory analysis. Mouse group mean bars are not cage-balanced estimates.

Reproduce with analyze.py using Python + NumPy + Pillow. CSV tables, editable SVG and PNG are generated here. Original scientific data and analysis pipeline unchanged.

## Figure decision (2026-11-11)

Prefer percentage of tracked traversal time spent stopped as the main-figure stop outcome; do not show a second stop-count panel in that figure. A brief movement can split one pause into two detected stops and change the count substantially while changing total stopped time only slightly. This is a methodological rationale, not a demonstrated robustness test. The percentage remains sensitive to the speed threshold, tracking noise, stop-mask processing and traversal boundaries; it also depends on traversal duration.

Retain stop counts and existing statistics for a possible supplementary/data table, with a note about event fragmentation. Do not delete the count figures or tables. This presentation preference was discussed after viewing the results; preserve that chronology. For D14−D0 stopped-time percentage, the current between-group test is not significant (overall p=0.637857); selection of the measure does not establish a change effect.
