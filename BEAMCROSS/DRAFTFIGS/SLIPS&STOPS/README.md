# Slip and stop draft results

The figures and tables summarize Tara's saved results for total slip count,
total slip magnitude and total stop count across three retained crossings per
mouse and day. One mouse has only two retained D0 crossings and is excluded
from the D0 and D14-minus-D0 summaries, but retained on days with three.

Figures show mice, cage means and mouse group means. Overall p values are
unadjusted; pairwise p values use Holm correction across the three group
pairs for that measure and comparison period. Tests compare cages within
cohort; no correction is made across measures or days. Allocation was
randomized by cage; confirm whether randomization was stratified by cohort.

The original Tara summary did not include event-frame indices. The later
Mac mini L40 rerun recovered slip and stop intervals and frame-aligned
centroid positions; the event data and manifest are saved in `../analysis-data/`.

## Position histograms in millimeters

The latest pooled D0 and D14 histograms use the approximate tape centers at
zero-based image pixels 42 and 1243 as 0 and 700 mm, with 10 mm bins. Event
midpoint centroids outside these marks are excluded; events in end bins inside
the marks remain included. Tape locations come from one representative video,
not separate detection per trial. Entry is on the right. The 250 eligible D0/D14
crossings all have 1280-pixel image width. These exploratory histograms exclude
slips overlapping stops and do not represent the main total-slip outcome.

## Interpretation and presentation decisions

- The main slip-count outcome includes detected slips even when they overlap a
  stop. A slip can coincide with, or potentially lead to, stopping; temporal
  overlap alone is not a reason to remove it from the slip count.
- The exploratory combined slip-and-stop positional scatters and histograms
  omit slips with any stop overlap for visual clarity when stops are displayed
  as well. These are filtered displays and do not represent all detected
  slips. Their titles and captions should state that omission explicitly.
- At the beginning and end of the camera field, part of the mouse may be
  outside the image. As the mouse enters or leaves, the visible silhouette
  changes shape and size, so the measured centroid can move differently from
  the animal. For example, as the mouse exits, its visible body can shorten
  even while it moves forward. This can affect measured speed and stop and
  slip detection. The physical situation and the mouse's behavior can also
  differ near the ends of the beam.
- The approximate tape-mark restriction is an exploratory sensitivity analysis,
  not a replacement for the full-crossing slip measure. See
  `tape-exclusion-sensitivity/README.md` for the paired comparison and its
  limitations. Choose a spatial exclusion based on the measurement and study
  question rather than on whether it changes statistical significance.
