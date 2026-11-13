"""Paired D14-last minus D0-last, four aligned behavior scatter panels."""
from pathlib import Path
from collections import defaultdict
import csv,json,statistics,math,runpy
R=Path(__file__).resolve().parents[1];D=R/'BEAMCROSS/DRAFTFIGS';O=D/'last-crossing-paired-20261112/aligned-four-D14';O.mkdir(exist_ok=True)
csv.field_size_limit(10000000)
m=list(csv.DictReader((D/'analysis-data/trial_manifest.csv').open()));assets={r['fileName']:r for r in csv.DictReader((R/'assets/Tara-BB-trial-data.csv').open())};selection={}
for r in m:
 if r['Day'] not in ['0','14']:continue
 k=(r['MouseID'],r['Day'])
 if k not in selection or int(r['TrialNumber'])>int(selection[k]['TrialNumber']):selection[k]=r
mice=sorted(set(k[0] for k in selection));assert len(mice)==42
cached={(r['MouseID'],r['Metric']):r for r in csv.DictReader((D/'last-crossing-paired-20261112/mouse_values.csv').open())}
S=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 328 94">','<rect width="100%" height="100%" fill="white"/>'];colors=['#232323','#008d3f','#0864cf'];pale=['#a7a7a7','#99d1b2','#9cc1ec'];values=[];stats=[]
def text(x,y,s,size=5,anchor='start'):S.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="#232323">{s}</text>')
def line(p,c='#262626',w=.4):S.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in p)+f'" fill="none" stroke="{c}" stroke-width="{w}" stroke-linejoin="round"/>')
configs=[('speed','Speed, D14','mm/s',50,1),('slip_count','Slip count, D14','count',5,1),('slip_score','Total slip score, D14','10³ a.u. × frames',1,.001),('time_stopped','Time stopped, D14','%',10,1)]
for k,(key,title,unit,step,scale) in enumerate(configs):
 rr=[]
 for mouse in mice:
  a=selection[mouse,'0'];b=selection[mouse,'14'];assert all(a[c]==b[c] for c in ['Group','CageID','Cohort'])
  def val(t):
   x=assets[t['File']]
   if key=='speed':return float(x['meanSpeedLoco'])*700/1201
   if key=='slip_count':return float(x['nSlips'])
   if key=='slip_score':return float(x['totalSlipMagnitude'])
   return 100*int(t['CorrectStoppedFrames'])/int(t['Frames'])
  v0,v14=val(a),val(b);delta=v14-v0;assert math.isfinite(delta)
  c=cached[mouse,key];assert c['D0File']==a['File'] and c['D14File']==b['File'];assert math.isclose(delta,float(c['Change']),abs_tol=1e-7,rel_tol=1e-7)
  rr.append(dict(metric=key,mouseID=mouse,cohort=a['Cohort'],cageID=a['CageID'],group=a['Group'],D0File=a['File'],D14File=b['File'],D0Trial=a['TrialNumber'],D14Trial=b['TrialNumber'],D0=v0,D14=v14,value=v14))
 om,pairs=runpy.run_path(str(D/'tail-metrics/whole-motion-reweighted/cage_tests.py'))['test'](rr);stats.append(dict(metric=key,omnibus_p=om,pairs=pairs,nMice=len(rr),nCages=15));values+=rr
 vv=[r['value']*scale for r in rr];lo=0;hi=max(step,step*math.ceil(max(vv)/step));hi+=step*.15 # room for p label without clipping points
 L=16+k*79;T=18;B=76;Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
 text(L-2,7,title,5.3);text(L,14,unit,3.6);line([(L,T),(L,B)]);line([(L,Y(0)),(L+63,Y(0))],'#bbbbbb',.35)
 for i in range(round(lo/step),math.floor(hi/step)+1):v=i*step;line([(L,Y(v)),(L+1,Y(v))]);text(L-2,Y(v)+1.7,f'{v:g}'.replace('-','−'),5,'end')
 text(L+62,T+5,f'p = {om:.3f}',4.4,'end')
 for j,g in enumerate(['sedentary','walk','run']):
  rs=[r for r in rr if r['group']==g];cx=L+13+j*22.5;cells=defaultdict(list)
  for i,r in enumerate(rs):
   v=r['value']*scale;x=cx-4.7+9.4*i/max(1,len(rs)-1);y=Y(v);S.append(f'<circle cx="{x}" cy="{y}" r="1.1" fill="{pale[j]}"/>');cells[r['cohort'],r['cageID']].append(v)
  for vs in cells.values():
   x=cx-8;y=Y(statistics.mean(vs));S.append(f'<polygon points="{x-1.35},{y} {x},{y-1.7} {x+1.35},{y} {x},{y+1.7}" fill="{colors[j]}" stroke="#231f20" stroke-width=".13"/>')
  y=Y(statistics.mean(r['value']*scale for r in rs));line([(cx-5,y),(cx+5,y)],colors[j],.9);text(cx,B+6,['SED','WALK','RUN'][j],5,'middle')
 print(key,om,lo,hi)
text(16,91,'D14 last retained crossing · mouse dots, cage diamonds · cage-aware group comparisons',3.4);S.append('</svg>');(O/'D14_last_four_metrics.svg').write_text('\n'.join(S))
with (O/'paired_mouse_values.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(values[0]));w.writeheader();w.writerows(values)
(O/'statistics.json').write_text(json.dumps(stats,indent=2))
reference={r['metric']:r for r in json.loads((D/'last-crossing-D14/statistics.json').read_text())}
for r in stats:assert math.isclose(r['omnibus_p'],reference[r['metric']]['overall_p'],abs_tol=1e-12)
(O/'README.md').write_text("""# D14 last retained: four absolute-value panels

D14 ONLY, no D0 subtraction or adjustment.42mice/15cages; highest retained original trial number per mouse. Same four outcomes/data as earlier nine-panel D14 overview. Raw omnibus exact cage-label permutation within cohort via cage_tests.py. All four p-values independently match earlier last-crossing-D14/statistics.json to1e-12. Exploratory/no across-outcome adjustment. Test assumptions unchanged. Individual values from assets plus validated manifest (stopped percentage), full filenames retained in table. The table also preserves D0 for provenance but plotted/tested value is D14 alone. Total slip score displayed /1000. Aligned axes/fonts/circular markers,zero baseline,no clipping. Original difference panels preserved. Reproduce tests/plotD14LastFourAbsolute.py.
""")
