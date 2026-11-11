# Nine-frame temporal averages

Equal-weight arithmetic means of raw grayscale pixels in the moving post-mouse crops; no intensity stretch, registration beyond the existing crop tracking, or sharpening. Pixel averages rounded to uint8 for PNG. Nine samples at 160 fps: 56.25 ms of frame duration, 50 ms between first and last frame centres. Raised-tail original frames 1182–1190, centre 1186. Lowered-tail original frames 1635–1643, centre 1639. The same display scaling is used for both.

Each underlying crop was reconstructed from the source video and checked against its saved probability-weighted row motion profile; see crop_validation.json. Averaging uses unweighted crop pixels, not probability- or distance-weighted pixels. Blur reflects changes relative to the tracked crop, not isolated anatomical tail velocity. Reproduction: tests/exportMethodTailAverages.m. Source and earlier results preserved.

## Centre-emphasized illustration

`center_emphasized_50pct_original_*.png` uses 50% centre frame plus 50% nine-frame mean. Effective weights: centre 5/9, each of the eight other frames 1/18. Mean recomputed from the original crops before final uint8 rounding. Identical weights and intensity settings for both examples. These are illustrative temporal composites, not single source frames; measurements unchanged. Reproduce with tests/blendMethodTailFrames.py.
