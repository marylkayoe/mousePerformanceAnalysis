"""Update supplied editable artwork from validated 3x-mask data; preserve older figures."""
from pathlib import Path
import csv,json,math,collections,statistics,re,xml.etree.ElementTree as E
import numpy as np
from scipy.io import loadmat
R=Path(__file__).resolve().parents[1]; B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_centroid3_height10_20261113');O=B/'figure_panels';N='http://www.w3.org/2000/svg';E.register_namespace('',N)
read=lambda p:list(csv.DictReader(p.open()))
def txt(e,v):
 for c in list(e):e.remove(c)
 e.text=v
# Reuse exact main-figure scatter marker/font geometry.
s=E.parse(R/'tests/figure_templates/tail_scatter_D14_user.svg').getroot();gs=s.findall('{*}g');g=gs[0]
for other in gs[1:]:s.remove(other)
s.set('viewBox','-4 0 83 99');rows=[r for r in read(B/'mouse_values.csv') if r['selection']=='D0_first' and r['metric']=='MeanHeight'];assert len(rows)==42
st=next(x for x in json.loads((B/'statistics.json').read_text()) if x['selection']=='D0_first' and x['metric']=='MeanHeight')
ts=g.findall('{*}text');txt(ts[0],'Tail-motion height, D0');txt(ts[1],'mm');Y=lambda v:85.97-66.76*v/75
for e,v in zip(ts[2:6],[0,25,50,75]):
 txt(e,str(v));xy=re.findall(r'-?[\d.]+',e.get('transform'));e.set('transform',f'translate(5 {xy[1]})');e.set('text-anchor','end')
txt(ts[6],f"p = {st['omnibus_p']:.3f}")
for group,dc,pc,lc in [('sedentary','cls-7','cls-3','cls-9'),('walk','cls-12','cls-2','cls-11'),('run','cls-16','cls-1','cls-10')]:
 rr=[r for r in rows if r['group']==group];dots=[e for e in g if e.tag.endswith('circle') and e.get('class')==dc];assert len(dots)==len(rr)
 for e,r in zip(dots,rr):e.attrib.pop('transform',None);e.set('cy',str(Y(float(r['value']))))
 cells=collections.defaultdict(list)
 for r in rr:cells[r['cohort'],r['cageID']].append(float(r['value']))
 ds=[e for e in g if e.tag.endswith('polygon') and e.get('class')==pc];assert len(ds)==len(cells)
 for e,vs in zip(ds,cells.values()):
  pts=list(map(float,re.findall(r'-?[\d.]+',e.get('points'))));dy=Y(statistics.mean(vs))-pts[1];e.set('points',' '.join(str(v+dy if i%2 else v) for i,v in enumerate(pts)))
 line=next(e for e in g if e.tag.endswith('line') and e.get('class')==lc);y=Y(statistics.mean(float(r['value']) for r in rr));line.set('y1',str(y));line.set('y2',str(y))
