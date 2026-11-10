"""Write per-crossing findings and reproducibility notes after movie review."""
from pathlib import Path
import json,csv,hashlib,shutil
ROOT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109')
results=json.loads((ROOT/'review_validation.json').read_text())
assert len(results)==10,'Run the review to completion before writing the final report.'
observations=json.loads((ROOT/'visual_observations.json').read_text())
table=['| Group/day/trial | Valid motion-height frames | Missing centroid X | Validation / qualifications |','| --- | ---: | --- | --- |']
for r in results:
    problems=[]
    if r['group']=='sedentary' and r['day'] in [0,7]:problems.append('Initial odd-width viewing-encoder failure; resolved in new retry folder. Lossless crop unchanged in size.')
    if r['missingXFrames']:problems.append(f"Original missing X at {r['missingXFrames']}; invalid motion pairs preserved, no displayed median there.")
    if r['group']=='walk' and r['day']==0 and r['trial']==2:problems.append('Initial 604 frames invalid; one continuous valid segment at original 1568–2485. Useful after entry, with trial 3 added.')
    if r['role']=='additional_comparison':problems.append('Additional walk D0 comparison; fewer invalid entry frames.')
    if not problems:problems.append('No missing original centroid; invalid entry crop frames retained and flagged.')
    table.append(f"| {r['group']} D{r['day']} trial {r['trial']} | {r['validFrames']}/{r['frames']} ({r['validPercent']:.1f}%) | {r['missingXFrames'] or 'none'} | All checks passed. {' '.join(problems)} |")
