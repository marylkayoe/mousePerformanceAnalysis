"""Build the portable local review page and concise provenance report."""
from pathlib import Path
import json, html, csv, hashlib
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_examples_L40_20261109')
chosen={'sedentary':[1101,1170,1254], 'run':[854,1103,1216]}
page=['''<!doctype html><meta charset="utf-8"><title>D14 tail-motion examples</title>
<style>body{font:17px system-ui;max-width:1150px;margin:30px auto;padding:20px}video,img{max-width:100%}section{margin:50px 0}button,input{font:inherit;margin:5px}small{color:#444}</style>
<h1>D14 tail-motion examples — validated L40</h1>
<p>Crop, total spatial weights, regional spatial weights, and existing motion-profile overlay.
Yellow = weight 1; black = weight 0. Green/red = above/below column motion;
magenta = row motion without mouse-column weighting. See <a href="METHODS.md">methods and validation</a>.</p>
<p>Movies play at 30 fps for inspection. Frame labels refer to the original video.
Use the original-frame selector while paused; the label burned into the image is authoritative.
Suggested PNGs below use lossless analysis crops. These are illustrations, not representative group comparisons.</p>''']
rows=[];summaries=[]
for i,folder in enumerate(sorted(OUT.glob('*.mp4'))):
    if not folder.is_dir():continue
    d=json.loads((folder/'weights_and_mapping.json').read_text())
    validation=json.loads((folder/'render_validation.json').read_text())
    assert validation['frames']==d['nFrames'] and validation['sourceFrameMappingContiguous']
    name=html.escape(folder.name);first,last=d['originalFrames'][0],d['originalFrames'][-1]
    summaries.append(f"- {d['group']}: {folder.name}; {d['nFrames']} frames, original {first}–{last}; "
        f"{sum(d['badFrames'])} original tail-bad frames; encoded/VideoReader fps {d['videoReaderFrameRate']}, "
        f"analysis fps {d['analysisFrameRate']}; bar top {d['barTop']}, thickness {d['barWidth']} pixels.")
    page.append(f'''<section><h2>{d['group'].capitalize()}</h2><p>{name}</p>
<video id="v{i}" controls preload="metadata" src="{name}/tail_debug_weights.mp4"></video>
<div>Original frame <input id="f{i}" type="number" min="{first}" max="{last}" value="{first}">
<button onclick="seek({i},{first},{last})">Go</button>
<button onclick="step({i},-1,{first},{last})">Previous</button><button onclick="step({i},1,{first},{last})">Next</button></div>
<p><a href="{name}/frame_mapping.csv">Frame mapping and flags (CSV)</a> ·
<a href="{name}/weights_and_mapping.mat">Exact weights and traces (MAT)</a> ·
<a href="{name}/post_mouse_crop.mp4">Crop-only movie</a></p>''')
    for original in chosen[d['group']]:
        k=d['originalFrames'].index(original)
        assert k>0 and not d['badFrames'][k] and not d['badFrames'][k-1]
        rows.append({'file':folder.name,'group':d['group'],'original_frame':original,'previous_original_frame':original-1,
                     'debug_frame':k+1,'encoded_time_seconds':d['encodedTimes'][k],
                     'tail_bad_frame':False,'previous_tail_bad_frame':False,'tail_above':d['tailAbove'][k]})
        page.append(f'''<h3>Original frame {original} / debug frame {k+1}</h3>
<a href="{name}/debug_f{original}.png"><img src="{name}/debug_f{original}.png"></a>
<details><summary>Previous/current crop and motion difference</summary><img src="{name}/motion_pair_f{original}.png"></details>''')
    page.append('</section>')
