"""Last retained trial profiles, preserving existing bins, masks and calibration."""
from pathlib import Path
from collections import defaultdict
import csv,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS';O=R/'last-crossing-spatial';O.mkdir(exist_ok=True)
manifest=list(csv.DictReader((R/'analysis-data/trial_manifest.csv').open()));by=defaultdict(list)
for r in manifest:
 if r['Day'] in ('0','14'):by[r['MouseID'],r['Day']].append(r)
sel={k:max(v,key=lambda r:int(r['TrialNumber'])) for k,v in by.items()};assert len(sel)==84
with (O/'selected_crossings.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(manifest[0]));w.writeheader();w.writerows(sel.values())
profiles={};positions={};mapping={r['MouseID']:r['Group'] for r in manifest}
for metric in ['posture','speed']:
 d=json.loads((R/f'{metric}-presentation/{metric}-profile-source.json').read_text());x=np.array(d['x']);keep=(x>=42)&(x<=1243);pos=(1243-x[keep])*700/1201;order=np.argsort(pos);positions[metric]=pos[order]
 for t in d['traces']:
  day={'D00':'0','D14':'14'}.get(t['day'])
  if day is None:continue
  chosen=sel[t['mouseID'],day]['File'];j=t['filenames'].index(chosen);a=np.array(t['trialHeight' if metric=='posture' else 'trialSpeedRelative'][j],float)
  assert len(a)==len(x)
  profiles[metric,t['mouseID'],day]=a[keep][order]*700/1201
for day,folder in [('0','D0-spatial-motion-and-height'),('14','D14-minus-D0-spatial-motion-and-height')]:
 for metric in ['height','score']:
  positions[metric]=np.arange(5,700,10)
  for m,dd in sel:
   if dd==day:profiles[metric,m,day]=np.full(70,np.nan)
 for r in csv.DictReader((R/f'tail-metrics/{folder}/trial-position-bins.csv').open()):
  if r['File']!=sel[r['MouseID'],day]['File']:continue
  b=int(r['Bin']);assert 0<=b<70
  for metric,field in [('height','Height'),('score','Score')]:
   if int(r[field+'Frames'])>0:profiles[metric,r['MouseID'],day][b]=float(r[field+'Mean'])
summary=[];source=[]
for metric,x in positions.items():
 for period in ['0','14','change']:
  for g in ['sedentary','walk','run']:
   ms=sorted(m for m in mapping if mapping[m]==g and (metric,m,'0') in profiles and (metric,m,'14') in profiles)
   a=np.array([profiles[metric,m,'14']-profiles[metric,m,'0'] if period=='change' else profiles[metric,m,period] for m in ms])
   for m,vv in zip(ms,a):
    source.extend(dict(metric=metric,period=period,mouse=m,group=g,positionMM=float(v),value=float(value)) for v,value in zip(x,vv))
   for j,v in enumerate(x):
    vals=a[:,j];vals=vals[np.isfinite(vals)];n=len(vals)
    summary.append(dict(metric=metric,period=period,group=g,bin=j,positionMM=float(v),nMice=n,mean=float(np.mean(vals)) if n else float('nan'),SEM=float(np.std(vals,ddof=1)/np.sqrt(n)) if n>1 else float('nan')))
W,H,Z=1530,1190,2;im=Image.new('RGB',(W*Z,H*Z),'white');draw=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=12,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{t}</text>');draw.text((x*Z,y*Z),t,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','end':'rs','middle':'ms'}[anchor])
def path(pts,c='#232323',w=1):
 svg.append('<path d="M'+' L'.join(f'{x:.3f},{y:.3f}' for x,y in pts)+f'" fill="none" stroke="{c}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"/>');draw.line([(x*Z,y*Z) for x,y in pts],fill=c,width=max(1,round(w*Z)),joint='curve')
