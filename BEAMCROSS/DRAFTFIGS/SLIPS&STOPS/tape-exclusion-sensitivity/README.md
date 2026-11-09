# Tape-mark exclusion: exploratory sensitivity analysis

Paired comparison of the same mouse-days using all events versus events whose
midpoint centroid falls between approximate tape centers at zero-based image
pixels 42 and 1243. These coordinates come from one calibration video, not
individual trial calibration. Includes only mouse-days with three retained
crossings, matching the original total-slip and stop statistical presentation.
D0: 39 mouse-days; D14: 42; paired change: 39. One additional D0 mouse-day had
only two crossings in the original source and is excluded under the existing
three-crossing rule. Two D0 mouse-days were excluded from both variants and
all three measures: one has an event with a missing centroid and one has an
inconsistent entry-direction check. Details and filenames are in
`excluded-mouse-days.csv`. The D14 and change samples are therefore not the
same population; each before/after comparison uses identical observations.

Each measure uses cage means and the same within-cohort exact permutation
procedures as the earlier analysis. Overall tests are raw; pairwise p-values
use Holm adjustment across the three group pairs for each measure and period.
The nonoverlap slip measure removes all slips with any temporal overlap with a
stop, matching the exploratory histograms. The total-slip measure includes
those events. The stop measure counts stops by midpoint position. The
within-mouse change is D14 minus D0, compared between groups.

Data: `matched-mouse-days.csv`, `group-means.csv`, `comparisons.csv`.
`analyze.py` reproduces these results from the event, manifest and
pooled-exposure files saved in `../../analysis-data/`. The exclusion rule was considered
after inspecting the data, so interpret this as exploratory; the outcome of
the comparison is not a reason by itself to select the rule as primary.
