# Last-retained-crossing speed change: reference-style figure

Reproduce with MATLAB R2024b: `addpath('tests'); plotLastSpeedChangeReference`. Template is the user's supplied SVG, preserved as `speed_change_reference_template.svg`. Preview rendered with macOS Quick Look.

Uses existing `group_profiles.csv`, speed/change rows; means and SEM checked against `mouse_profiles.csv` to <1e-9. 42 mice (SED12, WALK12, RUN18), 15 cages; original source filenames and selected trial numbers preserved in existing `selected_crossings.csv` (84 mouse/day rows). Last means highest original retained trial number independently on each day, not necessarily trial3.

Curves: equal-mouse mean of paired spatial D14−D0 differences; bands: SEM across mice, not cage-adjusted inferential uncertainty. All120 bins pass existing half-group support rule. Spatial speed includes stops, unlike scalar locomoting speed. No new smoothing, tracking, event detection or statistical tests.

Reference colours preserved: SED #232323, WALK #00b226, RUN #002bff; band opacity0.16 encoded with explicit fill-opacity for SVG compatibility. Editable text, line widths and vertical calibration retained (25mm/s=12.5 SVG units). Bottom margin extended to avoid clipping negative changes; horizontal calibration100mm=160/7 units on the700mm beam. Existing outputs and Illustrator master unchanged.
