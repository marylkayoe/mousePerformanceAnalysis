# Runner D0 end review
TMCS2_S17_T2_C05_BB_D00_20251022_THT_TRIAL1_gray.mp4. Presentation time starts at original frame 1147, playback 30 fps (analysis 160 fps).

Visible below-bar tail motion is missed near the end. At frame 2085 (31.27 s), normalized amplitude 4.027 and height +4.08 mm pass amplitude/height, but the closed component spans only frames 2084–2085 (2 frames), below the required 5. At frame 2117 (32.33 s), amplitude 5.445 and height -6.53 mm pass, but component 2117–2119 lasts 3 frames. These are genuine duration-filter false negatives for visibly below-bar tail motion. The original detected events are earlier, at frames 1435,1482,1538.

At frame 2242 (36.50 s), tail is clearly below the bar and height +3.26 mm passes, but amplitude 2.962 fails the 3.5 threshold. Frame 1993 (28.20 s) amplitude3.129 and height12.36 also fail. At frame2313 (38.87s), tail is raised: amplitude6.153 component is only1frame and height29.96 fails, so rejection there is appropriate for the present definition.

Destination-frame no-mouse probability weights retain approximately86% of ALL below-bar distance-weighted motion at frames2085 and2117,77% at2242. These ratios include background/body/paw contributions and are NOT tail-specific. Weighting may contribute to signal loss, but the direct rejection stage for the two above-threshold late episodes is minimum component duration. All reviewed frames joint-valid. Lossless hashes checked and weighted below sums reproduced saved NewBelowRaw within1e-5+1e-6*abs(reference). No detector or movie modifications in this review.

A sensitivity check of minimum duration (e.g.3 vs5 frames), holding amplitude and height fixed, would address the32.33s miss but not the2-frame31.27s miss or subthreshold36.5s movement. Such a change requires broader visual false-positive review; don't infer its suitability from this selected trial alone.

Code tests/auditRunnerD0TailEnd.py; frame_audit.csv and late_frames.png preserve evidence.

Canonical audit: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_normalized_tail_examples_v2_20261112/runner_D0_end_review
