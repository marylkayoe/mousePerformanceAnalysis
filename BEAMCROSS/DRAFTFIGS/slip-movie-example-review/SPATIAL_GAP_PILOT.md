# Tail-width spatial gap filling pilot — 2026-11-12

Canonical outputs: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_spatial_gap_test_20261112
Input: balance_beam_normalized_tail_examples_v2_20261112; same six crossings, no new tracking or crop reconstruction. Source videos and previous results unchanged. This is an experimental six-trial illustration, not a dataset rerun or detector validation estimate.

## Operation and choice
User requested narrow spatial gap filling comparable to tail thickness. At original S17 D0 frames1538,2117,2242, horizontal half-contrast widths below the beam were approximately6,5.5,4 decoded pixels respectively. Measurements sampled rows236:5:271, searching columns71–170, used (row background median + dark center)/2 and required contrast>25 gray levels. This is a horizontal apparent width in selected examples, not a precise anatomical calibration. Six pixels (~3.50mm at700/1201 mm/px) used as an upper typical tail-width bound. Sensitivities:0,3,4,5,6 pixels. No per-group tuning.

Take the square root of saved destination probability-squared weights. Fill ONLY contiguous exact-zero runs of <=N columns bounded immediately on BOTH sides by strictly positive probability; interpolate linearly between those neighboring probabilities, then square. All originally nonzero weights unchanged. Edge-connected/broad exclusions unchanged. No spatial interpolation of the resulting motion trace; original grayscale pixels retained. No temporal filling of invalid frames.

Recompute unchanged above-/below-bar row-weighted contributions and unweighted-in-height row-motion profile using modified column probabilities. Below ramp1 at first below row to2 at halfdepth then plateau; above original ramp unchanged. Recompute motion median height with original5-frame averaging within valid runs; preserve source invalid/nonfinite row masks. Re-estimate per-trial median and1.4826MAD from valid modified raw below sums. Detector remains positive normalized amplitude>3.5, closing5, minimumcomponent5, peak height<=+7.5mm. Score=sum excess above3.5. Thus weights can change baseline/MAD and height as well as raw amplitude; modified z may decrease at unchanged frames.

## Findings
No detected event counts changed at ANY tested gap size in these six trials. At gap6 counts remain SED6/3, WALK3/2, RUN3/1 forD0/D14. Total scores change from330.38/162.74 to382.89/194.80 (SED);187.33/117.43 to260.12/143.02 (WALK);456.14/19.70 to490.39/20.88 (RUN). These selected-trial changes cannot establish groupwise bias.

RunnerD0 frame2242 (36.50s): raw235.72→250.68; normalized2.962→3.248, still below3.5; height3.26→0.47mm. At frames2085 and2117 raw sums unchanged at those specific frames, because no eligible narrow gap was filled there. Re-estimated normalized amplitudes3.876 and5.246; no accepted new event. Narrow-gap repair alone does not resolve late missed episodes.

## Validation
Zero-gap above/below column contributions reproduce existing exports at maximum absolute differences~1.1e-13. Row-profile largest observed absolute discrepancy1.90e-6; all pass mixed1e-6+1e-6*abs(reference) tolerance (saved row profiles lower precision). Invalid row NaNs preserved. Original smoothed height checked includingNaNs, and all zero-gap event counts/start/end/peak/height-pass fields exactly match saved normalized detector; scores agree within1e-5+1e-6*abs(reference). Pixel hashes checked for every lossless crop frame. Synthetic bounded-gap test confirmed edge gaps and seven-column gaps stay excluded, original nonzero weights unchanged and interpolation correct. Movie renderer independently checks smoothed height, mapping, pixel hashes, full decode,fps,dimensions and framecounts.

## Movie and limitations
presentations_gap6/SED_WALK_RUN_D0_D14_tail_slips.mp4; green2xlinear, redlog1p, fixed frame alignment30fps and final-frame hold; persistent marker area above minimumarea proportional to eventscore, commonmax across sixpanels. Display maxima are recomputed from this modified six-trial package, so use comparison_trace.csv for numerical before/after comparisons rather than movie amplitude alone. Modified masks_height and row/column arrays are explicit experimental data; preparation_status says experimental. Original lossless crops/frame mappings/source columns reused through symlinks; movies standalone. Legacy tail_slip_events.csv links are NOT the event input; normalized_movie_events.csv is authoritative.

Code tests/testTailSpatialGapFill.py (optional fresh output path, refuses existing root), then tests/renderMarkedTailExamples.py --base ROOT --log-below --horizontal --height-max-mm 7.5 --green-gain 2 --score-markers --event-table ROOT/normalized_movie_events.csv --output-name presentations_gap6.

No full-cohort statistical analysis changed; further visual review needed before adopting. No commit/push requested. Bulk products external, small code/notes in repo. No bulk scratch.
