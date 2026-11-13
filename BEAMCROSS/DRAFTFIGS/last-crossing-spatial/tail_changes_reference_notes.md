# Last-retained-crossing tail profiles, D14 minus D0

Reproduce: MATLAB R2024b `addpath('tests'); plotLastTailChangesReference`. Uses existing group_profiles.csv and verifies means, SEM and finite sample counts against mouse_profiles.csv. Original selected filenames/trial numbers remain in selected_crossings.csv (42 mice, 15 cages, 84 mouse/day crossings). No measurements or inference rerun.

Score is corrected whole-range NewWholeNormalized (a.u.). Height is probability-weighted full-profile median motion location relative to beam top (mm), with existing five-frame smoothing within valid runs. These are image-motion measurements, not anatomical tail control/position. Values retain source masking and spatial definitions; see README.md and source export documentation.

Equal-mouse mean paired D14−D0 curves; shading is mouse SEM, not cage-adjusted inference. Require at least6 SED,6 WALK,9 RUN per bin. Each group has61/70 displayed bins in each metric; unsupported entry bins are left blank, not interpolated. NaN SEM with fewer than two contributors preserved. All saved values verified to1e-9.

Same reference grey #232323, green #00b226, blue #002bff; bands opacity0.16. Editable SVG text. Vertical bars0.5a.u. and10mm; horizontal bar10cm. PNG previews rendered using macOS Quick Look and visually checked. Existing speed figures and Illustrator master unchanged.
