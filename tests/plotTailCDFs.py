"""Valid-frame tail CDFs; equal crossings within mice and equal mice in groups."""
from pathlib import Path
import csv,json,math
from collections import defaultdict
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change'
trials=list(csv.DictReader((out/'trial-index.csv').open()));a=np.genfromtxt(out/'frame-values.csv',delimiter=',',names=True);curves={};summary=[];qcs=[]
groups=['sedentary','walk','run'];cols=['#232323','#00B226','#002BFF']
for metric,field in [('score','MotionScore'),('height','MotionHeightMM')]:
 vals=a[field];finite=vals[np.isfinite(vals)];lo=float(min(finite));hi=float(max(finite))
 if metric=='score':
  transform=lambda x:np.sign(x)*np.log10(1+np.abs(x));inverse=lambda x:np.sign(x)*(10**np.abs(x)-1)
  left=math.floor(float(transform(lo))*2)/2;right=math.ceil(float(transform(hi))*2)/2;grid=inverse(np.linspace(left,right,1601))
 else:
  transform=lambda x:np.asarray(x);left=math.floor(lo/10)*10;right=math.ceil(hi/10)*10;grid=np.linspace(left,right,1601)
 by=defaultdict(list)
 for i,t in enumerate(trials,1):
  v=vals[a['TrialIndex']==i];v=np.sort(v[np.isfinite(v)]);qcs.append(dict(Metric=metric,TrialIndex=i,File=t['File'],ValidFrames=len(v)))
  if not len(v):continue
  by[t['MouseID'],t['Day']].append(np.searchsorted(v,grid,side='right')/len(v))
 mouse={k:np.mean(v,axis=0) for k,v in by.items()};mapping={t['MouseID']:t['Group'] for t in trials};ids=sorted({m for m,day in mouse if (m,'0') in mouse and (m,'14') in mouse});assert len(ids)==42
 for period in ('D14','change'):
  for g in groups:
   ms=[m for m in ids if mapping[m]==g];arr=np.array([mouse[m,'14']-(mouse[m,'0'] if period=='change' else 0) for m in ms]);mu=arr.mean(axis=0);se=arr.std(axis=0,ddof=1)/np.sqrt(len(ms));curves[metric,period,g]=(grid,mu,se,left,right)
   for x,y,e in zip(grid,mu,se):summary.append([metric,period,g,x,y,e,len(ms)])
W,H,Z=1000,730,2;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=12,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{t}</text>');d.text((x*Z,y*Z),t,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,c='#333333',w=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{c}" stroke-width="{w}" fill="none"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=round(w*Z))
for row,metric in enumerate(('score','height')):
 for col,period in enumerate(('D14','change')):
  L=65+500*col;RR=L+410;T=65+350*row;B=T+225
  grid,_,_,left,right=curves[metric,period,'sedentary'];tr=(lambda v:np.sign(v)*np.log10(1+np.abs(v))) if metric=='score' else (lambda v:v);X=lambda v:L+(tr(v)-left)/(right-left)*(RR-L)
  limit=max(.1,math.ceil(max(np.max(abs(mu)+se) for (mm,pp,gg),(xx,mu,se,ll,rr) in curves.items() if mm==metric and pp=='change')*10)/10);yl,yh=(-limit,limit) if period=='change' else (0,1);Y=lambda v:B-(v-yl)/(yh-yl)*(B-T)
  text(L,T-35,('Tail-motion score' if metric=='score' else 'Motion height')+(', D14' if period=='D14' else ', D14−D0 CDF change'),18);text(L,T-15,'Cumulative fraction' if period=='D14' else 'Change in cumulative fraction',11)
  for v in np.linspace(yl,yh,5):line(L,Y(v),RR,Y(v),'#aaaaaa' if period=='change' and abs(v)<1e-9 else '#eeeeee');text(L-8,Y(v)+4,f'{v:.2g}',11,'end')
  ticks=[-10,-1,0,1,10,100,1000,10000] if metric=='score' else list(range(math.ceil(left/20)*20,int(right)+1,20))
  for v in ticks:
   if left<=tr(v)<=right:line(X(v),B,X(v),B+4);text(X(v),B+19,f'{v:g}',10,'middle')
  for g,c in zip(groups,cols):
   xx,mu,se,_,_=curves[metric,period,g]
   if period=='change':
    pts=[(X(x),Y(y+e)) for x,y,e in zip(xx,mu,se)]+[(X(x),Y(y-e)) for x,y,e in zip(xx[::-1],mu[::-1],se[::-1])];svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" fill-opacity=".13"/>');lay=Image.new('RGBA',im.size);ld=ImageDraw.Draw(lay);rgb=tuple(int(c[j:j+2],16) for j in (1,3,5));ld.polygon([(x*Z,y*Z) for x,y in pts],fill=rgb+(33,));im.paste(Image.alpha_composite(im.convert('RGBA'),lay).convert('RGB'))
   pts=[(X(x),Y(y)) for x,y in zip(xx,mu)];svg.append('<path d="M'+' L'.join(f'{x:.4f},{y:.4f}' for x,y in pts)+f'" fill="none" stroke="{c}" stroke-width="1.8"/>');d.line([(x*Z,y*Z) for x,y in pts],fill=c,width=4)
  line(L,T,L,B);line(L,B,RR,B);text((L+RR)/2,B+41,'Motion score (a.u.; signed-log spacing)' if metric=='score' else 'Motion height relative to bar (mm)',12,'middle')
  if period=='D14':
   for i,(g,c) in enumerate(zip(('SED','WALK','RUN'),cols)):
    y=B-65+i*19;line(RR-90,y,RR-65,y,c,2);text(RR-55,y+4,g,12)
text(W/2,720,'Equal crossing weight within mouse · equal mouse weight within group · change shading: paired-mouse SEM',12,'middle');svg.append('</svg>');stem=out/'tail_CDF_D14_and_D14_minus_D0';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with (out/'group_CDFs.csv').open('w',newline='') as f:w=csv.writer(f);w.writerow(['Metric','Period','Group','Threshold','MeanCDF','SEM','nMice']);w.writerows(summary)
with (out/'valid_frames.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(qcs[0]));w.writeheader();w.writerows(qcs)
(out/'README.md').write_text('''# Tail CDFs: D14 and paired D14−D0

Reproduce with tests/exportTailCDFValues.m then tests/plotTailCDFs.py. Reads canonical L40 saved row profiles and corrected whole-tail traces; preserves original results. Existing tail bad frames and invalid frame pairs are excluded as missing. Frame values retain NaNs. Height: full probability-weighted motion-profile median relative to bar top; contiguous-valid five-frame smoothing. Motion score: corrected NewWholeNormalized. All retained traversal frames; no tape-position restriction.

Each crossing empirical CDF uses finite frames only; crossings average equally within mouse/day, then mice equally within group. Changes are D14 CDF minus D0 CDF within mouse before averaging. Both days have42 mice; D0 has125 crossings, D14 has126. Values and valid-frame counts are saved. Motion-height index is location of motion, not anatomical stationary-tail position.

Curves evaluate empirical CDFs at1601 fixed display thresholds spanning the full observed range, joined for rendering; no statistical smoothing or clipping. Score axis uses sign(x)*log10(1+abs(x)) to retain negative normalized values and the long positive tail. Tick labels are original scores. Height uses linear mm. Positive changes indicate a greater fraction at or below a threshold at D14. Shading is descriptive paired-mouse SEM, not cage-adjusted or simultaneous confidence. No new significance tests.
''');print(stem)
