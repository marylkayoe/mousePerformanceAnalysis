# Balance-beam draft figures

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
- `speed-absolute-horizontal-groups-entry-right-D0-D14.fig` / `.png`: absolute
  forward-speed profiles by position, including stops.

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
