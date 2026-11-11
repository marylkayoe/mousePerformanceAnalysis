"""Sensitivity analysis: ignoring cage clustering, retaining cohort stratification."""
from pathlib import Path
import csv,json,runpy
import numpy as np
R=Path(__file__).resolve().parents[1];root=R/'BEAMCROSS/DRAFTFIGS';out=root/'SLIPS&STOPS';ct=runpy.run_path(str(root/'tail-metrics/whole-motion-reweighted/cage_tests.py'));rng=np.random.default_rng(20261111);N=100000
read=lambda p:list(csv.DictReader(p.open()))
def mouse_test(rows):
 strata=[];g00=g01=g11=0.;ou=ov=0.
 for co in ('TMCS2','TMCS3'):
  rr=[r for r in rows if r['cohort']==co];y=np.array([r['value'] for r in rr]);lab=np.array([r['group'] for r in rr]);yc=y-y.mean();nr=sum(lab=='run');nw=sum(lab=='walk');n=len(y);g00+=nr-nr*nr/n;g01-=nr*nw/n;g11+=nw-nw*nw/n;ou+=sum(yc[lab=='run']);ov+=sum(yc[lab=='walk']);strata.append((y,lab,yc,nr,nw))
 det=g00*g11-g01*g01
 stat=lambda u,v:(g11*u*u-2*g01*u*v+g00*v*v)/det
 observed=stat(ou,ov);ge=0
 for start in range(0,N,2000):
  size=min(2000,N-start);u=np.zeros(size);v=u.copy()
  for y,lab,yc,nr,nw in strata:
   shuffled=rng.permuted(np.broadcast_to(yc,(size,len(yc))),axis=1);u+=shuffled[:,:nr].sum(axis=1);v+=shuffled[:,nr:nr+nw].sum(axis=1)
  ge+=sum(stat(u,v)>=observed-1e-10)
 overall=(ge+1)/(N+1);pairs=[]
 for A,B in [('walk','sedentary'),('run','sedentary'),('run','walk')]:
  sub=[];obs=[]
  for y,lab,*_ in strata:
   keep=(lab==A)|(lab==B);z=y[keep];na=sum(lab==A);sub.append((z,na));obs.append(y[lab==A].mean()-y[lab==B].mean())
  diff=np.mean(obs);ge=0
  for start in range(0,N,2000):
   size=min(2000,N-start);null=np.zeros(size)
   for z,na in sub:
    a=rng.permuted(np.broadcast_to(z,(size,len(z))),axis=1);null+=(a[:,:na].mean(axis=1)-a[:,na:].mean(axis=1))/2
   ge+=sum(abs(null)>=abs(diff)-1e-10)
  pairs.append(dict(pair=A+' minus '+B,p_raw=(ge+1)/(N+1)))
 for r,p in zip(pairs,ct['holm']([r['p_raw'] for r in pairs])):r['p_holm']=p
 return overall,pairs
results=[]
for metric,field in [('Slip count','combinedSlips'),('Total slip score','combinedSlipMagnitude'),('Stop count','combinedStops'),('Time stopped (%)','value')]:
 rows=read(out/'stop-time-percentage/mouse-day-values.csv') if field=='value' else [r for r in read(root/'analysis-data/pooled-exposures.csv') if int(r['nRuns'])==3]
 for r in rows:r['value']=float(r[field])
 lookup={(r['mouseID'],r['day']):r for r in rows}
 for period in ('D14','D14-D0'):
  ds=[dict(r) for r in rows if r['day']=='D14' and (period=='D14' or (r['mouseID'],'D00') in lookup)]
  if period!='D14':
   for r in ds:r['value']-=lookup[r['mouseID'],'D00']['value']
  om,mp=mouse_test(ds);oc,cp=ct['test'](ds)
  for a,b in zip(mp,cp):
   assert a['pair']==b['pair'];results.append(dict(metric=metric,period=period,nMice=len(ds),pair=a['pair'],mouseOverall=om,cageOverall=oc,mouseRaw=a['p_raw'],mouseHolm=a['p_holm'],cageRaw=b['p_raw'],cageHolm=b['p_holm_3_pairs']))
with (out/'mouse_only_vs_cage_slip_stop_statistics.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(results[0]));w.writeheader();w.writerows(results)
(out/'mouse_only_vs_cage_slip_stop_statistics.json').write_text(json.dumps(dict(seed=20261111,permutations=N,method='Mouse-only: mean-based cohort-adjusted omnibus and equal-cohort pair differences; permute individual mouse labels within cohort. Cage analysis: existing exact cage permutations. Both use identical rows and Holm adjustment across three pairs per metric/period. D14−D0 formed within mouse first.',warning='Exploratory sensitivity only: mouse permutations ignore shared-cage dependence and are not a valid replacement for cage-aware inference. Allocation exchangeability remains an assumption. Not necessarily the same as historical mouse-only tests. No correction across metrics or periods.',results=results),indent=2))
for r in results:print(r['metric'],r['period'],r['pair'],round(r['mouseOverall'],4),round(r['mouseHolm'],4),round(r['cageHolm'],4))