for col,t in enumerate(['D0 · last retained crossing','D14 · last retained crossing','D14 − D0 · paired last crossings']):text(250+col*510,28,t,18,'middle')
minimum={'sedentary':6,'walk':6,'run':9};configs=[('posture','Centroid height',1,1,'mm'),('speed','Forward speed',50,25,'mm/s'),('height','Tail-motion height',10,10,'mm'),('score','Tail-motion score',.5,.5,'a.u.')]
for row,(metric,title,bar,changebar,unit) in enumerate(configs):
 valid=[r for r in summary if r['metric']==metric and r['nMice']>=minimum[r['group']] and math.isfinite(r['SEM'])]
 for col,period in enumerate(['0','14','change']):
  data=[r for r in valid if r['period']==period];bounds=[r for r in valid if (r['period']=='change')==(period=='change')];lo=min(r['mean']-r['SEM'] for r in bounds);hi=max(r['mean']+r['SEM'] for r in bounds)
  if period=='change' or metric in ('height','score'):lo=min(lo,0);hi=max(hi,0)
  vb=changebar if period=='change' else bar;span=max(hi-lo,2*vb);lo-=.15*span;hi+=.2*span
  L=35+510*col;RR=L+445;T=85+row*270;B=T+160;X=lambda v:L+v/700*(RR-L);Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
  text(L,T-23,title+(' change' if period=='change' else ''),18)
  for xx in [L,RR]:
   for yy in np.arange(T,B,10):path([(xx,yy),(xx,min(B,yy+5))],'#aaaaaa')
  text(L,B+19,'Start',11,'middle');text(RR,B+19,'Finish',11,'middle')
  if period=='change' or metric=='height':
   if metric=='height' and period!='change':
    for xx in np.arange(L,RR,14):path([(xx,Y(0)),(min(RR,xx+8),Y(0))],'#777777')
   else:path([(L,Y(0)),(RR,Y(0))],'#aaaaaa')
   text(RR-5,Y(0)-5,'0 '+unit+' change' if period=='change' else 'Bar top',10,'end')
  for g,c in zip(['sedentary','walk','run'],['#232323','#00b226','#002bff']):
   a=sorted([r for r in data if r['group']==g],key=lambda r:r['bin']);segments=[];seg=[]
   for r in a:
    if seg and r['bin']!=seg[-1]['bin']+1:segments.append(seg);seg=[]
    seg.append(r)
   if seg:segments.append(seg)
   for ss in segments:
    if len(ss)<2:continue
    pts=[(X(r['positionMM']),Y(r['mean']+r['SEM'])) for r in ss]+[(X(r['positionMM']),Y(r['mean']-r['SEM'])) for r in ss[::-1]]
    svg.append('<polygon points="'+' '.join(f'{x:.3f},{y:.3f}' for x,y in pts)+f'" fill="{c}" fill-opacity=".16"/>');lay=Image.new('RGBA',im.size);ld=ImageDraw.Draw(lay);ld.polygon([(x*Z,y*Z) for x,y in pts],fill=tuple(int(c[j:j+2],16) for j in [1,3,5])+(41,));im.paste(Image.alpha_composite(im.convert('RGBA'),lay).convert('RGB'))
    path([(X(r['positionMM']),Y(r['mean'])) for r in ss],c,2)
  sx=L+22;sy=T+12;path([(sx,sy),(sx,sy+vb/(hi-lo)*(B-T))],w=3);text(sx+9,sy+13,f'{vb:g} {unit}',11)
  yy=B+40;path([(X(300),yy),(X(400),yy)],w=3);text(X(350),yy+17,'10 cm',12,'middle')
text(35,1150,'SED black · WALK green · RUN blue. Equal mouse means ± SEM; shading is descriptive, not cage-adjusted confidence.',13)
text(35,1173,'One selected trial per mouse/day. Gaps preserved; bins shown with ≥ half the group contributing. No additional smoothing.',12)
svg.append('</svg>');stem=O/'last_crossing_D0_D14_and_changes';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
for name,rows in [('group_profiles',summary),('mouse_profiles',source)]:
 with (O/(name+'.csv')).open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
(O/'README.md').write_text('''# Last-retained-trial spatial profiles

Reproduce tests/plotLastCrossingSpatialProfiles.py. Twelve panels: centroid height,forward speed,tail-motion height,tail-motion score × D0,D14,paired D14−D0. Select highest retained trialNumber independently per mouse/day (84 selected trials), full filenames/timing in selected_crossings.csv. Source values unchanged; no retracking or source-video reads. Posture/speed source JSON contains per-trial bins (trialHeight/trialSpeedRelative); verify filenames against manifest. px converted700/1201. Camera tape bounds42..1243; reverse to entry-left0..700mm. Speed profile includes stops, unlike locomoting-speed scalar. Spatial source bins10camera pixels, retained within tape marks. Tail rows use existing10mm entry-relative trial-position-bins.csv from D0-spatial-motion-and-height and D14-minus-D0-spatial-motion-and-height, corrected whole-motion score and smoothed full-profile motion height. Tail invalid pair/bad-frame handling inherited from those exports, not Legacy scalar masks.

Means equal mice; SEM across mice. Paired differences at same bin only when both days finite. No padding/interpolation or bridging missing/low-support bins. Show minimum6SED,6WALK,9RUN contributors (half group), preserve variable bin counts in CSV. D0/D14 axes shared within metric; change scale separate. Real calibration horizontal100mm=10cm, vertical bars reflect plotted units. Profiles use continuous paths per finite segment, no additional smoothing. Tail height is location of motion,not anatomical tail position. No per-position statistics or significance inferred. Original results preserved.
''')
print(stem)
