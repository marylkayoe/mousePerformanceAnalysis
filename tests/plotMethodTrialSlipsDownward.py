"""Editable under-bar motion-versus-time illustration from saved L40 traces, without reanalysis."""
from pathlib import Path
import csv,math,json
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4'
source=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')
rows=list(csv.DictReader((source/(name+'.trace.csv')).open()));events=list(csv.DictReader((source/(name+'.events.csv')).open()))
scale=1;fps=160;n=len(rows);slips=[r for r in events if r['Type']=='slip'];assert len(slips)==8
W,H=920,380;left,right,top,bottom=90,890,55,305;end=n/fps;ymax=50
X=lambda t:left+t/end*(right-left);Y=lambda v:top+v/ymax*(bottom-top)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">', '<title>TMCS2_S18 D0 trial 2: under-bar motion and detected slips</title>']
im=Image.new('RGB',(W,H),'white');d=ImageDraw.Draw(im)
fontpath='/System/Library/Fonts/Supplemental/Arial.ttf'
def line(x1,y1,x2,y2,color='#222222',width=1):
 svg.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"/>');d.line((x1,y1,x2,y2),fill=color,width=round(width))
def text(x,y,s,size=16,anchor='middle'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#222222">{escape(s)}</text>')
 font=ImageFont.truetype(fontpath,size);d.text((x,y),s,font=font,fill='#222222',anchor={'middle':'ms','end':'rs','start':'ls'}[anchor])
svg.append('<rect width="920" height="380" fill="white"/>')
text(90,28,'TMCS2_S18 | D0 | Trial 2',18,'start')
for v in range(0,51,10):
 y=Y(v);line(left,y,right,y,'#e7e7e7');text(left-12,y+5,str(v),14,'end')
for t in range(7):
 x=X(t);line(x,bottom,x,bottom+5);text(x,bottom+24,str(t),14)
line(left,top,left,bottom);line(left,bottom,right,bottom)
threshold=2.5
y=Y(threshold)
svg.append(f'<line id="slip-threshold" x1="{left}" y1="{y}" x2="{right}" y2="{y}" stroke="#D55E00" stroke-width="1.4" stroke-dasharray="7 4"/>')
for xx in range(left,right,11):d.line((xx,y,min(xx+7,right),y),fill='#D55E00',width=1)
text(510,28,'Dashed: slip threshold = 2.5',14,'start')
svg.append('<g id="under-bar-motion" fill="none" stroke="black" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round">')
path=[];segment=[];data=[]
for i,r in enumerate(rows):
 t=i/fps;v=float(r['MovementTrace'])*scale;data.append(dict(TraversalFrame=i+1,OriginalFrame=r['OriginalFrame'],TimeSinceTraversalStartSeconds=t,NormalizedUnderBarMotion=v,StopMask=r['StopMask']))
 if math.isfinite(v):
  x,y=X(t),Y(v);path.append(f'{"L" if segment else "M"}{x:.4f},{y:.4f}');segment.append((x,y))
 else:
  if len(segment)>1:d.line(segment,fill='black',width=2)
  segment=[]
if len(segment)>1:d.line(segment,fill='black',width=2)
svg.append(f'<path id="saved-normalized-under-bar-motion" d="{" ".join(path)}"/></g>')
text((left+right)/2,355,'Time since traversal start (s)',17)
svg.append('<text transform="translate(25 180) rotate(-90)" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="17">Under-bar motion (a.u.)</text>')
label=Image.new('RGBA',(250,30),(255,255,255,0));ld=ImageDraw.Draw(label);ld.text((125,15),'Under-bar motion (a.u.)',font=ImageFont.truetype(fontpath,17),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(8,55),label)
peaks=[]
svg.append('<g id="detected-slip-peaks" fill="#D55E00" stroke="white" stroke-width="1">')
for e in slips:
 start=int(e['StartTraversalFrame'])-1;endidx=int(e['EndTraversalFrame'])
 k=max(range(start,endidx),key=lambda k:float(rows[k]['MovementTrace']))
 v=float(rows[k]['MovementTrace']);x,y=X(k/fps),Y(v);radius=4
 svg.append(f'<circle id="slip-peak-{len(peaks)+1}" cx="{x}" cy="{y}" r="{radius}"/>')
 d.ellipse((x-radius,y-radius,x+radius,y+radius),fill='#D55E00',outline='white',width=1)
 peaks.append(dict(traversalFrame=k+1,originalFrame=int(rows[k]['OriginalFrame']),timeSeconds=k/fps,value=v))
svg.append('</g>')
svg.append('<circle cx="745" cy="21" r="4" fill="#D55E00"/>');d.ellipse((741,17,749,25),fill='#D55E00');text(765,27,'Slip peak',14,'start')
svg.append('</svg>')
stem=OUT/'TMCS2_S18_D0_T2_under_bar_motion_slips_downward'
assert not stem.with_suffix('.svg').exists()
stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 writer=csv.DictWriter(f,fieldnames=list(data[0]));writer.writeheader();writer.writerows(data)
meta=dict(sourceTrace=str(source/(name+'.trace.csv')),sourceEvents=str(source/(name+'.events.csv')),fps=fps,timeOrigin='First traversal frame, original frame 856',extraSmoothing=False,slipThreshold=2.5,traceDefinition='Saved MovementTrace: weighted under-bar image differences, speed adjusted, smoothed and median/MAD normalized by existing detector. No new transformations.',slips=[dict(firstFrame=r['StartTraversalFrame'],lastFrame=r['EndTraversalFrame'],startSeconds=(int(r['StartTraversalFrame'])-1)/fps,endExclusiveSeconds=int(r['EndTraversalFrame'])/fps) for r in slips],stopAnnotations=False,displayDirection="Positive motion plotted downward; magnitude is not signed physical displacement",peakSymbols=peaks,overlapPolicy='All eight saved slips retained, including overlaps with stops; intervals are saved detector outputs, not newly thresholded.',nonfiniteFrames=[])
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2));print(stem.with_suffix('.svg'))
