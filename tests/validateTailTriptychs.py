"""Check timing, all end blanks, decoded references and preserve-source hashes."""
from pathlib import Path
import csv,json,hashlib,subprocess,shutil
import numpy as np
from PIL import Image
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_triptychs_20261109')
SRC=OUT.parent/'balance_beam_selected_tail_movies_20261109'
FF='/opt/homebrew/bin/ffmpeg';PROBE='/opt/homebrew/bin/ffprobe'
reports=json.loads((OUT/'presentation_manifest.json').read_text());validated=[]
for r in reports:
    path=OUT/r['movie'];n=r['frames'];w=r['width'];h=r['height']
    info=json.loads(subprocess.check_output([PROBE,'-v','error','-count_frames','-show_streams','-of','json',str(path)]))['streams'][0]
    assert int(info['nb_read_frames'])==n and info['width']==w and info['height']==h and info['avg_frame_rate']=='30/1'
    assert abs(float(info['duration'])-n/30)<.001
    with (OUT/f"{r['group']}_frame_mapping.csv").open() as f:mapping=list(csv.DictReader(f))
    assert len(mapping)==n
    d=subprocess.Popen([FF,'-v','error','-i',str(path),'-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
    blanks=0;maxblank=0;errors=[]
    for k in range(n):
        raw=d.stdout.read(w*h*3);assert len(raw)==w*h*3
        img=np.frombuffer(raw,np.uint8).reshape(h,w,3);row=mapping[k]
        assert int(row['PresentationFrame'])==k+1 and abs(float(row['PresentationTimeSeconds'])-k/30)<1e-12
        for j,p in enumerate(r['panels']):
            active=k<p['frames'];assert (row[f"D{p['day']}Active"]=='True')==active
            if not active:
                x=j*(r['panelWidth']+r['gutter']);blank=img[r['headingHeight']+8:h-8,x+8:x+r['panelWidth']-8]
                value=int(blank.max());maxblank=max(maxblank,value);assert value<=5,(r['group'],k,j,value)
                assert row[f"D{p['day']}OriginalFrame"]=='';blanks+=1
        if k in r['checkFrameIndicesZeroBased']:
            ref=np.array(Image.open(OUT/f"{r['group']}_reference_frame{k+1}.png"))
            error=float(np.abs(img.astype(float)-ref).mean());assert error<5
            errors.append({'frame':k+1,'meanAbsoluteRGBError':error})
            Image.fromarray(img).save(OUT/f"{r['group']}_decoded_frame{k+1}.png")
    assert not d.stdout.read(1);d.stdout.close();assert d.wait()==0
    assert blanks==sum(n-p['frames'] for p in r['panels'])
    validated.append({'movie':r['movie'],'frames':n,'fps':30,'durationSeconds':n/30,'blankPanelFramesChecked':blanks,'maximumBlankInteriorPixelValue':maxblank,'decodedReferenceErrors':errors,'passed':True})
    print(r['group'],'validated',n,'frames and',blanks,'ended-panel blanks',flush=True)
# Original individual videos, including the alternate walk crossing, remain intact.
originals=json.loads((SRC/'review_validation.json').read_text())
for r in originals:
    p=SRC/r['folder']/r['movie'];assert hashlib.sha256(p.read_bytes()).hexdigest()==r['movieSHA256']
(OUT/'validation.json').write_text(json.dumps({'presentations':validated,'allOriginalIndividualVideosUnchanged':True},indent=2))
shutil.copy2(__file__,OUT/Path(__file__).name)
text='''# D0 / D7 / D14 presentation movies

Three presentation MP4s use the nine requested crossings, one group/mouse per
movie, with D0, D7 and D14 from left to right. All crossings begin on presentation
frame 1. Every original debug frame is used once at the unchanged 30 fps playback;
there is no stretching, skipping, looping or frozen final frame. After a crossing
ends its image panel is black while its heading remains visible.

Each heading contains the full mouse ID, day and group. In-image colored-trace
legends are absent. Rather than masking over the old legend, each image was
rendered from its previously validated lossless post-mouse crop and saved traces.
Every source crop frame hash was rechecked. Original individual MP4s remain
unchanged, including the walk D0 trial 3 comparison.

Colored above/below/row profiles, black motion-height marker, five-frame smoothing
and invalid-frame crosses retain the previous renderer's calculations and scales.
There is no 5 mm blanking. The 20 mm scale bar appears **only in the D0 panel of
each presentation** and disappears with that panel when it ends. Calibration
remains the inherited approximate 700/1201 mm/pixel.

All three movies use identical 516-pixel-wide image panels, a 56-pixel heading,
and 16-pixel gutters. Original crop pixels retain the existing 2x integer display
scale. Crops are left-aligned at their saved crop-coordinate origin and translated
vertically so the detected beam TOP is at the same row across all nine panels.
The image-panel height is 726 pixels and total movie size is 1580 x 782.
Different crop widths are accommodated with black margins, not rescaling or
trimming. Beam thickness varies by one source pixel in some trials, so bottom
edges need not coincide when tops are aligned. No analysis data were changed.

The original per-movie profile amplitude scales are retained; these overlays
are not a common raw-amplitude scale between days. The median marker is a
motion-location index, not an anatomical stationary-tail position.

## Timing and validation

'''
for r in reports:
    text+=f"- {r['mouseID']} / {r['group']}: {r['frames']} frames, {r['durationSeconds']:.6f} s. Panel durations D0/D7/D14: "+', '.join(f"{p['durationSeconds']:.6f} s" for p in r['panels'])+'.\n'
text+='''
`presentation_manifest.json` records exact source filenames, offsets, dimensions
and blank-start frames. Each group has a presentation-to-original-frame/timestamp
mapping CSV, including invalid-state flags. `validation.json` records full
decoded-frame counts, unchanged fps/durations, all ended-panel interior blank
checks and sampled comparisons with pre-encoding reference images. Original
individual videos were checksum-verified unchanged. Decoded previews include
transition frames immediately before and after panels end.

Canonical outputs/reports stay in this folder on ShosaiData. Only the three final
MP4s are copied into Proton Drive's `D0_D7_D14_presentations` subfolder alongside
the prior individual videos. The alternate walk D0 trial 3 remains in the parent
Proton folder; it is not substituted into the requested walk presentation.
Cloud upload completion must be distinguished from a verified local synced-folder
copy. Reproduction scripts are copied here and stored in repository `tests/`.
'''
(OUT/'README.md').write_text(text)
print('Validation complete')
