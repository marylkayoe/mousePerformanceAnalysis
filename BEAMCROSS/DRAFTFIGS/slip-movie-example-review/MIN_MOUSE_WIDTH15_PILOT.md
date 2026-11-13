# Minimum mouse-present exclusion width: 15-column pilot

2026-11-12, canonical output /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_min_mouse_width15_20261112. Code tests/testTailSpatialGapFill.py accepts OUTPUT 15 minimum_mouse_width. Six-trial input unchanged: balance_beam_normalized_tail_examples_v2_20261112, including walkerS09 replacement. No canonical measurement overwrite or full-cohort rerun.

## Exact rule
Start from saved no-mouse probabilities after the historical .85 cutoff (sqrt of saved squared weights). Label contiguous exact-zero column runs separately for each frame. Preserve the run touching crop column0, which is anchored at the mouse centroid and is the body-connected exclusion. Every other excluded run of width<=15 is removed by assigning probability1 (squared weight1), including runs at the far crop edge. Runs>15 stay excluded; all previously nonzero probabilities stay unchanged. This is not an anatomical segmentation. A tail joined to the broad body-connected run remains excluded. Fifteen decoded pixels correspond to8.74mm, exceeding the4–6pixel horizontal widths measured in selected thin-tail samples; threshold explicitly requested by user.

Compared with bounded-gap interpolation, this changes BOTH edge eligibility and replacement weight (full1 rather than interpolated neighboring probabilities). Benefit cannot be attributed solely to the width criterion. Saved thresholded weights cannot recover the original sub-.85 probabilities; assignment1 is an explicit experimental override.

Above/below contributions and row profiles are recomputed from pixel-identical lossless crops, with unchanged vertical weights. Motion-derived median height and5-frame smoothing are recomputed. Each trial's median/MAD baseline is recalculated; amplitude>3.5, temporalclosing5, minimumcomponent5 and peakheight<=7.5mm retained. Nonfinite row masks and invalid frames preserved. Thus there is no relaxation of event threshold/duration/height. Movie uses new normalized_movie_events.csv.

## Vertical-tail checks (runnerS17 D0)
Original frame2117, presentation32.33s: formerly rejected3-frame component; now accepted2117–2125 (9frames after closing). Peakz5.139, height-6.53mm, score4.6777. Pixel-hash-checked frames2117,2121,2125 all show tail belowbar. Peakframe raw motion itself unchanged; surrounding-frame recovery extends/joins the component. Gallery vertical_tail_review.png.

Frame2085 (31.27s): z3.795,height2.21mm, only1frame afterclosing, still rejected. Frame2242 (36.50s) clearlyverticaltail: raw235.72→255.60,z3.309,height-3.03mm, still subthreshold. Nearby2237–2239 is a3-frame above-threshold component and also rejected. So the broader visual episode still is not detected. Frame2313 tailraised:1frame andheight29.96mm, appropriately rejected under current criteria.

Counts original→modified: SED D0/D14 6/3→6/3; WALK3/2→3/2; RUN3/1→4/1. Scores: SED330.38/162.74→472.80/202.83; WALK187.33/117.43→292.59/148.21; RUN456.14/19.70→547.57/21.95. These are selected examples and do not establish full-dataset sensitivity or specificity. New event visiblybelowtail, but existingevent peakpositions/durations/scores can also change.

## Validation/storage
Zero-modification branch matches saved column contributions (~1e-13absolute), saved rowprofiles mixed1e-6+1e-6*abs(reference), smoothedheight and all saved event boundaries/peakframes/passheight flags, and eventscore within1e-5+1e-6*abs(reference). Every decoded lossless frame hash checked. Synthetic rule tests preserve3-column bodyedge, remove15-column and2-column far-edge exclusions, preserve16-column exclusion and nonzero weights. Renderer checks independentheight/mapping, framecounts,30fps,dimensions and full decode.

Movie presentations_minwidth15/SED_WALK_RUN_D0_D14_tail_slips.mp4. Greenlinear2x, redlog1p, per-mouse scaling recomputed, marker area above minimum scaled by eventscore across sixpanels, same starttrim/finalhold. Use numerical CSVs for quantitative comparison because displaymaxima are recomputed. Original and all previouspilot outputs retained. Lossless input links point to existingcanonical packages; finalmovies standalone. Newdata external; smallcode/notes inGit workingtree, no commit requested.