page.append('''<script>
function seek(i,first,last){let v=document.getElementById('v'+i),f=document.getElementById('f'+i);let n=Math.max(first,Math.min(last,Number(f.value)));f.value=n;v.pause();v.currentTime=(n-first+0.1)/30;}
function step(i,delta,first,last){let f=document.getElementById('f'+i);f.value=Number(f.value)+delta;seek(i,first,last);}
</script>''')
(OUT/'index.html').write_text('\n'.join(page))
with (OUT/'selected_frames.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
methods='''# D14 tail debug examples: methods and validation

Created 2026-11-09. These two user-selected trials are useful illustrations of
the measurement. They do not establish a sedentary/run group difference.

## Source and analysis

Source collection: `/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved`.
Original videos were read in place. Two checksum-verified copies are in the
repository's `BEAMCROSS/example-videos/`; their SHA-256 manifest is copied here.
Canonical validated result/code root:
`/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106`.
Frozen source commit: `f7d85f52b946a295c035f1ba32a3e1468151b1fd`.
Repository HEAD before this addition: `f9fcf73` (working tree initially clean).
MATLAB R2024b, LOCOTHRESHOLD=40, SLIPTHRESHOLD=2.5,
MOUSESIZETHRESHOLD=2, EXCLUDE_STOPPING_FRAMES=false; other settings are retained
in each MAT/JSON `parameters` field. No original analysis function was edited.
An instrumented copy of the frozen capture function exports T after the original
tail calculation and returns. `provenance.json` records paths and SHA-256 hashes.

Both trials passed exact `isequaln` comparisons against the validated saved
centroids, forward speeds, under-bar movement, total/above/below tail traces,
original frame mapping, and original tail bad-frame mask. This verifies the
requested numerical reproduction; it is not independent biological validation.
The two rendered movies have exactly the expected frame counts and contiguous
original-frame mappings; no trace was trimmed or padded.

## Weight and debug definitions

For transition k-1 → k, the absolute difference of the moving post-mouse crop
is multiplied by the destination-frame column weights
`croppedNoMouseProbValues(:,k).^2`. The original 0.85 probability cutoff has
already been applied in these saved probabilities. MAT arrays are stored as
frame-by-column; original crop column coordinates are retained in `columns`.
Rows retain original video vertical coordinates and the recorded bar position.

Total-tail row weight is `(linspace(0,1,height)+eps).^3`, normalized to max 1.
Above-bar rows 1:barTop use the same cubic ramp over that region. Below-bar
rows barTop+barWidth:height use `min(2*linspace(0,1),1)+eps`, cubed and normalized.
The regional panel combines these disjoint regional weights; the beam gap is
zero. Each displayed spatial map is row weight times squared column weight.
Total and regional weights are different measurements, shown separately.

The green/red profiles duplicate the formulas in
`visualization/displayTailMotionWeightDebug.m`: regional weighted differences
summed across rows, displayed by column with a fixed shared scale across each
movie. The magenta profile sums differences across columns and applies the
existing bar-relative gradient (0→1 above, 1→2 below), WITHOUT the mouse-column
weights. It is a debug profile, not the scalar `verticalMotionTrace` or the
separately recovered weighted vertical-position index. Profiles are before the
tail trace's smoothing (window 5) and median/MAD normalization. The saved scalar
tail traces retain the original computation, including nonfinite values in MAT
and CSV (JSON encodes nonfinite numeric values as null).

Rendering is an additive headless version of the existing debug visualization,
with explicit spatial-weight panels, original-frame labels and masks. It does
not invoke the interactive GUI recorder. The first debug profile is zero as in
the existing display, but its preceding difference is unavailable and flagged.
The original bad-frame mask is unchanged. A separate predecessor flag makes
invalid motion pairs visible. Selected frames have both flags false; that alone
does not prove the difference is exclusively tail motion.

## Timing and visual review

All movies play at 30 fps solely for inspection. `frame_mapping.csv` maps every
debug frame to its 1-based original-video frame and encoded timestamp. Original
VideoReader and analysis frame rates are recorded separately; the frozen run's
analysis-rate rounding is preserved. No new rate is substituted for computation.
The MP4 views are lossy visualization files; selected PNG crops are lossless
exports from the analysis arrays. Weight data in MAT are exact exported arrays.
No full video matrices were saved.

Source contact sheets and actual post-mouse crops, weight panels and adjacent
frame differences were inspected. Both trials show useful tail silhouettes.
The body remains at the crop's left edge, with many body-side columns suppressed
by the probability weights. Some other movement or crop translation can still
contribute; the profiles must not be interpreted as isolated tail kinematics.
The difference PNG uses a display gain of 6 and includes movement of the crop.
Sedentary frame 1170 and run frame 1103 show clear tail arches; the latter also
shows a strong tail-shaped difference. Additional selected frames show changes
in tail height/shape and proximity to the beam. Selection is illustrative and
exploratory. Frame 1254 is a useful near/below-bar alternative, not a clean
above-bar-only example. See `selected_frames.csv` and `index.html`.

## Per-trial validation

'''+ '\n'.join(summaries)+'''

## Reproduction and storage

Repository helpers in `tests/`: prepareTailExamples.py, runTailExamples.m,
exportTailExampleData.m, renderTailExamples.py, documentTailExamples.py.
Run preparation, MATLAB capture, Python rendering, then this documentation
builder. Python needs NumPy/Pillow; rendering uses ffmpeg/ffprobe. Paths are
explicit. Choose a new destination consistently before a fresh rerun to retain
this set. Small checkpoints/logs record extraction; no bulk scratch was used.
Results stay here on ShosaiData. Only the two requested source copies, small
helpers and documentation belong in the repository; MP4 copies remain ignored.
'''
(OUT/'METHODS.md').write_text(methods)
manifest=Path('BEAMCROSS/example-videos/source_manifest.json')
(OUT/'source_manifest.json').write_bytes(manifest.read_bytes())
scripts=['prepareTailExamples.py','runTailExamples.m','exportTailExampleData.m','renderTailExamples.py','documentTailExamples.py']
for name in scripts:(OUT/'instrumentation'/name).write_bytes((Path('tests')/name).read_bytes())
(OUT/'artifact_checksums.json').write_text(json.dumps({str(p.relative_to(OUT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.rglob('*') if p.is_file() and p.name!='artifact_checksums.json'},indent=2))
print('Wrote review page, methods, selected frames and checksums')
