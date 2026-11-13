# D14 tail-video candidate review — 2026-11-12

User requested examples matching D14 tail results, with D0 context, following the
three-row/two-column under-bar presentations. This step finds candidates; it does
not render new tail movies or establish new biological results.

Inputs: corrected whole-tail trial-values.csv (sumLegacy/nLegacy) and
height-exploratory/trial-motion-height.csv (medianHeight; full-profile weighted
median with existing five-frame smoothing). Average crossings equally within
mouse/day. Rank mice by mean absolute standardized distance from their group's
D14 median mouse-day score and height, using within-group MADs. Select a crossing
closest to that mouse's daily means; independently select D0 near D0 daily means.
No tail-slip peak counts used; those saved counts cover D0-first/D14-last only.
This selection is for all-retained-crossing daily summaries, not last-trial figures.

Reproduction: tests/selectD14TailMovieExamples.py. Full shortlist:
D14_tail_example_shortlist.json. Exact filenames: tail_candidate_pairs.json.
Source review: tests/reviewTailCandidatePairs.py; 16 evenly spaced source frames
per crossing, six crossings. Contact sheets in:
 /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_D0_slip_example_review_20261112/group_presentations/tail_candidate_review

Preferred candidates:
- SED TMCS3_S08: D0 T1, D14 T1. D14 score .399, median motion height26.4mm,
  valid fraction .84. Visible tail lowering/under-bar periods near later traversal.
- WALK TMCS2_S19: D0 T3, D14 T1. D14 score .369, height33.7mm, valid fraction .80.
  Tail visible, variable elevation, mostly trailing in sampled frames.
- RUN TMCS3_S01: D0 T1, D14 T1. D14 score .360, height34.2mm, valid fraction .71.
  Includes under-bar tail periods; should preserve these, not imply runners never
  lower their tails.

These source-frame checks are not full temporal review, validated post-mouse
crop reconstruction, or anatomical tail tracking. Contact sheets use a
mouse-centered review crop that can clip the tail; this is not the analysis crop.
Before final movies use the on-demand validated preparation and inspect invalid
segments, especially runner's29% invalid motion-height frames.

D14 group medians of mouse daily means:
score SED .4464, WALK .4133, RUN .3445; height32.15,30.71,34.15mm.
Preferred actual crossings have small score differences; do not choose extremes
to exaggerate this pattern. SED candidate daily-mean score .522 differs from its
selected trial .399; report trial and daily values distinctly (JSON records both).
Existing under-bar S07/S20/S12 D14 T2 scores are .268/.351/.555, so that trio is
poor for illustrating the descriptive tail-score direction.
Earlier ready tail movies S09/S04/S18 D14 T2 scores are .688/.366/.371: easier
reuse, but exaggerate SED vs active-group contrast relative to typical values.

Movie green/red raw weighted contributions are NOT the independently normalized
scalar whole-tail score. Display scaling must be documented; per-mouse maxima
cannot support cross-group comparison of trace amplitudes. Motion height is
where image motion occurs, not anatomical tail position. No new inference or
significance claims. Existing movies/data unchanged.
