"""Render a draft tracking illustration from validated run-example exports.
Requires /private/tmp/tail-demo-background.png and /private/tmp/run-movie-row-profiles.csv,
prepared by running prepare_run_tracking_demo.m.
"""
import csv,math,subprocess
from pathlib import Path
p=Path(__file__).resolve().parent;data=p.parent.parent/'results/running_column_export_L40_halfdepth_20261109'
def matrix(name):
 with (data/name).open(newline='') as f:return [[float(v) for v in row] for row in csv.reader(f)]
def rows(q):
 with q.open(newline='') as f:return list(csv.DictReader(f))
above=matrix('above_contributions_frame_by_column.csv'); below=matrix('new_below_contributions_frame_by_column.csv'); mapping=rows(data/'frame_mapping.csv')
with open('/private/tmp/run-movie-row-profiles.csv',newline='') as f:q=[[float(v) for v in row] for row in csv.reader(f)]
allheights=rows(p/'example-motion-height-time-frames.csv'); heights=[r for r in allheights if r['Group']=='run']
assert all(len(x)==678 for x in (above,below,mapping,q,heights))
assert all(int(m['OriginalFrame'])==int(h['OriginalFrame'])==685+i for i,(m,h) in enumerate(zip(mapping,heights)))
for a,b,m in zip(above,below,mapping):
 assert len(a)==len(b)==226
 x=sum(b);ref=float(m['NewBelowRawReference']);assert abs(x-ref)<=1e-6+1e-6*abs(ref)
H,W=820,1100;ox,oy=80,50;scale=2;bar=209;factor=700/1201
valid=[i for i,m in enumerate(mapping) if m['InvalidFramePair']=='0']
for i in valid:
 weights=q[i]; total=sum(weights); ref=float(heights[i]['MotionHeightMM']); estimate=sum(((bar-1-r)*factor)*v for r,v in enumerate(weights))/total
 assert math.isfinite(ref) and abs(estimate-ref)<.001,(i,estimate,ref)
colmax=max(max(max(above[i]),max(below[i])) for i in valid)
rowmax=max(max(x for x in q[i] if math.isfinite(x)) for i in valid)
print('Shared horizontal profile scale',colmax,'row profile scale',rowmax,flush=True)
bg=subprocess.check_output(['ffmpeg','-loglevel','error','-i','/private/tmp/tail-demo-background.png','-vf',f'scale={W}:{H}','-frames:v','1','-f','rawvideo','-pix_fmt','rgb24','-'])
assert len(bg)==H*W*3
source=data/'post_mouse_crop_lossless.mkv'; out=p/'TMCS2_S18-D14-trial2-tail-tracking-demo-corrected.mp4'
decoder=subprocess.Popen(['ffmpeg','-loglevel','error','-i',str(source),'-vf','scale=452:712:flags=neighbor','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
encoder=subprocess.Popen(['ffmpeg','-loglevel','error','-y','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate','30','-i','-','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p',str(out)],stdin=subprocess.PIPE)
def pixel(buf,x,y,c):
 if 0<=x<W and 0<=y<H:
  k=(y*W+x)*3;buf[k:k+3]=c
def line(buf,x0,y0,x1,y1,c,thick=1):
 x0,y0,x1,y1=map(round,(x0,y0,x1,y1));dx=abs(x1-x0);sx=1 if x0<x1 else -1;dy=-abs(y1-y0);sy=1 if y0<y1 else -1;err=dx+dy
 while True:
  for i in range(-thick+1,thick):
   for j in range(-thick+1,thick):pixel(buf,x0+i,y0+j,c)
  if x0==x1 and y0==y1:break
  e=2*err
  if e>=dy:err+=dy;x0+=sx
  if e<=dx:err+=dx;y0+=sy
font={'0':['111','101','101','101','111'],'1':['010','110','010','010','111'],'2':['111','001','111','100','111'],'3':['111','001','111','001','111'],'4':['101','101','111','001','001'],'5':['111','100','111','001','111'],'6':['111','100','111','101','111'],'7':['111','001','010','010','010'],'8':['111','101','111','101','111'],'9':['111','101','111','001','111'],'-':['000','000','111','000','000'],'.':['000','000','000','000','010']}
def number(buf,x,y,s,c,sz=3):
 for ch in s:
  for j,row in enumerate(font[ch]):
   for i,b in enumerate(row):
    if b=='1':
     for dy in range(sz):
      for dx in range(sz):pixel(buf,x+i*sz+dx,y+j*sz+dy,c)
  x+=4*sz
red=bytes((210,40,45));green=bytes((0,155,70));purple=bytes((160,35,190));black=bytes((0,0,0));invalidc=bytes((200,45,40))
for k,(m,h) in enumerate(zip(mapping,heights)):
 needed=452*712*3;parts=[];received=0
 while received<needed:
  chunk=decoder.stdout.read(needed-received)
  if not chunk:raise RuntimeError(f'crop ended at frame {k}')
  parts.append(chunk);received+=len(chunk)
 crop=b''.join(parts); frame=bytearray(bg)
 for y in range(712):
  dst=((oy+y)*W+ox)*3;src=y*452*3;frame[dst:dst+452*3]=crop[src:src+452*3]
 number(frame,870,100,str(int(m['OriginalFrame'])),black,3)
 if m['InvalidFramePair']=='0':
  def curve(vals,colour,direction):
   base=oy+scale*(bar-1);last=None
   for j,value in enumerate(vals):
    xx=ox+2*j; yy=base+direction*(value/colmax)*150
    if last is not None:line(frame,last[0],last[1],xx,yy,colour,2)
    last=(xx,yy)
  curve(above[k],green,-1);curve(below[k],red,1)
  last=None
  for r,value in enumerate(q[k]):
   if not math.isfinite(value):last=None;continue
   xy=(620+180*value/rowmax,oy+2*r)
   if last is not None:line(frame,*last,*xy,purple,2)
   last=xy
  height=float(h['MotionHeightMM'])
  if math.isfinite(height):
   yy=oy+2*((bar-1)-height/factor);line(frame,850,yy,880,yy,black,2)
   number(frame,870,55,f'{height:.1f}',black,3)
 else:
  # A red cross communicates that these retained video frames have no valid profile.
  line(frame,870,55,885,70,invalidc,2);line(frame,885,55,870,70,invalidc,2)
 encoder.stdin.write(frame)
decoder.stdout.close();assert decoder.wait()==0
encoder.stdin.close();assert encoder.wait()==0
print('Saved',out,'frames',len(mapping),flush=True)
