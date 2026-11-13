# MAD4 plus motion height<=+7.5mm pilot

Exact MATLAB detector tested on the same12 trials,6 mice,5 cages. Keeps28 peaks versus25 atMAD5 with the same height cutoff. All25 prior peaks retained; three added: TMCS2_S18 D0T3 original1807(prominence4.636,height+0.816mm), TMCS3_S08 D0T1 original1756(4.953,+3.614mm), TMCS3_S01 D14T1 original1053(4.946,+4.080mm). All three show visibly below-bar tail in reviewed lossless peak frames; hashes verified against saved mapping. This remains unblinded calibration, not independent validation or proof of distinct physical slips.

Known S08 D0T1 vertical-tail episode around1467–1482 remains missed: previously identified peak around3.07xMAD and diagnostic local maximum3.22xMAD are below4. The two above-bar boundary examples with motion heights+8.6 and+8.7 remain rejected. User prefers false negatives over false positives. No production changes or new movie rendered in this test; previous six-panel movie still usesMAD5.

Canonical outputs: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_threshold_review_20261112/MAD4_height7p5. events.csv is ungated sweep; retained.csv applies<=+7.5mm; added.csv lists changes. counts.csv WithHeight is legacy<=0 tally, not the requested+7.5 tally. Use retained.csv for current rule. Reproduce: reviewLowerTailThresholds(4,'MAD4_height7p5'), tests/summarizeMAD4TailReview.py, tests/showMAD4TailFrames.py.
