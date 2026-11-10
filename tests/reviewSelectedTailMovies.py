"""Verify selected rendered movies/median values; publish a crop-only gallery."""
from pathlib import Path
import csv,json,hashlib,subprocess,html,sys,math
import numpy as np
ROOT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109')
FF='/opt/homebrew/bin/ffmpeg';PROBE='/opt/homebrew/bin/ffprobe'
partial='--partial' in sys.argv
selection=json.loads((ROOT/'selection_manifest.json').read_text())['trials']
def read(path):
    with path.open() as f:return list(csv.DictReader(f))
def verify(folder):
    p=ROOT/folder;v=json.loads((p/'numerical_validation.json').read_text())
    cached=p/'review_validation.json'
    if cached.exists():return json.loads(cached.read_text())
    n=v['frames'];movie=next(p.glob('*.tail_metrics_debug.mp4'))
    m=json.loads(subprocess.check_output([PROBE,'-v','error','-count_frames','-show_streams','-of','json',str(movie)]))
    s=m['streams'][0];assert int(s['nb_read_frames'])==n and s['width']==2*v['width'] and s['height']==2*v['height']
    mapping=read(p/'frame_mapping.csv');heights=read(p/'render_inputs/motion_height.csv');tracking=read(p/'tracking_review.csv')
    meta=json.loads((p/'render_inputs/metadata.json').read_text());assert meta['scaleBarMM']==20
    q=np.loadtxt(p/'render_inputs/rows.csv',delimiter=',');a=np.loadtxt(p/'render_inputs/above.csv',delimiter=',');b=np.loadtxt(p/'render_inputs/below.csv',delimiter=',')
    invalid=np.array([r['InvalidFramePair']=='1' for r in mapping]);total=q.sum(axis=1)
    valid=~invalid & np.isfinite(q).all(axis=1)&np.isfinite(a).all(axis=1)&np.isfinite(b).all(axis=1)&(q>=0).all(axis=1)&(a>=0).all(axis=1)&(b>=0).all(axis=1)&(total>0)
    raw=np.full(n,np.nan)
    for k in np.flatnonzero(valid):
        row=int(np.searchsorted(np.cumsum(q[k]),total[k]/2,side='left'));raw[k]=(meta['barTop']-1-row)*meta['mmPerPixel']
    sm=np.full(n,np.nan)
    for k in np.flatnonzero(valid):
        lo=k;hi=k
        while lo>max(0,k-2) and valid[lo-1]:lo-=1
        while hi<min(n-1,k+2) and valid[hi+1]:hi+=1
        sm[k]=raw[lo:hi+1].mean()
    assert np.array_equal(valid,np.array([r['InvalidOrUnusable']=='0' for r in heights]))
    assert np.allclose(raw,[float(r['WeightedMedianMM']) for r in heights],atol=1e-10,rtol=0,equal_nan=True)
    assert np.allclose(sm,[float(r['WeightedMedianSmoothed5MM']) for r in heights],atol=1e-10,rtol=0,equal_nan=True)
    assert [r['OriginalFrame'] for r in mapping]==[r['OriginalFrame'] for r in heights]==[r['OriginalFrame'] for r in tracking]
    assert json.loads((p/'video_validation.json').read_text())['losslessExactFrames']==n
    assert v['rowProfilesMatch'] and v['belowMatches']
    trace=json.loads((p/'decoded_contribution_trace_validation.json').read_text());assert trace['aboveNormalizedMatch'] and trace['belowNormalizedMatch']
    blocks=[];start=0
    for i in range(1,n+1):
        if i==n or valid[i]!=valid[start]:
            blocks.append(dict(valid=bool(valid[start]),firstOriginalFrame=int(mapping[start]['OriginalFrame']),lastOriginalFrame=int(mapping[i-1]['OriginalFrame']),frames=i-start));start=i
    x=np.array([float(r['CameraFieldEntryRightFraction']) for r in tracking]);candidates=np.flatnonzero(valid&np.isfinite(x))
    k=int(candidates[np.argmin(np.abs(x[candidates]-.5))])
    subprocess.run([FF,'-v','error','-i',str(movie),'-vf',f'select=eq(n\\,{k})','-frames:v','1',str(p/'review_preview.png')],check=True)
    # Verify a complete decode, not just container metadata.
    decoded=subprocess.run([FF,'-v','error','-i',str(movie),'-f','null','-'],capture_output=True,text=True)
    assert decoded.returncode==0 and not decoded.stderr,decoded.stderr
    result=dict(frames=n,validFrames=int(valid.sum()),validPercent=float(100*valid.mean()),firstOriginalFrame=int(mapping[0]['OriginalFrame']),lastOriginalFrame=int(mapping[-1]['OriginalFrame']),
        missingXFrames=[int(r['OriginalFrame']) for r in tracking if r['MissingOriginalX']=='1'],tailBadFrames=sum(r['TailBadFrame']=='1' for r in mapping),
        validBlocks=blocks,previewOriginalFrame=int(mapping[k]['OriginalFrame']),movie=movie.name,movieSHA256=hashlib.sha256(movie.read_bytes()).hexdigest(),
        belowMaxAbsoluteError=v['belowMaxAbsoluteError'],medianAndSmoothingVerified=True,fullDecodeVerified=True,losslessHashFrames=n,width=v['width'],height=v['height'],
        medianScaleMMPerPixel=meta['mmPerPixel'],scaleBarMM=meta['scaleBarMM'])
    cached.write_text(json.dumps(result,indent=2));return result
