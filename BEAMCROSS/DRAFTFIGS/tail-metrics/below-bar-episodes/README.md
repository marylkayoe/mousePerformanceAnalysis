# Below-bar motion episodes

Reproduce `tests/countBelowBarMotionEpisodes.m` in MATLAB R2024b. Read canonical L40 probability-weighted row profiles and frame CSVs in place for all retained D0/D7/D14 trials. No videos/tracking or source-result changes. Compact derived event and trial tables only.

Height is full-profile probability-weighted median row motion relative to bar top, scaled700/1201mm/px, then centred5frame moving MEAN within contiguous finite segments, shortened at segment ends. This matches exportTailCDFValues.m. Neither corrected distance-from-bar ramp nor scalar normalized tail score weights enter this height. TailBadFrame OR invalidFramePair invalidates a sample; nonfinite/negative row values or no motion also invalidate height. No bridging invalid gaps or zero filling.

Threshold strictly height<0; zero is nonnegative. No minimum duration, hysteresis or merging. Count maximal contiguous observed negative segments. `ObservedDowncrossings` counts only those preceded immediately by a valid nonnegative frame; `CompleteEpisodes` also requires a following valid nonnegative frame. Boundary/gap-truncated segments retained, left/right flags and reason codes explicit. A negative segment after a gap is not a proven new event; events could span or occur inside missing data. Segment count is not the number of true physical tail dips.

These are episodes where the median detected motion is below the bar, not stationary anatomical tail position. Fraction below is BelowZeroFrames/ValidHeightFrames, not all traversal time. Zero valid frames ->NaN. Zero episodes with valid data is a legitimate zero. Duration is inclusive observed frames / analysis frame rate, not endpoint timestamp subtraction. Encoded video timestamps and original frame mapping preserved alongside analysis frame rate; flags identify censored durations. Original bad-frame masks remain in canonical source profiles; derived missing counts retained here.

No independent-event group statistics, no minimum-duration tuning. Inspect representative episodes against movies before interpreting counts biologically. Counts may be sensitive to threshold flicker and missingness. Full filenames, mouse/cage/group/day/original trial IDs included. These small tables are reproducibility/figure materials; original profiles and videos remain canonical on ShosaiData.

## Validation and results

377 trials processed: D0 125, D7 126, D14 126. Observed negative segments: 449, 658, 399; observed downcrossings: 445, 654, 389; complete episodes: 438, 644, 385, respectively. These totals pool crossings and are not group comparisons.

All 251 D0/D14 cached frame traces independently reproduce the negative-frame counts, valid-frame counts, and every segment boundary exactly (tests/validateBelowBarEpisodes.py; validation.json). D7 uses the identical reconstruction but lacks an independent cached trace. An initial movmean implementation differed at near-zero values due to arithmetic rounding; final extraction uses the original explicit five-frame mean loop exactly. No epsilon threshold was introduced. No video review was performed for this new episode metric.

Display terminology: "Tail slips" = detected peaks in corrected raw below-bar motion (5-MAD prominence,0.1s separation); "Below-bar motion" = observed negative-motion-height downcrossings. These are operational labels, not confirmed physical slips or anatomical tail position. Figure filenames retain original metric identifiers for compatibility. Labels revised without changing data/statistics.
