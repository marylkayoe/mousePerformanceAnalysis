# Above-bar tail motion by position

Exploratory, descriptive profiles from the Mac mini L40 rerun archive. The
plotted quantity is `TailAboveBar`, the existing frame-level above-bar tail
motion trace, normalized within each crossing by that algorithm's median and
MAD. It is an index in arbitrary units, not physical tail displacement. The
negative values represent below-median normalized motion, not negative movement.
The x coordinate is the mouse centroid, not the tail tip or the place in the
image where the motion occurred. Crop motion and non-tail image changes may
contribute. Original reference exports contained scalar tail-trace placeholders;
although the rerun scalar metrics matched, frame-level traces lack independent
reference validation.

Coordinates use the entry-right common camera-field fraction and the approximate
tape centers at pixels 42 and 1243 from a single calibration video. The axis
is 0 mm at the exit-side mark to 700 mm at the entry-side mark. Plots place
entry on the right, matching the slip/stop position plots; the current
posture/speed trajectory files have a reversed displayed x-axis. The common
position is not a trial-specific tape calibration.

D0 and D14 use 250 direction-consistent validated crossings: sedentary 36,
walk 36, run 52 on D0; sedentary 36, walk 36, run 54 on D14. All 42 mice
contribute at least somewhere. One D0 run crossing was excluded for inconsistent
entry direction and another was absent from the retained trial set. Finite
centroid and above-bar motion values within the tape marks are assigned to 10 mm
bins; the original tail bad-frame flags are excluded, not set to zero. Frames
within a stop are retained. First average the available frames in each trial
and position bin, then average available crossing means equally within each
mouse and position bin. Lines are means across mice; bands are across-mouse SD
or SEM as labeled. More time spent in a bin gives that trial more frames in its
within-bin mean, but does not increase its weight across trials or mice.

Dashed lines indicate fewer than half the group's mice; at least two mice are
required to draw the trace or band. Positions with no line have insufficient
valid data, not zero movement. The region near the entry mark has especially
low coverage because tail crop frames are flagged invalid. Group counts in the
legend are total mice with any contribution, not the sample size at every bin;
`group-position-bin-summary.csv` records per-bin counts. No smoothing or
inference by position is applied. Positions are bins and not independent
replicates; the shading is descriptive and not a cage-aware group test.

`prepare_position_profiles.py` reads the frame traces and trial manifest from
`../analysis-data/`, and writes trial- and mouse-level bin data, frame counts
and group summaries; `plot_tail_position.m` writes PNG, FIG and SVG. CSV rows
preserve original complete trial filenames.

## Pooled histogram-style view

`tail-above-pooled-days-histogram-10mm` overlays D0 and D14 as bars in 10 mm
bins. Each bar is the mean of available mouse-level means across all groups,
not a count of tail movements or a sum of motion over time. Individual mice
have equal weight; therefore groups with more mice contribute more to the
pooled mean. The lower panel shows the number of contributing mice per bin;
all bins with valid data are shown. The position range without valid data is
blank, not zero. This is descriptive and does
not establish a group or day effect. `pool_tail_positions.py` and
`plot_pooled_tail_histogram.m` produce this view and its per-bin summary.

The D0 combined tail/slip/stop histogram uses 10 mm bins over 0–700 mm,
pooled groups and the same 124 eligible crossings. Tail bars show the mean of
available mouse-level tail indices and a separate panel shows contributing mice;
slip and stop bars are raw event counts. Slips overlapping any stop are omitted only for
this combined display; main slip counts retain those events. The tail profile
and event counts use different summaries and their bar heights are not
directly comparable. The side-by-side profiles are descriptive and do not
establish that tail motion precedes or predicts individual slips. See
`d0-pooled-tail-slips-stops-10mm.csv` and the associated prepare/plot scripts.

The `d0-pooled-tail-slips-stops-histograms-10mm-all-data` version displays every
bin with at least one valid mouse and adds a separate contributing-mouse panel.
In D0, the 620–630 mm bin has data from three mice and a negative mean index;
630–700 mm has no valid data. Negative normalized values mean below that
crossing's median signal, not negative physical motion.