status={}
for name in ['batch_status.csv','retry_batch_status.csv']:
    if (ROOT/name).exists():
        for r in read(ROOT/name):status[r['File']]=r
results=[];parts=['''<!doctype html><meta charset="utf-8"><title>Selected tail-metrics movies</title>
<style>body{font:17px system-ui;max-width:1150px;margin:30px auto;padding:20px}video{max-height:650px;max-width:100%}img{max-height:350px}table{border-collapse:collapse}td,th{padding:8px;text-align:left;border-bottom:1px solid #ccc}section{margin:50px 0}</style>
<h1>Selected tail-metrics movies</h1><p>Full-profile weighted median, five-frame smoothing, colored legend and 20 mm scale bar. No 5 mm near-bar blanking. Videos show only the moving post-mouse crop.</p>
<p>Approximate inherited calibration: 700/1201 mm per pixel. Playback is 30 fps; original-frame timing and flags are in each mapping CSV. Red cross = invalid/unusable motion pair, not a zero-height measurement.</p>
<p><a href="REPORT.md">Report and limitations</a> · <a href="selected_validation.csv">Per-crossing validation table</a></p>''']
for t in selection:
    r=status.get(t['file']);title=f"{t['group'].capitalize()} D{t['day']} trial {t['trial']}"
    if not r or r['Status']!='complete':
        parts.append(f'<section><h2>{title}</h2><p>Pending or failed; see batch logs. No validated movie offered.</p></section>');continue
    v=verify(r['Folder']);v.update(file=t['file'],group=t['group'],day=t['day'],trial=t['trial'],role=t['role'],folder=r['Folder']);results.append(v)
    prefix=html.escape(r['Folder']);name=html.escape(v['movie']);missing=v['missingXFrames']
    parts.append(f'''<section><h2>{title}{' — additional comparison' if t['role']!='requested' else ''}</h2><p>{html.escape(t['file'])}</p>
<p>{v['validFrames']}/{v['frames']} valid motion-height frames ({v['validPercent']:.1f}%). Original frames {v['firstOriginalFrame']}–{v['lastOriginalFrame']}. Missing original centroid-X frames: {missing or 'none'}.</p>
<video controls preload="metadata" src="{prefix}/{name}"></video>
<p><a href="{prefix}/{name}">Open movie</a> · <a href="{prefix}/frame_mapping.csv">Frame mapping and flags</a> · <a href="{prefix}/render_inputs/motion_height.csv">Motion-height values</a> · <a href="{prefix}/review_validation.json">Validation</a></p></section>''')
prior=ROOT/'run_D14_trial2_existing';movie=next(prior.glob('*.tail_metrics_debug.mp4'))
parts.append(f'<section><h2>Run D14 trial 2 — retained comparison</h2><p>Previously validated 678-frame demo; 559 valid motion-height frames (82.4%). Retained alongside the newly selected trial 1, not replaced.</p><video controls preload="metadata" src="run_D14_trial2_existing/{movie.name}"></video></section>')
(ROOT/'index.html').write_text('\n'.join(parts))
(ROOT/'review_validation.json').write_text(json.dumps(results,indent=2))
fields=['file','group','day','trial','role','folder','frames','validFrames','validPercent','tailBadFrames','missingXFrames','belowMaxAbsoluteError','losslessHashFrames','medianAndSmoothingVerified','fullDecodeVerified']
with (ROOT/'selected_validation.csv').open('w',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore',lineterminator='\n');writer.writeheader();writer.writerows(results)
print('Verified movies:',len(results),'of',len(selection),flush=True)
if not partial:assert len(results)==len(selection),'Incomplete selected batch: inspect failures rather than publish completion.'
