# Revised normalized tail example movie — 2026-11-12

Replaces only WALK with TMCS2_S09: D0 first retained trial 1 and D14 last retained trial 3. It was second in the original D14 joint count/total-score distance ranking, after S33. D14 count 2 and score 117.4296; D0 count 3 and score 187.3287. The five peak-frame crops were visually reviewed and each shows a below-bar tail. Two nearby D0 peaks may represent motions within one lowering episode. These are selected illustrations, not unbiased validation or evidence of a representative longitudinal change.

SED S30 and RUN S17 reuse validated inputs from the previous package via absolute symlinks, avoiding duplicate bulk data. The completed movies are standalone. The runner D0 remains unusually high and is context, not a typical improvement example. All selected mice are TMCS2.

Detector unchanged: per-trial positive median/MAD-normalized corrected below-bar motion, amplitude >3.5, closing length 5 and minimum component length 5, peak motion height <=+7.5 mm. Event score is sum(max(z-3.5,0)) over the component; no fps division. Invalid masks and original-frame mapping retained.

Marker radius in output pixels = sqrt(4^2 + (12^2-4^2)*score/max_score), with max_score across all displayed events. Thus marker AREA above a minimum visible area is proportional to score, with one common scale across all groups and days. It is deliberately not a zero-based proportional-area display. Exact radii, scores and shared maximum are recorded in marker JSONs and manifest. Green gain 2, red log1p and per-mouse raw display maxima remain unchanged; scale calculated before start trimming. Rendering is 30fps, first-valid aligned, with held final frames.

S33 D0 ~13s: original frame 1428 peaks at normalized amplitude 3.1914, motion height -0.816 mm; no amplitude >3.5 in the checked 12–14s window. This is a missed visible below-bar tail episode at the amplitude stage, not the height gate. User proposes vertical tail suppression by the no-mouse filter. Code indeed sets no-mouse probability below .85 to zero before squaring destination-frame column weights, so this is a plausible mechanism, not yet quantitatively established for this event. The replacement does not resolve detector sensitivity. Original S33 movie retained unchanged.

Revised interpretation of SED D14 frame 777: user identifies possible trailing paw movement. Classify as real below-bar movement possibly paw-derived, not confirmed noise/false-positive motion. Current detector cannot distinguish tail from a trailing paw in this region. No measurements or event selections altered for this interpretation.

New walker reconstruction passes saved row profiles and NewBelowRaw comparisons using abs(error)<=1e-6+1e-6*abs(reference). No saved independent above-bar per-column reference exists for these trials. Renderer checks all lossless pixel hashes, frame mappings and recomputed smoothed heights, followed by full output decode, frame-count/dimension/fps checks.

Reproduce: prepareNormalizedTailExamples(new_root, selection_json) in MATLAB R2024b; tests/exportNormalizedMovieEvents.py new_root selection_json; tests/renderMarkedTailExamples.py --base new_root --log-below --horizontal --height-max-mm 7.5 --green-gain 2 --score-markers --event-table new_root/normalized_movie_events.csv --output-name presentations_score_markers. Code and selection JSON in repository; bulk canonical outputs here. Existing results preserved. No commit/push requested.

Canonical package: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_normalized_tail_examples_v2_20261112