E.ElementTree(s).write(O/'D0_first_tail_height.svg',encoding='utf-8',xml_declaration=True)
with (O/'D0_first_tail_height.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4';d=loadmat(O/'validated_example/factor3/traces'/ (name+'.mat'),simplify_cells=True)
f=np.asarray(d['originalFrames'],dtype=int);invalid=np.asarray(d['invalid'],dtype=bool);h=d['motionHeight'];z=d['normalized'];dims=read(O/'validated_example/factor3/example_summary.csv')[0];motion=d['wholeUnweighted']*1000/(float(dims['CropHeight'])*float(dims['CropWidth']));valid=~invalid & ~d['stoppingFrames'].astype(bool)&np.isfinite(d['forwardSpeeds'])&(d['forwardSpeeds']>=40)
sm=np.full(len(f),np.nan)
for i in range(len(f)):
 if not valid[i]:continue
 a=i;b=i
 while a>max(0,i-8) and valid[a-1]:a-=1
 while b<min(len(f)-1,i+8) and valid[b+1]:b+=1
 sm[i]=np.mean(motion[a:b+1])
lo,hi=np.nanpercentile(sm,[5,95]);events=read(O/'validated_example/factor3/example_events.csv');events=[e for e in events if math.isfinite(float(e['HeightAtPeakMM'])) and float(e['HeightAtPeakMM'])<=10]
assert len(f)==967 and f[0]==856 and f[-1]==1822
s=E.parse(R/'tests/figure_templates/tail_example_centroid3_requested.svg').getroot();g=next(g for g in s.iter() if len(g.findall('{*}path'))>800)
for e in list(g):
 if (e.tag.endswith('path') and e.get('class') not in ('cls-14','cls-12')) or e.tag.endswith('ellipse') or e.tag.endswith('line'):g.remove(e)
# The a/b annotation group contains the old image-reference markers. Rebuild at new coordinates.
for e in list(g):
 if e.tag.endswith('g') and set(''.join(t.itertext()).strip() for t in e.iter() if t.tag.endswith('text'))=={'a','b'}:g.remove(e)
# Locate any residual old a/b marker group outside main plot.
parents={c:p for p in s.iter() for c in p}
for e in list(s.iter()):
 if e.tag.endswith('text') and ''.join(e.itertext()).strip() in ('a','b'):
  p=parents[e];p.remove(e)
# Preserve reference color-key geometry and update endpoint labels.
for e in s.iter():
 if e.tag.endswith('text'):
  t=''.join(e.itertext()).strip()
  if t=='2.56':txt(e,f'{lo:.2f}')
  if t=='5.79':txt(e,f'{hi:.2f}')
X=lambda frame:3.37+39.8566666667*(int(frame)-856)/160
H=lambda height:46.26-11.25*height/20
Z=lambda val:71.96+(val-3.5)*8.17/5

def el(tag,**a):return E.SubElement(g,'{'+N+'}'+tag,{k.replace('_','-'):str(v) for k,v in a.items()})
def path(p,**a):return el('path',d='M'+' L'.join(f'{x:.5f},{y:.5f}' for x,y in p),**a)
for i in range(1,len(f)):
 if invalid[i-1] or invalid[i]:continue
 col='#bbbbbb'
 if np.isfinite(sm[i-1:i+1]).all():
  q=np.clip((np.mean(sm[i-1:i+1])-lo)/(hi-lo),0,1);col='#%02x%02x%02x'%(round(25+215*q),round(25*(1-q)),round(25*(1-q)))
 path([(X(f[i-1]),H(h[i-1])),(X(f[i]),H(h[i]))],fill='none',stroke=col,stroke_width='.46',stroke_linecap='round',stroke_linejoin='round')
score=0
for e in events:
 keep=(f>=int(e['StartOriginalFrame']))&(f<=int(e['EndOriginalFrame']));ff=f[keep];zz=z[keep];area=sum(np.maximum(zz-3.5,0));assert abs(area-float(e['EventScore']))<1e-8;score+=area
 p=[(X(ff[0]),Z(3.5))]+[(X(a),Z(max(3.5,b))) for a,b in zip(ff,zz)]+[(X(ff[-1]),Z(3.5))];e1=path(p,fill='#8b3fa0',fill_opacity='.22');e1.set('d',e1.get('d')+' Z')
seg=[]
for i in range(len(f)):
 if not invalid[i] and np.isfinite(z[i]):seg.append((X(f[i]),Z(z[i])))
 elif seg:path(seg,fill='none',stroke='#8b3fa0',stroke_width='.5',stroke_linejoin='round');seg=[]
if seg:path(seg,fill='none',stroke='#8b3fa0',stroke_width='.5',stroke_linejoin='round')
for e in events:el('ellipse',cx=X(e['PeakOriginalFrame']),cy=Z(float(e['NormalizedPeak'])),rx=1.5,ry=1.42,fill='#d464f9',stroke='black',stroke_width='.24')
for frame,label in [(1186,'a'),(1638,'b')]:
 i=np.flatnonzero(f==frame)[0];el('circle',cx=X(frame),cy=H(h[i]),r=1.4,fill='#d464f9',stroke='black',stroke_width='.24');el('text',x=X(frame)+2.5,y=H(h[i])+1.4,font_family='Arial',font_size=5).text=label
stem='TMCS2_S18_D0_T2_tail_traces_centroid3_height10';E.ElementTree(s).write(O/(stem+'.svg'),encoding='utf-8',xml_declaration=True)
with (O/(stem+'.csv')).open('w') as out:
 w=csv.writer(out);w.writerow(['OriginalFrame','SecondsSinceTraversalStart','MotionHeightMM','WholeMotionPerPixelTimes1000','SmoothedMotionForColor','NormalizedBelow','Invalid','Locomoting'])
 w.writerows(zip(f,(f-f[0])/160,h,motion,sm,z,invalid.astype(int),valid.astype(int)))
with (O/'example_accepted_events.csv').open('w') as out:
 w=csv.DictWriter(out,fieldnames=events[0]);w.writeheader();w.writerows(events)
meta=dict(file=name,frames=[856,1822],fps=160,mask='3x centroid; minwidth15',heightGateMM=10,eventCount=len(events),summedEventScore=score,colorLimits=[lo,hi],heightSmoothingFrames=5,colorSmoothingFrames=17,normalization='whole motion / geometrical crop area *1000; no height, speed or MAD scaling; locomotion-only color; stops gray',scatter=st)
(O/'figure_metadata.json').write_text(json.dumps(meta,indent=2));print(meta)
# Square rendering canvas for macOS QuickLook, without changing delivered layout.
s.set('viewBox','0 0 254.4 254.4');s.set('width','1800');s.set('height','1800');E.ElementTree(s).write(O/'trace_preview.svg')
