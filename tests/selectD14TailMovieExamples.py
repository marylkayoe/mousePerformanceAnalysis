"""D14 tail-example shortlist, daily-mean proximity; no outcome recomputation."""
from pathlib import Path
import csv,json,statistics as st,collections
R=Path(__file__).resolve().parents[1];T=R/'BEAMCROSS/DRAFTFIGS/tail-metrics'
read=lambda p:list(csv.DictReader(p.open()))
heights={r['file']:r for r in read(T/'height-exploratory/trial-motion-height.csv')}
rows=[]
for r in read(T/'whole-motion-reweighted/trial-values.csv'):
 h=heights[r['file']]
 rows.append(dict(file=r['file'],mouse=r['mouseID'],group=r['group'],day=r['day'],trial=int(r['trialNumber']),score=float(r['sumLegacy'])/float(r['nLegacy']),height=float(h['medianHeight']),valid=float(h['validFraction'])))
metrics=['score','height'];result={}
for g in ['sedentary','walk','run']:
 by=collections.defaultdict(list)
 for r in rows:
  if r['group']==g and r['day']=='D14':by[r['mouse']].append(r)
 means={m:{k:st.mean(r[k] for r in rr) for k in metrics} for m,rr in by.items()}
 med={k:st.median(v[k] for v in means.values()) for k in metrics}
 scale={k:max(st.median(abs(v[k]-med[k]) for v in means.values()),1e-9) for k in metrics}
 ranks=[]
 for m,v in means.items():
  distance=sum(abs(v[k]-med[k])/scale[k] for k in metrics)/2
  trialrank=sorted(by[m],key=lambda r:sum(abs(r[k]-v[k])/scale[k] for k in metrics))
  ranks.append(dict(mouse=m,distance=distance,dailyMean=v,trials=trialrank,D0=sorted([r for r in rows if r['mouse']==m and r['day']=='D00'],key=lambda r:r['trial'])))
 ranks.sort(key=lambda r:r['distance'])
 result[g]=dict(groupMedianMouseMean=med,groupMAD=scale,ranking=ranks)
 print(g,'group medians',med)
 for x in ranks[:4]:print(x['mouse'],round(x['distance'],2),[(r['trial'],round(r['score'],3),round(r['height'],1),round(r['valid'],2)) for r in x['trials']])
 for m in ['TMCS3_S07','TMCS2_S20','TMCS3_S12','TMCS3_S09','TMCS3_S04','TMCS2_S18']:
  if m in means:print('Existing',m,means[m],[(r['trial'],round(r['score'],3),round(r['height'],1),round(r['valid'],2)) for r in by[m]])
out=R/'BEAMCROSS/DRAFTFIGS/slip-movie-example-review/D14_tail_example_shortlist.json'
out.write_text(json.dumps(result,indent=2))
