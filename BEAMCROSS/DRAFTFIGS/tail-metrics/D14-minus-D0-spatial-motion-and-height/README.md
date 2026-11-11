# Tail changes along the beam, D14 minus D0

Reproduce with tests/exportD14TailSpatialProfiles.m then tests/plotTailSpatialChanges.py. Reuses existing D0-spatial-motion-and-height summaries. Reads canonical saved profiles and corrected whole-tail traces in place; no video processing or new tracking. MATLAB verifies frame counts, original-frame mapping, time and bad-frame alignment.

10 mm bins between tape positions; start left. Average valid frames within crossing, then equal crossing means within mouse/day. Subtract D0 from D14 within the same mouse and spatial bin, then group mean and SEM across paired mice. Each displayed bin requires at least half the group (SED6, WALK6, RUN9); missing bins remain gaps. No additional spatial smoothing or binwise tests. Different bins can have different contributing mice/crossings; coverage and paired values are saved.

Height is the probability-weighted full-profile median location of motion, relative to bar top, with five-frame smoothing restricted to contiguous valid runs. Score is NewWholeNormalized, the corrected whole-range tail score, masked for invalid pairs and existing tail bad frames. These spatial profiles use mean height within bins, whereas the scalar height scatter uses mean crossing median heights. The score profile gives crossings equal weight within bins, whereas the scalar score pools finite frames. Do not interpret these spatial curves as an exact decomposition of scalar scatter means.

Horizontal scale is 10 cm (100 mm), not 10 mm. Vertical scales: 10 mm height change and 0.5 a.u. score change. Zero is no change, not physical bar height. Original D0 results preserved.
