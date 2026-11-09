"""Decode every output frame, verify lossless pixels, and document the export."""
from pathlib import Path
import csv,json,hashlib,subprocess,shutil
import numpy as np
from PIL import Image
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_running_column_export_L40_halfdepth_20261109')
ROOT=OUT.parent
NAME='TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4'
FF='/opt/homebrew/bin/ffmpeg'
rows=list(csv.DictReader((OUT/'frame_mapping.csv').open()))
v=json.loads((OUT/'numerical_validation.json').read_text());w,h,n=v['width'],v['height'],v['frames']
assert len(rows)==n
def decoder(name):return subprocess.Popen([FF,'-v','error','-i',str(OUT/name),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
loss=decoder('post_mouse_crop_lossless.mkv');view=decoder('post_mouse_crop_clean.mp4')
metrics=[]
for k,row in enumerate(rows):
    a=loss.stdout.read(w*h);b=view.stdout.read(w*h)
    assert len(a)==len(b)==w*h
    assert hashlib.sha256(a).hexdigest()==row['LosslessGrayFrameSHA256'],k
    assert int(row['ExportFrame'])==k+1 and int(row['OriginalFrame'])==685+k
    aa=np.frombuffer(a,np.uint8).reshape(h,w);bb=np.frombuffer(b,np.uint8).reshape(h,w)
    d=np.abs(aa.astype(float)-bb)
    metrics.append({'ExportFrame':k+1,'OriginalFrame':685+k,'LosslessExact':True,
                    'ViewingMP4MeanAbsoluteError':float(d.mean()),'ViewingMP4MaxAbsoluteError':float(d.max()),
                    'ViewingMP4PixelsErrorAbove50':int((d>50).sum())})
    if 685+k in [854,1103,1216]:Image.fromarray(bb).save(OUT/f'clean_mp4_decoded_f{685+k}.png')
for p in [loss,view]:
    assert not p.stdout.read(1);p.stdout.close();assert p.wait()==0
with (OUT/'video_validation_by_frame.csv').open('w') as f:
    writer=csv.DictWriter(f,fieldnames=list(metrics[0]));writer.writeheader();writer.writerows(metrics)
metadata={}
for name in ['post_mouse_crop_lossless.mkv','post_mouse_crop_clean.mp4']:
    m=json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe','-v','error','-count_frames','-show_streams','-of','json',str(OUT/name)]))
    s=m['streams'][0];assert int(s['nb_read_frames'])==n and s['width']==w and s['height']==h
    metadata[name]=s
# Independently check exported CSV contribution sums and mapping.
A=np.loadtxt(OUT/'above_contributions_frame_by_column.csv',delimiter=',')
B=np.loadtxt(OUT/'new_below_contributions_frame_by_column.csv',delimiter=',')
cols=np.loadtxt(OUT/'source_columns_frame_by_column.csv',delimiter=',')
weights=np.loadtxt(OUT/'destination_probability_squared_frame_by_column.csv',delimiter=',')
assert A.shape==B.shape==cols.shape==weights.shape==(n,w)
ref=np.array([float(r['NewBelowRawReference']) for r in rows]);err=np.abs(B.sum(axis=1)-ref)
assert np.all(err<=1e-6+1e-6*np.abs(ref))
assert np.allclose(A.sum(axis=1),[float(r['AboveColumnSum']) for r in rows],rtol=1e-12,atol=1e-10)
assert np.all(A[0]==0) and np.all(B[0]==0) and rows[0]['InvalidFramePair']=='1'
report={'losslessFramesExactlyMatchingMATLABCropHashes':n,'bothVideosDecodedFrames':n,
        'viewingMP4WorstFrameMeanAbsoluteError':max(m['ViewingMP4MeanAbsoluteError'] for m in metrics),
        'viewingMP4WorstPixelAbsoluteError':max(m['ViewingMP4MaxAbsoluteError'] for m in metrics),
        'viewingMP4PixelsErrorAbove50':sum(m['ViewingMP4PixelsErrorAbove50'] for m in metrics),
        'CSVBelowSumMaxAbsoluteError':float(err.max()),'CSVBelowSumAllWithinTolerance':True,'videoStreams':metadata}
(OUT/'video_and_csv_validation.json').write_text(json.dumps(report,indent=2)+'\n')
source=Path('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved')/NAME
inputs=[source,ROOT/'balance_beam_tail_examples_L40_20261109'/NAME/'weights_and_mapping.mat',
        ROOT/'balance_beam_events_traces_L40_20261106'/'trials'/(NAME+'.mat'),
        ROOT/'balance_beam_events_traces_L40_20261106'/'trials'/(NAME+'.profiles.mat'),
        ROOT/'balance_beam_tail_reweight_L40_halfdepth_20261109'/'trials'/(NAME+'.mat')]
provenance={'inputChecksums':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs},
            'gitHead':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
            'reproductionScripts':['tests/exportRunningTailColumns.m','tests/validateRunningTailColumns.py']}
(OUT/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
text=f'''# Running example: per-column tail motion and clean crop video

Source: `{NAME}`. Group: run. No tracking was repeated. The original source
and existing results were read only; this is a new, separate export.

## Data files and alignment

- `column_contributions.mat`: MATLAB structure E. `aboveContributions` and
  `newBelowContributions` are **{n} frames × {w} crop columns**. Rows correspond
  exactly to `frame_mapping.csv`; columns follow the saved crop's order.
- `above_contributions_frame_by_column.csv` and
  `new_below_contributions_frame_by_column.csv`: the same raw matrices, no
  headers. These are before temporal smoothing and median/MAD normalization.
- `source_columns_frame_by_column.csv`: original decoded-image column number
  for every crop column/frame (MATLAB 1-based coordinates).
- `destination_probability_squared_frame_by_column.csv`: the exact probability
  weights multiplied into the contributions at destination frame k. MAT also
  retains the unsquared probabilities.
- `frame_mapping.csv`: export frame, original frame, encoded timestamp, flags,
  above/below sums, reference NewBelowRaw, per-frame numerical errors and hashes.

Original frames **685–1362 inclusive**, {n} frames. Crop dimensions are
**{w} pixels wide × {h} pixels high**, retaining original video rows.
Original timing is stored without substitution: VideoReader fps
{v['videoReaderFrameRate']}, encoded rate {v['encodedFrameRate']}, analysis rate
{v['analysisFrameRate']}. Use `EncodedTimeSeconds`, not movie playback time, to
align with the source. Flags: {v['tailBadFrames']} original tail-bad frames and
{v['invalidPairs']} invalid pairs. The original tail mask, preceding tail mask,
stricter invalid-pair mask, and original missing-tracking-X mask are preserved.
Contributions at flagged frames are retained, not silently zeroed or removed.
The first row is zero only to reproduce the existing no-predecessor convention;
its invalid-pair flag is true. No length trimming or padding was performed.

## Exact contribution definition

For transition k-1 → k and crop column x:
`contribution(k,x) = sum_r(abs(crop_k(r,x)-crop_(k-1)(r,x))/255 * rowWeight(r)) * probability(x,k)^2`.
The saved `croppedNoMouseProbValues` already have the original 0.85 cutoff.
Coordinates and weights come from the validated L40/S2.5/M2 rerun capture.
The source is decoded sequentially with the same MATLAB VideoReader/rgb2gray
procedure; every reconstructed weighted row profile is checked against the
saved profiles. Crops move as in the original analysis, so differences can
include crop movement and residual non-tail motion.

Above rows are 1:barTop with the original normalized cubic row ramp
`(linspace(0,1)+eps)^3`. Below rows start at barTop+barWidth. Their new weight is
`1+min(2*d,1)`, where d is 0 at the first below-bar row and 1 at the last image
row. Thus weight starts at 1, reaches 2 at half-depth, then remains at 2.
The beam-gap rows are excluded from both regional measures. Exact row lists,
bar position/thickness and weights are stored in MAT. The full-height total
measure is not changed or recomputed in this export.

## Numerical validation

All above-bar contributions match the previous per-column export, with maximum
absolute difference **{v['aboveMaxError']:.9g}**. All corrected below-bar column
sums reproduce saved `NewBelowRaw`. Criterion for every frame is
`abs(export-reference) <= 1e-6 + 1e-6*abs(reference)`; maximum absolute difference
is **{v['belowMaxAbsoluteError']:.9g}**. The reference was computed from compressed
single-precision row profiles, whereas this export sums directly from decoded
crop pixels; small rounding differences are expected. All reconstructed weighted
row profiles pass that same absolute-plus-relative tolerance. CSV sums are
independently checked after serialization. See `numerical_validation.json`,
`video_and_csv_validation.json` and `frame_mapping.csv`.

## Clean videos

- `post_mouse_crop_lossless.mkv`: FFV1, 8-bit grayscale, exact {w}×{h} pixels.
  **All {n} decoded frames match SHA-256 hashes of the MATLAB analysis crops**.
  Use this file for lossless pixels (e.g. with FFmpeg or VLC).
- `post_mouse_crop_clean.mp4`: H.264 viewing copy, grayscale content encoded
  as yuv420p, same dimensions/frame count. No overlays, resizing or border
  padding. It is lossy and should not replace the measurement arrays.
  Worst-frame mean absolute error is
  {report['viewingMP4WorstFrameMeanAbsoluteError']:.6g}/255; maximum pixel error
  {report['viewingMP4WorstPixelAbsoluteError']:.0f}/255. Pixels with error >50:
  {report['viewingMP4PixelsErrorAbove50']} across all frames.

Both videos play at **30 fps for inspection**, not source speed. All frames,
including invalid ones, remain present and are identified in the mapping CSV.
Raw grayscale frames stream directly from MATLAB to FFmpeg; the problematic
MATLAB MPEG-4 writer and old crop movie are not used. There is no saved full
video matrix or bulk temporary file. Five existing lossless sample PNGs were
matched exactly; fresh sample PNGs are included for visual inspection.

## Provenance and reproduction

`provenance.json` identifies and hashes source inputs. MATLAB version:
{v['MATLAB']}. Scripts `exportRunningTailColumns.m` and
`validateRunningTailColumns.py` are copied here and live in repository `tests/`.
Choose a new output path before rerunning; MATLAB refuses an existing directory.
Python validation needs NumPy/Pillow and ffmpeg/ffprobe. `artifact_checksums.json`
records output checksums. Original videos/results remain unchanged.
'''
(OUT/'README.md').write_text(text)
shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'artifact_checksums.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.iterdir() if p.is_file() and p.name!='artifact_checksums.json'},indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='videoStreams'},indent=2))
print('Total bytes:',sum(p.stat().st_size for p in OUT.iterdir() if p.is_file()))
