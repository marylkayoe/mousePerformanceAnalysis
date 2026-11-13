from pathlib import Path
import csv,json,runpy,statistics,collections,math,re,copy,sys,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];D=R/'BEAMCROSS/DRAFTFIGS';O=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_MAD3p5_height7p5_results_20261112')
I=O
literal='--literal-trial1' in sys.argv
if literal:O=O/'literal_trial1';O.mkdir(exist_ok=True)
read=lambda p:list(csv.DictReader(p.open()));manifest={r['File']:r for r in read(D/'tail-metrics/CDF-D14-and-change/trial-index.csv')}
test=runpy.run_path(str(D/'tail-metrics/whole-motion-reweighted/cage_tests.py'))['test'];ns={'s':'http://www.w3.org/2000/svg'};ET.register_namespace('',ns['s']);combined=ET.Element('{'+ns['s']+'}svg',{'viewBox':'0 0 156.02 94.19'});allrows=[];stats=[]
for panel,stem in enumerate(['D0_first','D14_last']):
 rows=[]
 for q in read(I/(stem+'_peak_counts.csv')):
  m=manifest[q['File']];v=float(q['PeakCount']);assert math.isfinite(v)
  rows.append(dict(file=q['File'],mouseID=m['MouseID'],cohort=m['Cohort'],cageID=m['CageID'],group=m['Group'],day=m['Day'],trialNumber=m['TrialNumber'],value=v,validSeconds=float(q['JointValidSeconds']),rawThreshold=float(q['RawProminenceThreshold'])))
 if literal and panel==0:rows=[r for r in rows if r['trialNumber']=='1']
 om,pairs=test(rows);means={g:statistics.mean(r['value'] for r in rows if r['group']==g) for g in ['sedentary','walk','run']};stats.append(dict(selection=stem,omnibus_p=om,pairs=pairs,means=means,nMice=len(rows),nCages=len({r['cageID'] for r in rows})));allrows+=rows
 root=ET.parse(R/'tests/figure_templates/tail_candidate_scatter_reference.svg').getroot();texts=root.findall('.//s:text',ns)
 def txt(e,v):
  for c in list(e):e.remove(c)
  e.text=v
 txt(texts[0], 'Tail slips, D0' if panel==0 else 'Tail slips, D14');txt(texts[6],f'p = {om:.3f}');texts[6].set('transform','translate(70 17.31)');texts[6].set('text-anchor','end')
 upper=max(3,3*math.ceil(max(r['value'] for r in rows)/3));Y=lambda v:85.97-66.76*v/upper
 for e,v in zip(texts[2:6],[0,upper/3,2*upper/3,upper]):txt(e,f'{v:g}')
 for g,dc,pc,lc in [('sedentary','cls-7','cls-3','cls-9'),('walk','cls-12','cls-2','cls-11'),('run','cls-16','cls-1','cls-10')]:
  rr=[r for r in rows if r['group']==g];dots=[e for e in root.findall('.//s:circle',ns) if e.get('class')==dc];parents={c:p for p in root.iter() for c in p}
  for e in dots[len(rr):]:parents[e].remove(e)
  dots=dots[:len(rr)]
  for e,r in zip(dots,rr):e.set('cy',str(Y(r['value'])))
  cells=collections.defaultdict(list)
  for r in rr:cells[r['cohort'],r['cageID']].append(r['value'])
  diamonds=[e for e in root.findall('.//s:polygon',ns) if e.get('class')==pc];assert len(diamonds)==len(cells)
  for e,values in zip(diamonds,cells.values()):
   coords=list(map(float,re.findall(r'-?[0-9.]+',e.get('points'))));x=coords[2];y=Y(statistics.mean(values));e.set('points',f'{x-1.525},{y} {x},{y-1.905} {x+1.525},{y} {x},{y+1.905}')
  line=next(e for e in root.findall('.//s:line',ns) if e.get('class')==lc);line.set('y1',str(Y(means[g])));line.set('y2',str(Y(means[g])))
 ET.ElementTree(root).write(O/(stem+'_tail_slips.svg'),encoding='utf-8',xml_declaration=True)
 root.set('x',str(panel*83.01));root.set('y','0');root.set('width','73.01');root.set('height','94.19');combined.append(root)
 print(stem,'omnibus',om,'means',means,'max',max(r['value'] for r in rows),'trials',collections.Counter(r['trialNumber'] for r in rows),flush=True)
 print(pairs,flush=True)
ET.ElementTree(combined).write(O/'D0_first_D14_last_tail_slips.svg',encoding='utf-8',xml_declaration=True)
(O/'statistics.json').write_text(json.dumps(stats,indent=2))
with (O/'mouse_values.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=allrows[0]);w.writeheader();w.writerows(allrows)
