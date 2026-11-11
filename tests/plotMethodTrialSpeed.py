"""Editable speed-versus-time illustration from saved L40 traces, without reanalysis."""
from pathlib import Path
import csv,math,json
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4'
source=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')
rows=list(csv.DictReader((source/(name+'.trace.csv')).open()));events=list(csv.DictReader((source/(name+'.events.csv')).open()))
scale=700/1201;fps=160;n=len(rows);stops=[r for r in events if r['Type']=='stop'];assert len(stops)==3
W,H=920,380;left,right,top,bottom=90,890,55,305;end=n/fps;ymax=275
X=lambda t:left+t/end*(right-left);Y=lambda v:bottom-v/ymax*(bottom-top)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">', '<title>TMCS2_S18 D0 trial 2: forward speed and detected stops</title>']
im=Image.new('RGB',(W,H),'white');d=ImageDraw.Draw(im)
fontpath='/System/Library/Fonts/Supplemental/Arial.ttf'
def line(x1,y1,x2,y2,color='#222222',width=1):
 svg.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"/>');d.line((x1,y1,x2,y2),fill=color,width=round(width))
def text(x,y,s,size=16,anchor='middle'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#222222">{escape(s)}</text>')
 font=ImageFont.truetype(fontpath,size);d.text((x,y),s,font=font,fill='#222222',anchor={'middle':'ms','end':'rs','start':'ls'}[anchor])
svg.append('<rect width="920" height="380" fill="white"/>')
text(90,28,'TMCS2_S18 | D0 | Trial 2',18,'start')
svg.append('<g id="detected-stops">')
for r in stops:
 a=(int(r['StartTraversalFrame'])-1)/fps;b=int(r['EndTraversalFrame'])/fps;x=X(a);w=X(b)-x
 svg.append(f'<rect x="{x}" y="{top}" width="{w}" height="{bottom-top}" fill="#dbe7f0"/>');d.rectangle((x,top,x+w,bottom),fill='#dbe7f0')
svg.append('</g>')
for v in range(0,251,50):
 y=Y(v);line(left,y,right,y,'#e7e7e7');text(left-12,y+5,str(v),14,'end')
for t in range(7):
 x=X(t);line(x,bottom,x,bottom+5);text(x,bottom+24,str(t),14)
line(left,top,left,bottom);line(left,bottom,right,bottom)
svg.append('<g id="forward-speed" fill="none" stroke="black" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round">')
path=[];segment=[];data=[]
for i,r in enumerate(rows):
 t=i/fps;v=float(r['ForwardSpeed'])*scale;data.append(dict(TraversalFrame=i+1,OriginalFrame=r['OriginalFrame'],TimeSinceTraversalStartSeconds=t,ForwardSpeedMMPerSecond=v,StopMask=r['StopMask']))
 if math.isfinite(v):
  x,y=X(t),Y(v);path.append(f'{"L" if segment else "M"}{x:.4f},{y:.4f}');segment.append((x,y))
 else:
  if len(segment)>1:d.line(segment,fill='black',width=2)
  segment=[]
if len(segment)>1:d.line(segment,fill='black',width=2)
svg.append(f'<path id="raw-saved-speed-mm-per-second" d="{" ".join(path)}"/></g>')
text((left+right)/2,355,'Time since traversal start (s)',17)
svg.append('<text transform="translate(25 180) rotate(-90)" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="17">Forward speed (mm/s)</text>')
label=Image.new('RGBA',(250,30),(255,255,255,0));ld=ImageDraw.Draw(label);ld.text((125,15),'Forward speed (mm/s)',font=ImageFont.truetype(fontpath,17),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(8,55),label)
svg.append('<rect x="735" y="14" width="20" height="14" fill="#dbe7f0"/>');d.rectangle((735,14,755,28),fill='#dbe7f0');text(765,27,'Detected stop',14,'start')
svg.append('</svg>')
stem=OUT/'TMCS2_S18_D0_T2_forward_speed_stops'
assert not stem.with_suffix('.svg').exists()
stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 writer=csv.DictWriter(f,fieldnames=list(data[0]));writer.writeheader();writer.writerows(data)
meta=dict(sourceTrace=str(source/(name+'.trace.csv')),fps=fps,millimetersPerPixel=scale,calibration='Approximate existing 700/1201 mm per pixel; not newly calibrated',timeOrigin='First traversal frame, original frame 856',extraSmoothing=False,nonfiniteTraversalFrames=[r['TraversalFrame'] for r in data if not math.isfinite(r['ForwardSpeedMMPerSecond'])],stops=[dict(firstFrame=r['StartTraversalFrame'],lastFrame=r['EndTraversalFrame'],startSeconds=(int(r['StartTraversalFrame'])-1)/fps,endExclusiveSeconds=int(r['EndTraversalFrame'])/fps) for r in stops],slipsShown=False)
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2));print(json.dumps(meta,indent=2))
