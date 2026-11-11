"""Stacked tail traces with an intervening slip-event timing strip."""
from pathlib import Path
import csv,json,math
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/figMaterials';rows=list(csv.DictReader((out/'TMCS2_S18_D0_T2_tail_example_traces.csv').open()));name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4';src=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')/(name+'.events.csv');slips=[r for r in csv.DictReader(src.open()) if r['Type']=='slip'];assert len(slips)==8
W,H,Z=290,190,4;L,RR=30,280;X=lambda t:L+t/(967/160)*(RR-L)
im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=6,anchor='start',c='#222222'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{c}">{s}</text>');f=ImageFont.truetype(font,round(size*Z));ww=d.textlength(s,font=f);d.text((x*Z-(ww/2 if anchor=='middle' else ww if anchor=='end' else 0),(y-size)*Z),s,font=f,fill=c)
def line(x,y,xx,yy,c='#222222',w=.35):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{w}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
for key,title,top,bottom,lo,hi,ticks,c in [('TailMotionScore','Tail-motion score (a.u.)',16,74,-4,8,(-4,0,4,8),'#8B3FA0'),('MedianMotionHeight5FrameMM','Median motion height (mm relative to bar)',111,165,-40,80,(-40,0,40,80),'#222222')]:
 Y=lambda v:bottom-(v-lo)/(hi-lo)*(bottom-top)
 text(L,top-5,title,7,c=c)
 for v in ticks:
  y=Y(v);line(L,y,RR,y,'#e7e7e7');text(L-3,y+2,str(v),6,'end')
 if key.startswith('Median'):
  line(L,Y(0),RR,Y(0),'#777777',.5);text(L+2,Y(0)-2,'Bar level',5,c='#666666')
 path=[];seg=[]
 for i,r in enumerate(rows):
  v=float(r[key])
  if math.isfinite(v):
   x,y=X(i/160),Y(v);path.append(('L' if seg else 'M')+f'{x:.5f},{y:.5f}');seg.append((x*Z,y*Z))
  else:
   if len(seg)>1:d.line(seg,fill=c,width=2)
   seg=[]
 if len(seg)>1:d.line(seg,fill=c,width=2)
 svg.append('<path d="'+' '.join(path)+f'" fill="none" stroke="{c}" stroke-width=".5"/>');line(L,top,L,bottom);line(L,bottom,RR,bottom)
text(L,89,'Detected slips',6,c='#D5650B');marks=[]
for e in slips:
 a=int(e['StartTraversalFrame']);b=int(e['EndTraversalFrame']);t=((a+b)/2-1)/160;x=X(t);line(x,81,x,92,'#D5650B',.8);marks.append(dict(event=e['EventNumber'],start=a,end=b,midpointSeconds=t))
for t in range(7):
 x=X(t);line(x,165,x,167);text(x,174,str(t),6,'middle')
text((L+RR)/2,186,'Time since traversal start (s)',7,'middle')
svg.append('</svg>');stem=out/'TMCS2_S18_D0_T2_tail_stacked_slip_markers';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'));stem.with_suffix('.json').write_text(json.dumps(dict(sourceTrace=str(out/'TMCS2_S18_D0_T2_tail_example_traces.csv'),sourceEvents=str(src),slipMarkers=marks,notes='Event midpoint ticks, all eight slips including stop-overlap events. No stop shading. Measurements unchanged from existing example traces; five-frame median-height smoothing preserved, invalid frames remain gaps; motion location is not anatomical tail position. Positive height above bar. No association test.'),indent=2))
