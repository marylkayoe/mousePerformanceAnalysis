"""Render a draft tracking illustration from validated run-example exports.
Requires /private/tmp/tail-demo-overlay-background.png and /private/tmp/run-movie-row-profiles.csv,
prepared by running prepare_run_tracking_overlay.m.
"""
import csv,math,subprocess,tempfile
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
H,W=820,620;ox,oy=80,50;scale=2;bar=209;factor=700/1201
valid=[i for i,m in enumerate(mapping) if m['InvalidFramePair']=='0']
for i in valid:
 weights=q[i]; total=sum(weights); ref=float(heights[i]['MotionHeightMM']); estimate=sum(((bar-1-r)*factor)*v for r,v in enumerate(weights))/total
 assert math.isfinite(ref) and abs(estimate-ref)<.001,(i,estimate,ref)
vals=[float(x['MotionHeightMM']) if mapping[k]['InvalidFramePair']=='0' else float('nan') for k,x in enumerate(heights)]
smoothed=[float('nan')]*len(vals); i=0
while i<len(vals):
 if not math.isfinite(vals[i]):i+=1;continue
 j=i
 while j<len(vals) and math.isfinite(vals[j]):j+=1
 for k in range(i,j):
  win=vals[max(i,k-2):min(j,k+3)];smoothed[k]=sum(win)/len(win)
 i=j
# Weighted median of all rows; invalid/no-motion frames remain missing.
median_vals=[float('nan')]*len(q)
for k in valid:
 weights=q[k]
 assert all(math.isfinite(v) and v>=0 for v in weights)
 total=sum(weights)
 if total<=0: continue
 cumulative=0.0
 # Scan from greatest height to smallest; first row attaining half the mass.
 for row,w in enumerate(weights):
  cumulative+=w
  if cumulative>=total/2:
   median_vals[k]=(bar-1-row)*factor
   break
median_smoothed=[float('nan')]*len(vals); i=0
while i<len(vals):
 if not math.isfinite(median_vals[i]): i+=1; continue
 j=i
 while j<len(vals) and math.isfinite(median_vals[j]): j+=1
 for k in range(i,j):
  win=median_vals[max(i,k-2):min(j,k+3)]; median_smoothed[k]=sum(win)/len(win)
 i=j
with (p/'run-example-mean-median-motion-height.csv').open('w',newline='') as f:
 writer=csv.writer(f);writer.writerow(['OriginalFrame','Valid','WeightedMeanMM','WeightedMedianMM','MeanSmoothed5MM','MedianSmoothed5MM'])
 for k,m in enumerate(mapping):
  def value(x): return '' if not math.isfinite(x) else f'{x:.8f}'
  writer.writerow([m['OriginalFrame'],m['InvalidFramePair']=='0',value(vals[k]),value(median_vals[k]),value(smoothed[k]),value(median_smoothed[k])])
