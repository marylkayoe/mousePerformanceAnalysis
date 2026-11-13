from pathlib import Path
import csv,json,collections,statistics,math
R=Path(__file__).resolve().parents[1];rows=list(csv.DictReader((R/'BEAMCROSS/DRAFTFIGS/within-session-diagnostics-20261112/trial_values.csv').open()));metrics=['speed','stopped','slip_count','slip_score'];result={}
for group in ['sedentary','run','walk']:
 rr=[r for r in rows if r['Group']==group and r['Day']=='14'];by=collections.defaultdict(list)
 for r in rr:by[r['MouseID']].append(r)
 means={mouse:{k:statistics.mean(float(r[k]) for r in rs) for k in metrics} for mouse,rs in by.items()};med={k:statistics.median(v[k] for v in means.values()) for k in metrics};scale={k:max(statistics.median(abs(v[k]-med[k]) for v in means.values()),1e-6) for k in metrics}
 ranked=[]
 for mouse,v in means.items():
  dist=sum(abs(v[k]-med[k])/scale[k] for k in metrics)/len(metrics)
  trials=sorted(by[mouse],key=lambda r:sum(abs(float(r[k])-v[k])/scale[k] for k in metrics))
  ranked.append(dict(mouse=mouse,distance=dist,means=v,trials=trials,D0=[r for r in rows if r['MouseID']==mouse and r['Day']=='0']))
 ranked.sort(key=lambda r:r['distance']);result[group]=dict(groupMouseMedian=med,ranking=ranked)
 print(group,'median',med)
 for x in ranked[:4]:print(x['mouse'],round(x['distance'],2),[(r['TrialNumber'],r['slip_count'],round(float(r['speed']))) for r in x['trials']])
(R/'BEAMCROSS/DRAFTFIGS/slip-movie-example-review/group_example_shortlist.json').write_text(json.dumps(result,indent=2))
