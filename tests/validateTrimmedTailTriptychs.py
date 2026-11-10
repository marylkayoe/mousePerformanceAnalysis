"""Validate start-trimmed, final-frame-held presentations and export trimmed singles."""
from pathlib import Path
import csv,json,hashlib,subprocess,shutil
import numpy as np
from PIL import Image
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_triptychs_tracking_start_20261109')
SRC=OUT.parent/'balance_beam_selected_tail_movies_20261109'
FF='/opt/homebrew/bin/ffmpeg';PROBE='/opt/homebrew/bin/ffprobe'
reports=json.loads((OUT/'presentation_manifest.json').read_text());checks=[]
for r in reports:
 w,h,n=r['width'],r['height'],r['frames'];d=subprocess.Popen([FF,'-v','error','-i',str(OUT/r['movie']),'-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
 last={};held=0;maxerror=0
 mapping=list(csv.DictReader((OUT/f"{r['group']}_frame_mapping.csv").open()))
 for k in range(n):
  raw=d.stdout.read(w*h*3);assert len(raw)==w*h*3
  img=np.frombuffer(raw,np.uint8).reshape(h,w,3)
  for j,p in enumerate(r['panels']):
   x=j*(r['panelWidth']+r['gutter']);panel=img[r['headingHeight']+8:h-8,x+8:x+r['panelWidth']-8]
   if k==0:assert mapping[k][f"D{p['day']}InvalidOrUnusable"]=='False'
   if k==p['frames']-1:last[j]=panel.copy()
   if k>=p['frames']:
    error=float(np.abs(panel.astype(float)-last[j]).mean());assert error<2,(k,j,error)
    maxerror=max(error,maxerror);held+=1
  if k in r['checkFrameIndicesZeroBased']:
   reference=np.array(Image.open(OUT/f"{r['group']}_reference_frame{k+1}.png"))
   assert np.abs(img.astype(float)-reference).mean()<5
   Image.fromarray(img).save(OUT/f"{r['group']}_decoded_frame{k+1}.png")
 assert not d.stdout.read(1);assert d.wait()==0
 info=json.loads(subprocess.check_output([PROBE,'-v','error','-show_streams','-of','json',str(OUT/r['movie'])]))['streams'][0]
 assert info['avg_frame_rate']=='30/1' and int(info['nb_frames'])==n
 checks.append(dict(group=r['group'],frames=n,heldPanelFrames=held,maxHeldMeanPixelError=maxerror,passed=True))
 print(checks[-1],flush=True)
# Individually clipped debug movies retain their original annotations, including legend.
individual=OUT/'individual_tracking_start';individual.mkdir()
singles=[]
for r in json.loads((SRC/'review_validation.json').read_text()):
 folder=SRC/r['folder'];rows=list(csv.DictReader((folder/'render_inputs/motion_height.csv').open()))
 start=next(i for i,v in enumerate(rows) if v['InvalidOrUnusable']=='0')
 source=folder/r['movie'];assert hashlib.sha256(source.read_bytes()).hexdigest()==r['movieSHA256']
 dest=individual/(r['file']+'.tracking_start.mp4')
 subprocess.run([FF,'-v','error','-i',str(source),'-vf',f'trim=start_frame={start},setpts=PTS-STARTPTS','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-threads','4',str(dest)],check=True)
 info=json.loads(subprocess.check_output([PROBE,'-v','error','-count_frames','-show_streams','-of','json',str(dest)]))['streams'][0]
 assert int(info['nb_read_frames'])==len(rows)-start and info['avg_frame_rate']=='30/1'
 singles.append(dict(file=dest.name,trimmedLeadingFrames=start,firstOriginalFrame=rows[start]['OriginalFrame'],frames=len(rows)-start,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()))
(OUT/'validation.json').write_text(json.dumps(dict(presentations=checks,individualMovies=singles),indent=2))
(OUT/'README.txt').write_text('Tracking-start revision: each crossing starts at the first InvalidOrUnusable=0 frame (no X). Later invalid frames remain. No other frames removed; playback remains 30 fps. Shorter presentation panels hold their final frame until the longest ends. D0 alone has the scale bar. Existing full-profile median, five-frame smoothing, profiles, calibration and beam alignment unchanged; no 5 mm blanking. Presentation CSVs retain original frame/time mappings and explicit HeldFinalFrame flags. Individual trimmed movies retain the original individual annotations. Originals preserved. Source and processing details: presentation_manifest.json, validation.json and included scripts.\n')
for name in ['createTailTriptychs.py','validateTrimmedTailTriptychs.py']:shutil.copy2(Path(__file__).parent/name,OUT/name)
