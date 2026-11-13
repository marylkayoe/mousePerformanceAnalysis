# Additional 7.5x MAD review

Six additional trials from three new mice (S09 sedentary, S04 walk, S18 run), D0 and D14. Selected from existing validated movie set before inspecting threshold outcomes. S09 shares TMCS3_C03 with earlier S08; S04 TMCS3_C02 and S18 TMCS2_C05 add two new cages. No new tracking or video outputs. Decoded selected lossless frames were SHA256 checked against saved mapping.

11 threshold-only peaks; nine survive saved motion-height<=0 at peak. D0 counts without/with gate: S09T4 4/4, S04T2 1/1, S18T3 1/1. D14: S09T2 3/2, S04T2 2/1, S18T1 0/0.

Visual peak-frame review: ten of eleven peaks show visible below-bar tail. All nine retained peaks do. Critically S09 D14 original1259 visibly has tail below, but the height gate rejects it (+6.5mm). S04 D14 original1590 has tail above and is rejected (+8.7mm). Thus the gate removes one anatomical-below detection and one tail-above detection in these additional trials. Peak-frame labels are single-agent unblinded observations, not independent ground truth or physical-slip confirmation. Repeated peaks can be within one tail-lowering episode. No recall estimate from event-only review.

Contact sheets show every threshold-only peak, labelled KEEP/REMOVE according to height, not according to visual truth. Source filenames, original/traversal frames, prominence and height are in each subfolder events.csv; zero-event trials remain in counts.csv. Existing invalid masks and full-profile smoothed motion heights retained. Reproduction: tests/reviewAdditionalTailThresholds.m (day0/default or14), tests/showAdditionalTailThresholdFrames.py (default or additional_trials_D14).

Production settings and previous results remain unchanged. This follow-up cautions against treating height<=0 as a universally reliable anatomical-tail gate.
