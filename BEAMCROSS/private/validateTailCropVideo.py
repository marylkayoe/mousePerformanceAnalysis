"""Standard-library verification of every decoded lossless crop frame."""
import csv, hashlib, json, subprocess, sys
from pathlib import Path
p=Path(sys.argv[1]);v=json.loads((p/'numerical_validation.json').read_text())
with (p/'frame_mapping.csv').open() as f:rows=list(csv.DictReader(f))
w,h,n=v['width'],v['height'],v['frames'];assert len(rows)==n
cmd=['ffmpeg','-v','error','-i',str(p/'post_mouse_crop_lossless.mkv'),'-f','rawvideo','-pix_fmt','gray','-']
d=subprocess.Popen(cmd,stdout=subprocess.PIPE)
try:
    for k,r in enumerate(rows):
        data=d.stdout.read(w*h);assert len(data)==w*h, f'Early end at frame {k+1}'
        assert hashlib.sha256(data).hexdigest()==r['LosslessGrayFrameSHA256'], f'Pixel mismatch at frame {k+1}'
        assert int(r['ExportFrame'])==k+1
    assert not d.stdout.read(1),'Unexpected extra frames'
    assert d.wait()==0
except BaseException:
    d.kill();d.wait();raise
metadata={}
for name in ['post_mouse_crop_lossless.mkv','post_mouse_crop_clean.mp4']:
    m=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames','-show_streams','-of','json',str(p/name)]))
    s=m['streams'][0]
    ew,eh=(w,h) if name.endswith('.mkv') else (w+w%2,h+h%2)
    assert int(s['nb_read_frames'])==n and s['width']==ew and s['height']==eh
    metadata[name]=s
(p/'video_validation.json').write_text(json.dumps({'losslessExactFrames':n,'metadata':metadata},indent=2))
print(f'Validated all {n} lossless decoded frame hashes; both movie dimensions and counts match.')
