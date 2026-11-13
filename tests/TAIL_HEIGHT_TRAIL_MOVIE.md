# Tail height-trail movie, 2026-11-13

Canonical output: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_minwidth15_smooth5_20261112/presentations_height_trail_purple_20261113`.
Main movie: `SED_WALK_RUN_D0_D14_tail_slips.mp4`; historical filename says slips, displayed events are exploratory deep tail swings. Six source filenames, mapping, events and scales are in manifest and sidecars.

Run `renderMarkedTailExamples.py` with `--height-trail --score-markers --log-below --horizontal --height-max-mm 7.5 --display-smooth-columns 5`, the minwidth15_smooth5 base, its `normalized_movie_events.csv` event table, and a fresh `--output-name`.

Green hidden. Row-motion profile black. Below-bar columns and persistent score-scaled markers purple. Median motion-height history extends left for 80 acquisition frames (0.5 seconds at 160 fps), colored black-to-red by crop-area-normalized whole motion, without vertical weighting, MAD normalization or speed division. Color limits are shared 5th/95th percentiles of smoothed locomoting activity across all six trials; saturation is display-only. Stops are gray. Color uses centered17-frame mean within contiguous locomotion-valid segments. Height retains existing five-frame smoothing. Below-bar/profile displays use temporal5-frame means and spatial5-point means (below spatial mean follows log1p mapping). Body-side exclusions and minimum-width15 probability rule come from validated input, not re-estimated.

Bounded missing display intervals of at most four frames are linearly interpolated; longer gaps remain missing. Original invalid masks remain in mapping and X remains visible; interpolated height-trail segments are dashed. No color interpolation across stops. No numerical event/score changes. Original data and movies preserved. All crop frame hashes, output frame counts/rate/dimensions and full decode are checked by renderer. `display_settings.json` and per-frame display CSVs document rendering. Presentation playback30fps, final frames held.

Only code/notes belong in Git. Movies and diagnostic previews remain canonical external outputs. No bulk scratch.

## Rightward trail revision
User requested older height history to extend right. New canonical sibling folder `presentations_height_trail_right_20261113`; same movie filenames and all other settings. Renderer now defaults to `--trail-direction right`; `--trail-direction left` reproduces the preceding version. No measurement changes.
