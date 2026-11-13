# Updated example and D0 tail-height panel — 2026-11-13

Canonical results: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_centroid3_height10_20261113/figure_panels

D0 scatter: first retained crossings, 42 mice/15 cages. Mean full-profile motion height across valid frames, including stops; 3× centroid override. Dots=mice, diamonds=cages, horizontal bars=mouse group means. Exact cage permutations within cohort omnibus p=0.5581349206; pairwise values in figure_metadata.json. This is motion location, not a stationary anatomical tail estimate.

Example: TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4; original frames856–1822;160fps. Existing tracking/crops read in place. Reconstructed baseline matches saved row profiles, whole/below motion and motion height; no reconstruction failures. Current3× centroid mask, minimum exclusion width15; 5-frame motion height. Color uses whole motion /geometrical crop area ×1000, 17-frame mean within locomoting valid runs; stops gray; no vertical, speed or MAD normalization for whole motion. Color limits are example5th/95th percentiles2.9283–6.2387 (0.001 a.u./pixel). Preserve gaps. Image referencesa/b remain original1186/1638.

Below trace unchanged: raw5-frame smoothing, median/1.4826MAD, positive clipping; threshold3.5, closing/minimum5frames. Updated peak-height gate<=10mm.3 accepted swings; summed excess area119.7491598839. Stops allowed. Purple markers and shaded excess area; no physical momentum interpretation.

Supplied SVG retained for typography/layout/images. Source template tests/figure_templates/tail_example_centroid3_requested.svg; generator tests/makeTailCentroid3ExamplePanels.py. Reconstruction BEAMCROSS/analyzeTailCentroidBoundary.m now accepts optional files/referenceRoot; defaults unchanged. validated_example holds compact2×/3× traces (only3× plotted). Initial reconstruction directory contains failed filename-argument parsing logs only; no scientific output was used. Fixed char-to-string conversion before successful rerun.

These small editable SVG/CSV/JSON copies are for Illustrator. Canonical outputs and preview PNGs stay externally; original figures/results remain intact. No commit or push performed.
