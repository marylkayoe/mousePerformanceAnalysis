"""User-approved3x mask,10mm gate; reselect saved candidates, no new tracking."""
from pathlib import Path
import csv,json,runpy,collections,statistics,math,re,copy,xml.etree.ElementTree as E
from bbSimpleSVG import Figure
R=Path(__file__).resolve().parents[1];B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS');I=B/'balance_beam_tail_centroid_boundary_20261113/factor3';O=B/'balance_beam_tail_centroid3_height10_20261113';O.mkdir(exist_ok=True)
read=lambda p:list(csv.DictReader(p.open()))
def write(p,rs):
 with p.open('w') as f:w=csv.DictWriter(f,fieldnames=rs[0]);w.writeheader();w.writerows(rs)
index={r['File']:r for r in read(R/'BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/trial-index.csv')};test=runpy.run_path(str(R/'BEAMCROSS/DRAFTFIGS/tail-metrics/whole-motion-reweighted/cage_tests.py'))['test']
metrics=[('LocomotingMean','Tail motion','0.001 a.u./pixel'),('MeanHeight','Motion height','mm above bar'),('CountHeightFiltered','Tail swing count','count'),('TotalScoreHeightFiltered','Tail swings','a.u. × frames')];cols={'sedentary':'#232323','walk':'#00b526','run':'#002bff'};allrows=[];stats=[];added=[]
N='http://www.w3.org/2000/svg';E.register_namespace('',N)
for stem in ['D0_first','D14_last']:
 day='D0' if stem=='D0_first' else 'D14';ss=read(I/(stem+'_summary.csv'));events=read(I/(stem+'_events.csv'));assert len(ss)==42
 for e in events:
  h=float(e['HeightAtPeakMM']);old=e['PassHeight'];e['PassHeight']=int(math.isfinite(h) and h<=10);e['HeightCutoffMM']=10
  if e['PassHeight'] and old=='0':added.append(e.copy())
 for r in ss:
  es=[e for e in events if e['File']==r['File'] and e['PassHeight']];r['CountHeightFiltered']=len(es);r['TotalScoreHeightFiltered']=sum(float(e['EventScore']) for e in es)
 write(O/(stem+'_summary.csv'),ss);write(O/(stem+'_events.csv'),events)
 fig=Figure(2,2,800,320);fig.text(25,25,day+' · 3× centroid mask, height ≤10 mm',20)
 tables={};tests={}
 for i,(metric,label,unit) in enumerate(metrics):
  rows=[]
  for r in ss:
   m=index[r['File']];rows.append(dict(file=r['File'],mouseID=m['MouseID'],cohort=m['Cohort'],cageID=m['CageID'],group=m['Group'],day=m['Day'],trialNumber=m['TrialNumber'],value=float(r[metric])))
  om,pairs=test(rows);st=dict(selection=stem,metric=metric,omnibus_p=om,pairs=pairs,nMice=42,nCages=15,means={g:statistics.mean(r['value'] for r in rows if r['group']==g) for g in cols});stats.append(st);tables[metric]=rows;tests[metric]=st;allrows.extend(dict(r,metric=metric,selection=stem) for r in rows)
  upper={'LocomotingMean':7.5,'MeanHeight':75,'CountHeightFiltered':3*math.ceil(max(r['value'] for r in rows)/3),'TotalScoreHeightFiltered':300*math.ceil(max(r['value'] for r in rows)/300)}[metric];ax=fig.axes[i//2][i%2];ax.setup((-.6,2.4),(0,upper),label+', '+day,unit,[0,1,2],['SED','WALK','RUN']);ax.p(om)
  for gi,g in enumerate(cols):
   rr=[r for r in rows if r['group']==g];n=len(rr)
   for j,r in enumerate(rr):ax.dot(gi+((j*7)%n/(n-1)-.5)*.3,r['value'],cols[g],opacity=.42)
   cells=collections.defaultdict(list)
   for r in rr:cells[r['cohort'],r['cageID']].append(r['value'])
   for v in cells.values():ax.dot(gi-.29,statistics.mean(v),cols[g],diamond=True)
   ax.line([gi-.17,gi+.17],[statistics.mean(r['value'] for r in rr)]*2,cols[g],2.5)
 fig.save(O/(stem+'_four_metrics.svg'))
 # Main-figure pair: preserve supplied marker/font geometry.
 s=E.parse(R/'tests/figure_templates/tail_scatter_D14_user.svg').getroot();s.set('viewBox','-4 0 168 94.19');groups=s.findall('{'+N+'}g')
 for col,metric in enumerate(['LocomotingMean','TotalScoreHeightFiltered']):
  title=('Tail motion' if col==0 else 'Tail swings')+', '+day;unit='0.001 a.u./pixel' if col==0 else 'a.u. × frames';rows=tables[metric];st=tests[metric];upper=7.5 if col==0 else 300*math.ceil(max(r['value'] for r in rows)/300);Y=lambda v:85.97-66.76*v/upper;g=groups[col];texts=g.findall('{'+N+'}text')
  def txt(e,v):
   for c in list(e):e.remove(c)
   e.text=v
  txt(texts[0],title);txt(texts[1],unit)
  for e,v in zip(texts[2:6],[0,upper/3,2*upper/3,upper]):
   txt(e,f'{v:g}');xy=re.findall(r'-?[\d.]+',e.get('transform'));e.set('transform',f'translate({5+85.82*col} {xy[1]})');e.set('text-anchor','end')
  txt(texts[6],f"p = {st['omnibus_p']:.3f}")
  for group,dc,pc,lc in [('sedentary','cls-7','cls-3','cls-9'),('walk','cls-12','cls-2','cls-11'),('run','cls-16','cls-1','cls-10')]:
   rr=[r for r in rows if r['group']==group];dots=[e for e in g if e.tag.endswith('circle') and e.get('class')==dc];assert len(dots)==len(rr)
   for e,r in zip(dots,rr):e.attrib.pop('transform',None);e.set('cy',str(Y(r['value'])))
   cells=collections.defaultdict(list)
   for r in rr:cells[r['cohort'],r['cageID']].append(r['value'])
   diamonds=[e for e in g if e.tag.endswith('polygon') and e.get('class')==pc];assert len(diamonds)==len(cells)
   for e,vs in zip(diamonds,cells.values()):
    pts=list(map(float,re.findall(r'-?[\d.]+',e.get('points'))));shift=Y(statistics.mean(vs))-pts[1];e.set('points',' '.join(f'{v+shift if i%2 else v:.5f}' for i,v in enumerate(pts)))
   line=next(e for e in g if e.tag.endswith('line') and e.get('class')==lc);y=Y(statistics.mean(r['value'] for r in rr));line.set('y1',str(y));line.set('y2',str(y))
 E.ElementTree(s).write(O/(stem+'_tail_motion_and_swings.svg'),encoding='utf-8',xml_declaration=True)
 s.set('viewBox','-4 0 168 168');s.set('width','1200');s.set('height','1200');E.ElementTree(s).write(O/(stem+'_preview.svg'))
 print(stem,'events',sum(r['CountHeightFiltered'] for r in ss),'score p',tests['TotalScoreHeightFiltered']['omnibus_p'],flush=True)
write(O/'mouse_values.csv',allrows);write(O/'additional_events.csv',added);assert len(added)==5
(O/'statistics.json').write_text(json.dumps(stats,indent=2))
(O/'README.md').write_text('3× centroid-height upper-body probability override;10mm peak-motion-height gate user accepted after review of all5 additional detections (examples2,6,7,8,11 in excluded_3x_review). Other current criteria unchanged: minwidth15,raw scalar mean5,median/1.4826MAD,z>3.5,closing5,min5frames; score=sum excess above3.5 over each accepted event, then sum events per crossing. No FPS division; include swings during stops. Whole motion=mean geometrical crop-area-normalized unweighted-in-height motion during locomotion (stop false,speed>=40px/s); display×1000. Height mean uses all valid frames. D0 first retained/D14 last retained:42mice,15cages each. Source factor3 measurements reused, no redecoding or retracking.\n\nOmnibus p in figures: existing exact cage permutations within cohort. Raw and Holm-three pairwise comparisons in statistics.json; no across-outcome correction. Exploratory data-informed detector changes. Mouse dots,cage diamonds,mouse-group means. Motion values/height unchanged from factor3; only swing acceptance/count/score updated. SVG units spelled0.001 to avoid Illustrator superscript problems. Original results and movies preserved; movies still show7.5mm until explicitly regenerated. Code tests/makeTailCentroid3Height10Scatters.py.\n')
