"""Dual-axis example; align medians on common valid frames, preserve values."""
from pathlib import Path
import csv,json,math,statistics
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/figMaterials';src=out/'TMCS2_S18_D0_T2_tail_example_traces.csv';rs=list(csv.DictReader(src.open()));keys=['TailMotionScore','MedianMotionHeight5FrameMM'];valid=[r for r in rs if all(math.isfinite(float(r[k])) for k in keys)];med={k:statistics.median(float(r[k]) for r in valid) for k in keys};span={k:max(abs(float(r[k])-med[k]) for r in rs if math.isfinite(float(r[k])))*1.08 for k in keys}
W,H,Z=310,120,4;L,RR,T,B=24,280,18,92;mid=(T+B)/2;X=lambda t:L+t/(967/160)*(RR-L);Y=lambda v,k:mid-(v-med[k])/span[k]*(B-T)/2
im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=6,anchor='start',color='#222222'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>');f=ImageFont.truetype(font,round(size*Z));ww=d.textlength(s,font=f);d.text((x*Z-(ww/2 if anchor=='middle' else ww if anchor=='end' else 0),(y-size)*Z),s,font=f,fill=color)
def line(x,y,xx,yy,c='#222222',w=.35):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{w}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
text(L,8,'Tail motion and motion height during traverse',8)
text(L,15,'Motion score (a.u.)',6,color='#8B3FA0');text(RR,15,'Median motion height (mm)',6,'end')
for i,r in enumerate(rs):
 if int(r['StopMask']):
  x=X(i/160);xx=X((i+1)/160);svg.append(f'<rect x="{x}" y="{T}" width="{xx-x}" height="{B-T}" fill="#dbe7f0"/>');d.rectangle((x*Z,T*Z,xx*Z,B*Z),fill='#dbe7f0')
svg.append(f'<path d="M{L},{mid}H{RR}" stroke="#aaaaaa" stroke-width=".3" stroke-dasharray="1.2 1.2"/>')
for x in range(int(L*Z),int(RR*Z),10):d.line((x,mid*Z,x+5,mid*Z),fill='#aaaaaa',width=1)
for k,c,ticks,axis,anchor in [(keys[0],'#8B3FA0',range(-8,13,2),L,'end'),(keys[1],'#222222',range(-100,121,20),RR,'start')]:
 for v in ticks:
  y=Y(v,k)
  if T<=y<=B:
   sign=-1 if axis==L else 1;line(axis,y,axis+sign*1.5,y,c);text(axis+sign*3,y+2,str(v),6,anchor,c)
 path=[];seg=[]
 for i,r in enumerate(rs):
  v=float(r[k])
  if math.isfinite(v):
   x,y=X(i/160),Y(v,k);path.append(('L' if seg else 'M')+f'{x:.5f},{y:.5f}');seg.append((x*Z,y*Z))
  else:
   if len(seg)>1:d.line(seg,fill=c,width=2)
   seg=[]
 if len(seg)>1:d.line(seg,fill=c,width=2)
 svg.append('<path d="'+' '.join(path)+f'" fill="none" stroke="{c}" stroke-width=".5"/>');line(axis,T,axis,B,c)
line(L,B,RR,B)
for t in range(7):x=X(t);line(x,B,x,B+1.5);text(x,B+7,str(t),6,'middle')
text((L+RR)/2,109,'Time since traversal start (s)',6,'middle');text((L+RR)/2,118,'Dashed line: medians aligned for display; independent y-axis scales',5,'middle')
svg.append('</svg>');stem=out/'TMCS2_S18_D0_T2_tail_overlay_medians_aligned';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'));stem.with_suffix('.json').write_text(json.dumps(dict(source=str(src),commonValidFrames=len(valid),medians=med,axisLimits={k:[med[k]-span[k],med[k]+span[k]] for k in keys},display='Medians on common finite frames at vertical midpoint; independent symmetric ranges include all finite values with 8 percent headroom. Values unchanged; no extra smoothing. Crossings and relative amplitudes have no quantitative shared-axis meaning.'),indent=2));print(med,len(valid))
