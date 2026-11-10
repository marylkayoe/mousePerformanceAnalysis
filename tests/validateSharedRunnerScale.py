"""Validate shared-scale presentations against original timing, geometry, and full-trial inputs."""
from pathlib import Path
import csv,json,hashlib,subprocess,shutil,sys
import numpy as np
from PIL import Image
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_runner_shared_scale_20261109')
if len(sys.argv)>1: OUT=Path(sys.argv[1])
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

previous=OUT.parent/'balance_beam_tail_triptychs_tracking_start_20261109'
scale_checks=[]
for new in reports:
 old=next(r for r in json.loads((previous/'presentation_manifest.json').read_text()) if r['group']==new['group'])
 assert (OUT/f"{new['group']}_frame_mapping.csv").read_bytes()==(previous/f"{new['group']}_frame_mapping.csv").read_bytes()
 for key in ['frames','fps','width','height','panelWidth','panelImageHeight','headingHeight','gutter','beamTopOutputRowZeroBased','panels']:
  assert old[key]==new[key],key
 maxima=[]
 for panel in new['panels']:
  work=SRC/panel['sourceFolder']/'render_inputs'
  rows=list(csv.DictReader((work/'motion_height.csv').open()))
  valid=np.array([r['InvalidOrUnusable']=='0' for r in rows])
  a=np.loadtxt(work/'above.csv',delimiter=',');b=np.loadtxt(work/'below.csv',delimiter=',')
  maxima.append(float(max(a[valid].max(),b[valid].max())))
 assert new['originalTrialGreenRedMaxima']==maxima
 assert new['greenRedDisplayMaxima']==[max(maxima)]*3
 assert hashlib.sha256((previous/old['movie']).read_bytes()).hexdigest()==old['movieSHA256']
 # At pre-encoding reference frames, only green/red stroke pixels may differ.
 for k in new['checkFrameIndicesZeroBased']:
  name=f"{new['group']}_reference_frame{k+1}.png"
  before=np.array(Image.open(previous/name));after=np.array(Image.open(OUT/name))
  changed=np.any(before!=after,axis=2)
  permitted=np.zeros(changed.shape,dtype=bool)
  for color in [(0,155,70),(210,40,45)]:
   permitted|=np.all(before==color,axis=2)|np.all(after==color,axis=2)
  assert not np.any(changed & ~permitted),(name,'Non-green/red content changed')
 scale_checks.append(dict(mouseID=new['mouseID'],fullTrialMaxima=maxima,sharedMaximum=max(maxima),referenceChangesRestrictedToGreenRed=True))
(OUT/'validation.json').write_text(json.dumps(dict(presentations=checks,originalPerTrialMovieUnchanged=True,frameMappingExactlyUnchanged=True,panelAlignmentExactlyUnchanged=True,scaleChecks=scale_checks),indent=2))
shutil.copy2(__file__,OUT/Path(__file__).name)
print('Shared-scale validation complete',flush=True)
