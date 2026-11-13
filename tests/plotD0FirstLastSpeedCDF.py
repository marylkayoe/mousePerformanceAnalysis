"""Empirical CDFs of paired mouse-level first/last locomoting speed at D0."""
from pathlib import Path
import csv,json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/D0-within-day-trials'
rows=list(csv.DictReader((R/'D0_locomoting_speed_last_minus_first_scatter.csv').open()))
W,H,Z=1020,375,2;im=Image.new('RGB',(W*Z,H*Z),'white');dr=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=14,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{s}</text>');dr.text((x*Z,y*Z),s,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def path(pts,c='#232323',w=1,dash=False):
 svg.append('<path d="M'+' L'.join(f'{x:.4f},{y:.4f}' for x,y in pts)+f'" fill="none" stroke="{c}" stroke-width="{w}" stroke-linejoin="round"'+(' stroke-dasharray="6 4"' if dash else '')+'/>')
 phase=0
 for (x,y),(xx,yy) in zip(pts,pts[1:]):
  length=np.hypot(xx-x,yy-y)
  if not dash:dr.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)));continue
  offset=0
  while offset<length:
   left=(6-phase) if phase<6 else (10-phase);step=min(left,length-offset)
   if phase<6:dr.line(((x+(xx-x)*offset/length)*Z,(y+(yy-y)*offset/length)*Z,(x+(xx-x)*(offset+step)/length)*Z,(y+(yy-y)*(offset+step)/length)*Z),fill=c,width=max(1,round(w*Z)))
   offset+=step;phase=(phase+step)%10
text(35,27,'D0 locomoting speed: first and last retained crossings',22)
export=[]
for j,(g,c,label) in enumerate(zip(['sedentary','walk','run'],['#232323','#00b226','#002bff'],['SED','WALK','RUN'])):
 rs=[r for r in rows if r['group']==g];L=55+j*335;RR=L+260;T=85;B=285;X=lambda v:L+v/200*260;Y=lambda v:B-v*200
 text((L+RR)/2,58,f'{label} · {len(rs)} mice',17,'middle')
 for y in [0,.25,.5,.75,1]:
  path([(L,Y(y)),(RR,Y(y))],'#eeeeee');text(L-7,Y(y)+4,f'{y:g}',11,'end')
 for v in [0,50,100,150,200]:path([(X(v),B),(X(v),B+4)]);text(X(v),B+19,str(v),11,'middle')
 for key,lab,dashed in [('firstSpeed','First',True),('lastSpeed','Last',False)]:
  a=np.sort([float(r[key]) for r in rs]);assert a[0]>=0 and a[-1]<=200
  pts=[(0,0)]
  for i,v in enumerate(a):pts.extend([(v,i/len(a)),(v,(i+1)/len(a))])
  pts.append((200,1));path([(X(x),Y(y)) for x,y in pts],c,2,dashed)
  export.extend(dict(group=g,crossing=lab,speedMMPerS=x,cumulativeFraction=y,nMice=len(a)) for x,y in pts)
 path([(L,T),(L,B),(RR,B)]);text((L+RR)/2,B+41,'Locomoting speed (mm/s)',13,'middle')
 path([(L+12,T+17),(L+42,T+17)],c,2,True);text(L+49,T+21,'First',11)
 path([(L+12,T+36),(L+42,T+36)],c,2);text(L+49,T+40,'Last',11)
text(35,365,'Cumulative fraction of mice · one speed per mouse/crossing · same paired mice · stops excluded',13)
svg.append('</svg>');stem=R/'D0_first_last_locomoting_speed_mouse_CDFs';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
stem.with_suffix('.md').write_text('''# D0 first/last mouse-speed CDFs

Empirical distributions of the SAME mouse-level scalar locomoting speeds as the paired scatter, not distributions of frames or spatial speed bins. Each mouse contributes equally once per crossing; first and third retained D0 crossings, 41 complete-triplet mice (12 SED,12 WALK,17 RUN). Stops excluded by original meanSpeedLoco. Source: D0_locomoting_speed_last_minus_first_scatter.csv, which retains source filenames and paired values. No smoothing, interpolation, clipping or new statistical test. CDFs show marginal distributions and do not display individual pairing; do not apply independent-sample KS tests. Existing paired cage-aware inference remains in statistics.json. First dashed, last solid; leftward shift means slower. Reproduce tests/plotD0FirstLastSpeedCDF.py.
''')
print(stem)