maxerr=max(r['belowMaxAbsoluteError'] for r in results)
text='''# Selected tail-metrics debug movies

All nine requested crossings were regenerated and validated. Walk D0 trial 3
was additionally generated for comparison. The existing runner D14 trial 2
demo was copied with checksum verification and retained alongside requested
trial 1. Trial 1 was selected by the user as closer to that mouse's D14 daily
mean; this export does not independently redefine or retest that daily mean.
Open `index.html` for the cropped movies, mapping/flags and per-movie validation.

## Display and calculation

The movies show only the moving post-mouse crop, with the colored in-image
legend, 20 mm scale bar and full-profile probability-weighted median motion
height. The marker is the weighted median of the entire saved probability-
weighted row profile, followed by a centered five-frame arithmetic mean within
contiguous valid segments. **No 5 mm near-bar exclusion is applied.** This is
where motion occurs, not an anatomical tail position or stationary-tail height.

Above-bar contributions retain the original cubic row weights. Below-bar
contributions use weight 1 immediately below the beam, rising linearly to 2
at half-depth and constant thereafter. The full-profile median uses probability
weights, not these separate vertical region weights. Colored profiles have
fixed display scales within each movie, not a common raw-amplitude scale across
all movies. The physical scale is the inherited approximate 700/1201 mm/pixel,
not a new per-trial calibration. Playback is 30 fps for inspection. Original
encoded timestamps and frame numbers are preserved in each `frame_mapping.csv`.

## Per-crossing results

'''+ '\n'.join(table)+f'''

The retained runner D14 trial 2 has 559/678 valid frames (82.4%), from the prior
validated on-demand export. Its original remains untouched; see its separate
reference manifest for source paths and checksums.

## Walk D0 interpretation

Trial 2 has no missing original centroid samples. Its 60.3% valid fraction is
primarily an entry-visibility/crop-boundary issue, not repeated missing tracking:
original frames **964–1567** are invalid, followed by **918 continuous valid
frames, 1568–2485** (about 5.74 s at the encoded 160 fps). The mouse spends time
at the right edge and much of its tail is outside the camera field initially.
Source checks were used only to explain this limitation; final movies remain
post-mouse crops. The valid central/later crop shows clear tail motion and is
informative, but cannot describe motion in the unavailable entry segment.

Trial 3 has **815/940 valid frames (86.7%)**, original valid frames **939–1753**,
and only 125 initial invalid frames. It is included as an additional inspection,
not a replacement that hides trial 2's behavior. Its larger valid percentage
reflects less time with an unusable entry crop, not proof of better tracking or
greater biological representativeness. Treat the examples as exploratory.

## Tracking and export problems

Walk D7 trial 1 has an original missing centroid X at **frame 1744**, near the
end of the selected traversal. The original tail cropping policy interpolates
that X only to reproduce its crop; the original missing-X mask and invalid
motion pairs **1744–1745** remain explicit. The movie shows a red cross and
suppresses the marker/profiles on those frames. No original tracking values
were overwritten or silently filled in the saved tracking table.

Sedentary D0 and D7 initially failed because their **219- and 229-pixel-wide**
crops cannot be encoded as yuv420p H.264 without even dimensions. Initial
failure logs and partial artifacts are retained in their original output
folders; successful retries are in `_retry_even_view` folders. Only the
optional viewing-copy MP4 receives a one-pixel right border. Exact lossless
crops, contribution matrices and final debug movies are not padded/resized
to change the analysis. Final debug rendering uses integer display scaling
of the lossless source crop. The other crossings passed without this initial
encoder failure. No unresolved reconstruction or numerical mismatch remains in
the final exports; the original tracking limitation above remains explicitly
flagged. Matching saved tracking does not independently establish biological
tracking accuracy throughout every movie.

The earlier sedentary striped MP4 was never used as an input. All crops were
regenerated from the source. At sedentary D14 original frame **1170**, the new
lossless crop is pixel-identical to the earlier clean analysis PNG; its newly
rendered debug frame is visibly free of stripes. See `original1170_crop_check.json`
and the paired stills in `sedentary_D14_trial2`.

## Validation

All new selected/candidate exports passed frozen-code reconstruction checks,
saved weighted-row-profile comparisons, original trace reconstruction and
above/corrected-below normalized-trace checks. Below column sums reproduce
`NewBelowRaw` within **1e-6 + 1e-6 × abs(reference)**; largest absolute error
across these exports is **{maxerr:.9g}**. Original masks, nonfinite values,
identifiers, parameters and mappings are retained. First-frame zeros remain
explicit legacy no-predecessor placeholders; invalid is not zero motion height.

Every lossless frame was decoded and hash-checked against the fresh MATLAB
crop; the renderer checked those hashes again. Rendered movie frame counts,
dimensions and complete decode were independently checked. NumPy independently
recomputed every raw/smoothed median and validity decision from the full row
profiles. Decoded crop previews were visually inspected for all new movies,
including the explicit missing-centroid frame and the previously problematic
sedentary frame. Detailed observations are in `visual_observations.json`.

## Storage and reproduction

Canonical output root: `{ROOT}`.
Source videos and prior scientific results remain unchanged. The source is
read in place using the validated MATLAB decoding convention; original masks
and crop probabilities are reconstructed without rerunning tracking. Full
source decoding is required for the frozen all-frame background mean when
reconstructing probabilities; full-field debug videos were not generated.

All outputs and rendering inputs remain in this external results directory;
no bulk scratch or video matrices were created elsewhere. `selection_manifest.json`
records the exact original filenames, groups, days, trials and selection roles.
`batch_status.csv` preserves initial outcomes; `retry_batch_status.csv` records
resolved encoder failures. `selected_validation.csv` is the final per-crossing
summary. `code/` retains the batch-start code; `code_final/` records the final
odd-dimension encoder fix and reporting scripts. The numerical pipeline and
weights were unchanged by that export fix. Outputs have not been added to Git.

Reproduction scripts in repository `tests/`: `runSelectedTailMovies.m`,
`retrySelectedTailMovies.m`, `reviewSelectedTailMovies.py`, and
`reportSelectedTailMovies.py`. Choose fresh output destinations consistently
before rerunning. The generalized entry point is
`BEAMCROSS/createTailMetricsDebugForTrial.m`. Requirements: MATLAB R2024b,
FFmpeg/ffprobe, Python (NumPy/Pillow for review), and macOS clang/Core Text for
the renderer's labels. `artifact_checksums.json` records final output hashes.
'''
(ROOT/'REPORT.md').write_text(text)
files=['BEAMCROSS/createTailMetricsDebugForTrial.m','BEAMCROSS/prepareTailMetricsTrial.m','BEAMCROSS/validateTailMetricsPreparation.m','BEAMCROSS/createTailMetricsDebugVideo.m','BEAMCROSS/private/tailCropGeometry.m','BEAMCROSS/private/validateTailCropVideo.py','BEAMCROSS/private/renderTailMetricsDebug.py','BEAMCROSS/private/tailDebugLabel.c','tests/runSelectedTailMovies.m','tests/retrySelectedTailMovies.m','tests/reviewSelectedTailMovies.py','tests/reportSelectedTailMovies.py']
for f in files:
    p=ROOT/'code_final'/f;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,p)
(ROOT/'final_code_checksums.json').write_text(json.dumps({f:hashlib.sha256(Path(f).read_bytes()).hexdigest() for f in files},indent=2))
(ROOT/'artifact_checksums.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in ROOT.rglob('*') if p.is_file() and p.name!='artifact_checksums.json'},indent=2))
print('Report complete; persistent bytes:',sum(p.stat().st_size for p in ROOT.rglob('*') if p.is_file()))
