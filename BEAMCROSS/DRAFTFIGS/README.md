# Balance-beam draft figures

## Draft publication tables

These are editable CSV drafts, with cage / mouse / trial counts and group
summaries. D0 is descriptive; D14 includes cage-aware group tests and Holm
adjustment across the three group pairs for each measure.

- [D0 speed, crossing duration and posture](speed-presentation/speed-selected-D0-descriptive.csv)
- [D14 speed, crossing duration and posture](speed-presentation/speed-selected-D14-group-comparisons.csv)
- [D0 slips and stops](SLIPS%26STOPS/slips-stops-D0-descriptive.csv)
- [D14 slips and stops](SLIPS%26STOPS/slips-stops-D14-group-comparisons.csv)

The speed and posture rows in these tables are still in pixels and pixels/s,
not the millimeter units used in the newer spatial figures. These are drafts,
not finalized publication tables; review the statistical families and units.

## Transfer data

`analysis-data/` contains the complete per-frame CSV traces from the 377-trial
L40 rerun (in `tail-and-behavior-frame-traces.zip`), the derived event and
trial-manifest tables, pooled exposure data, and small analysis inputs needed
for the figures and sensitivity comparison. The zip retains full original
trial filenames and the rerun methods and validation report. It does not
contain the source videos or the larger per-row motion profile matrices; those
remain in the Mac mini Tara project results archive. The tail and sensitivity
scripts use these repository copies, rather than temporary files.

## Speed presentation

For the current speed presentation, retain three measures: combined crossing
duration, whole-crossing speed while locomoting, and first-to-last change in
locomoting speed within a day. The user confirmed that allocation to groups
was randomized by cage.

The `speed-presentation` folder contains a D0 table and a separate D14
group-comparison table. In the D14 table and the speed and posture presentation
figures, the three group-pair p values are Holm-adjusted separately within
each measure and comparison period. Overall p values are unadjusted. No
correction is applied across measures or days. D14 group differences and
D0-to-D14 group differences in change answer distinct questions.

The position-dependent speed profile peaks in the middle of the beam. Keep the
absolute speed-versus-position plots as descriptive views of that pattern.

For the within-day slowing analysis, use **whole-crossing speed while
locomoting**: compare each mouse's first and last retained trials. Keep the
middle-third analysis as an exploratory comparison rather than the main test.

- `within-day-slowdown.fig` / `.png`: locomoting speed for successive trials.
- `first-last-speed-change-statistics.fig` / `.png`: first-to-last percentage
  change, with mice, cage means and cage-aware group comparisons.
- `speed-presentation/speed-by-group-mm.*`: absolute forward-speed profiles
  by position, including stops.

One mouse has only two retained D0 trials; the first-to-last change uses those
two. The displayed statistical comparisons are exploratory, and the correction
families shown on each figure should be reviewed for the final paper.

## Exploratory interpretation

Runners tended to slow down less from the first to the last retained crossing,
but the cage-aware comparison is not conclusive (D14 overall group test:
p = 0.037 unadjusted, 0.106 Holm-adjusted across days). Selecting only the last
crossing after seeing this pattern would be a post hoc analysis; it could be
described as exploratory, without presenting it as a planned primary test.

The observed D14 mean locomoting speed is higher in runners than sedentary
mice. The exploratory D14 cage-aware run–sedentary comparison gave p = 0.024
unadjusted and 0.071 Holm-adjusted across the three D14 group pairs. The overall
three-group test of within-mouse D14-minus-D0 changes gave p = 0.268
unadjusted. These test different questions and do not establish that the
increase over two weeks differs between groups. Corrections across the selected
behavioral measures are not included in these figures.

## Approximate spatial calibration

On 2026-11-08, the tape marks in the 1280 × 356 video
`/Users/yoe/Documents/DATA/TARA/BB-mp4/D140043 26-03-05 14-07-16_gray.mp4`
were measured at approximately x = 42 and 1243 pixels (zero-based image
coordinates). Their centers are approximately 1201 pixels apart. The user
reported that the tape marks are 70 cm apart; assuming this refers to their
centers, the working scale is **700/1201 = 0.58285 mm/pixel** (approximately
1.716 pixels/mm). Multiply pixel distances and pixels/second by this factor
to obtain mm and mm/second, respectively; divide mm/second by 10 for cm/second.
Speeds already expressed per second do not need another frame-rate conversion.

This is a one-video approximation. Confirm comparable camera geometry and
resolution before applying it to other recordings. The scale measures along
the beam's image plane; vertical centroid heights use the same approximate
scale and remain subject to perspective and bar-detection uncertainty. The position plots use horizontal position relative to the image's left edge,
rather than distance from a tape mark. Their x-axes decrease from left to right
to match the original uncentered posture figure; the entry side has not yet
been verified. The uncentered posture figure shows centroid height relative
to the detected bar.

The current `BBanalysisSingleFile.m` intends the vertical centroid reference
to be the detected **top** of the beam, not its center. With an unclipped,
symmetric crop and an integer crop radius, the displayed transformation puts
the detected top at +1 pixel rather than exactly zero. Crop clipping or
rounding can change this offset; the source version and crop conditions used
for the historical centroid results have not yet been verified. Therefore the
zero line on `posture-by-day-uncentered-mm` is an approximate reference and
should not be interpreted as a precisely established beam surface.