colmax=max(max(max(above[i]),max(below[i])) for i in valid)
rowmax=max(max(x for x in q[i] if math.isfinite(x)) for i in valid)
print('Shared horizontal profile scale',colmax,'row profile scale',rowmax,flush=True)
bg=subprocess.check_output(['ffmpeg','-loglevel','error','-i','/private/tmp/tail-demo-overlay-background.png','-vf',f'scale={W}:{H}','-frames:v','1','-f','rawvideo','-pix_fmt','rgb24','-'])
assert len(bg)==H*W*3
# Render a single scale label in a conventional font.
label_dir=Path(tempfile.mkdtemp(prefix='tail-scale-label-'))
subprocess.run(['clang','-x','objective-c','-fobjc-arc','-framework','Foundation','-framework','CoreText','-framework','CoreGraphics',str(p/'render_tail_label.c'),'-o',str(label_dir/'label-renderer')],check=True)
(label_dir/'requests.tsv').write_text(f'{label_dir}/scale.rgb\t20 mm\n')
subprocess.run([str(label_dir/'label-renderer'),str(label_dir/'requests.tsv')],check=True)
scale_label=(label_dir/'scale.rgb').read_bytes()
assert len(scale_label)==430*32*3
source=data/'post_mouse_crop_lossless.mkv'; out=p/'TMCS2_S18-D14-trial2-tail-position-median-scalebar.mp4'
decoder=subprocess.Popen(['ffmpeg','-loglevel','error','-i',str(source),'-vf','scale=452:712:flags=neighbor','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
encoder=subprocess.Popen(['ffmpeg','-loglevel','error','-y','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate','30','-i','-','-an','-vf','crop=452:712:80:50','-c:v','libx264','-crf','17','-pix_fmt','yuv420p',str(out)],stdin=subprocess.PIPE)
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
font={'A':['010','101','111','101','101'],'E':['111','100','110','100','111'],'D':['110','101','101','101','110'],'I':['111','010','010','010','111'],'M':['101','111','111','101','101'],'N':['101','111','111','111','101'],'m':['000','000','110','111','101'],'0':['111','101','101','101','111'],'1':['010','110','010','010','111'],'2':['111','001','111','100','111'],'3':['111','001','111','001','111'],'4':['101','101','111','001','001'],'5':['111','100','111','001','111'],'6':['111','100','111','101','111'],'7':['111','001','010','010','010'],'8':['111','101','111','101','111'],'9':['111','101','111','001','111'],'-':['000','000','111','000','000'],'.':['000','000','000','000','010']}
def number(buf,x,y,s,c,sz=3):
 for ch in s:
  for j,row in enumerate(font[ch]):
   for i,b in enumerate(row):
    if b=='1':
     for dy in range(sz):
      for dx in range(sz):pixel(buf,x+i*sz+dx,y+j*sz+dy,c)
  x+=4*sz
red=bytes((210,40,45));green=bytes((0,155,70));purple=bytes((160,35,190));black=bytes((0,0,0));orange=bytes((220,95,0));invalidc=bytes((200,45,40))
for k,(m,h) in enumerate(zip(mapping,heights)):
 needed=452*712*3;parts=[];received=0
 while received<needed:
  chunk=decoder.stdout.read(needed-received)
  if not chunk:raise RuntimeError(f'crop ended at frame {k}')
  parts.append(chunk);received+=len(chunk)
 crop=b''.join(parts); frame=bytearray(bg)
 for y in range(712):
  dst=((oy+y)*W+ox)*3;src=y*452*3;frame[dst:dst+452*3]=crop[src:src+452*3]

 if m['InvalidFramePair']=='0':
  def curve(vals,colour,direction):
   base=oy+scale*(bar-1+(16 if direction>0 else 0));last=None
   for j,value in enumerate(vals):
    xx=ox+2*j; yy=base+direction*(value/colmax)*150
    if last is not None:line(frame,last[0],last[1],xx,yy,colour,2)
    last=(xx,yy)
  curve(above[k],green,-1);curve(below[k],red,1)
  last=None
  for r,value in enumerate(q[k]):
   if not math.isfinite(value):last=None;continue
   xy=(ox+451-180*value/rowmax,oy+2*r)
   if last is not None:line(frame,*last,*xy,purple,2)
   last=xy
  height=median_smoothed[k]
  if math.isfinite(height):
   yy=oy+2*((bar-1)-height/factor)
   line(frame,ox+211,yy,ox+241,yy,bytes((255,255,255)),4)
   line(frame,ox+211,yy,ox+241,yy,black,2)
 else:
  # A red cross communicates that these retained video frames have no valid profile.
  line(frame,ox+10,oy+10,ox+25,oy+25,invalidc,2);line(frame,ox+25,oy+10,ox+10,oy+25,invalidc,2)
 # Scale is vertical and represents 20 mm at 700/1201 mm per source pixel.
 # It stays fixed in every frame, including invalid tracking frames.
 scale_x=ox+11; scale_y=oy+2*(bar-1+16)+12
 scale_end=scale_y+round(2*20/factor)
 white=bytes((255,255,255))
 line(frame,scale_x,scale_y,scale_x,scale_end,white,4)
 line(frame,scale_x,scale_y,scale_x,scale_end,black,2)
 line(frame,scale_x-4,scale_y,scale_x+4,scale_y,black,1)
 line(frame,scale_x-4,scale_end,scale_x+4,scale_end,black,1)
 for y in range(32):
  dst=((scale_y+18+y)*W+scale_x+8)*3;src=y*430*3
  frame[dst:dst+65*3]=scale_label[src:src+65*3]
 encoder.stdin.write(frame)
decoder.stdout.close();assert decoder.wait()==0
encoder.stdin.close();assert encoder.wait()==0
print('Saved',out,'frames',len(mapping),flush=True)
