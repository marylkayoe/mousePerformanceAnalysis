# Six-panel tail movie: MAD5, height <= +7.5mm

Requested review variant, 2026-11-12. Same six source trials, validated lossless crops, 30fps playback, tracking-start trimming, final-frame hold, panel alignment, headings, black motion-height marker, purple profile and20mm scale bar as the previous horizontal movie. Green remains linear, red log1p with unchanged within-mouse full-trial display maximum. No change to underlying traces.

Only orange event markers change: original MATLAB5x robust-MAD prominence peaks, minimum separation0.1s, existing joint-valid masks, additionally require finite saved five-frame-smoothed full-profile motion height<=+7.5mm at the peak. Negative heights accepted. Markers remain at their peak column/display coordinates. This is a visualization test of the candidate rule, not a dataset-wide rerun or confirmation of distinct physical tail slips. User prioritizes avoiding false positives over false negatives.

Code: tests/renderMarkedTailExamples.py --log-below --horizontal --height-max-mm 7.5 --output-name presentations_log_below_horizontal_MAD5_height7p5. Existing outputs preserved; fresh output folder required. Inputs from parent trial folders. All decoded source crop frame hashes checked; saved motion-height agreement checked; output frame counts, dimensions,30fps and full decode checked. manifest.json records final event counts, mappings and scales after successful completion.

Canonical folder: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_D14_examples_marked_20261112/presentations_log_below_horizontal_MAD5_height7p5
