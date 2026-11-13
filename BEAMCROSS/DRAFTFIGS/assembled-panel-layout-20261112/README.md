# Standardized supplied assembly

Presentation-only edit of the user-supplied SVG (preserved as supplied_assembly.svg). Reproduce with `python3 tests/standardizeBeamAssembly.py`; PNG is a Quick Look rendering cropped to the SVG canvas, not scientific content.

Eight scatter plotting regions are70×70 SVG units, with common row alignment. Mouse dots have radius1.3; cage diamonds have width3.2/height4.0. Original marker fills/colours retained. Arial: headings6, tick/group labels5, units/statistics4.5. P-value strings unchanged. Bottom axis spines removed; first-to-last zero-reference lines preserved. No data recalculation or statistical analysis. Original336 mouse dots and120 cage diamonds retained, with affine coordinate mapping per panel. Text remains editable. Schematic artwork and spatial profile retained. Illustrator master untouched.

Outputs: beam_panels_aligned.svg and beam_panels_aligned.png. Original titles/metric terminology retained; this is a layout revision, not a scientific redefinition or statistical endorsement.

Colour import repair: all CSS class styles resolved into local inline styles and generic cls-* names removed to prevent destination-document class collisions. Original colour values retained, including mouse dots #a7a7a7/#99d1b2/#9cc1ec and dark group markers #232323/#008d3f/#0864cf. RGBA band fills encoded as hex plus fill-opacity for Illustrator compatibility. Geometry unchanged by this repair.
