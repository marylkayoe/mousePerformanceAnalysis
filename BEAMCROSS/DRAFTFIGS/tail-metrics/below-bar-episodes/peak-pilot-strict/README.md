# Stricter peak pilot

User correctly noted that original 1-MAD peak detection marked background-sized fluctuations. This revision preserves original outputs and unchanged raw traces, heights, masks, frame mapping and weights. Exact frames.csv byte equality checked against original pilot. Same six crossings; no source/result modifications.

Illustrated prominence threshold=5 times trial-valid 1.4826*median(abs(raw-median(raw))); minimum separation0.1s. Sensitivity grid prominence3/5/8 and separation0.05/0.1/0.2s. MATLAB findpeaks within valid segments, unchanged unsmoothed raw amplitudes. MAD sets only detection prominence, not displayed amplitude. Candidate thresholds remain exploratory and trial-relative, not validated biological event criteria.

Default counts SED D0/D14=8/4,WALK=3/6,RUN=3/3 (27 total), versus original172. 13/27 peaks have negative smoothed motion height at peak. This replaces the earlier permissive detector as the current visual pilot. Earlier conclusion that height is more robust is premature: substantial part of the apparent over-detection came from an insufficient prominence threshold. Retain distinction between location of dominant motion and amplitude of below-bar motion; neither is anatomical tail position.

Reproduce: compareBelowBarPeaks(true) in MATLAB, then tests/plotBelowBarPeakPilot.py --strict. Parent peak-pilot/README.md records source paths and prior frame validation. No new video review performed in this stricter revision. SVG/PNG, candidate table, sensitivity table and summary are here.

Display terminology: "Tail slips" = detected peaks in corrected raw below-bar motion (5-MAD prominence,0.1s separation); "Below-bar motion" = observed negative-motion-height downcrossings. These are operational labels, not confirmed physical slips or anatomical tail position. Figure filenames retain original metric identifiers for compatibility. Labels revised without changing data/statistics.
