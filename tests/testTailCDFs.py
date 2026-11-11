"""Exact cohort-stratified cage tests of whole spatial speed/posture CDF changes.
Integrate squared curve differences over linear physical-unit thresholds.
"""
from pathlib import Path
import csv,json,itertools,runpy
import numpy as np
R=Path(__file__).resolve().parents[1];root=R/'BEAMCROSS/DRAFTFIGS'
meta={r['mouseID']:(r['cohort'],r['cageID'],r['group']) for r in csv.DictReader((root/'analysis-data/pooled-exposures.csv').open())}
holm=runpy.run_path(str(root/'tail-metrics/whole-motion-reweighted/cage_tests.py'))['holm']
def test(keys,profiles,weights):
 # Gram matrix preserves exact integral while avoiding large permutation arrays.
 G=(profiles*weights)@profiles.T;n=len(keys);results=[]
 norm=lambda c:np.einsum('...i,ij,...j->...',c,G,c)
 for A,B in [('walk','sedentary'),('run','sedentary'),('run','walk')]:
  per=[];observed=np.zeros(n)
  for co in ('TMCS2','TMCS3'):
   ids=[i for i,k in enumerate(keys) if k[0]==co and k[2] in (A,B)];aa=[i for i in ids if keys[i][2]==A];bb=[i for i in ids if keys[i][2]==B];observed[aa]=.5/len(aa);observed[bb]=-.5/len(bb);ps=[]
   for subset in itertools.combinations(ids,len(aa)):
    c=np.zeros(n);c[ids]=-.5/len(bb);c[list(subset)]=.5/len(aa);ps.append(c)
   per.append(ps)
  obs=float(norm(observed));null=norm(np.array([a+b for a in per[0] for b in per[1]]));p=float(np.mean(null>=obs-1e-10));results.append(dict(pair=A+' minus '+B,statistic=obs,p_raw=p,permutations=len(null)))
 for r,p in zip(results,holm([r['p_raw'] for r in results])):r['p_holm_3_pairs']=p
 perms=[];ou=np.zeros(n);ov=np.zeros(n);g00=g01=g11=0.
 for co in ('TMCS2','TMCS3'):
  ids=[i for i,k in enumerate(keys) if k[0]==co];nr=sum(keys[i][2]=='run' for i in ids);nw=sum(keys[i][2]=='walk' for i in ids);nc=len(ids);g00+=nr-nr*nr/nc;g01-=nr*nw/nc;g11+=nw-nw*nw/nc
  ou[ids]=-nr/nc;ov[ids]=-nw/nc
  for i in ids:
   ou[i]+=keys[i][2]=='run';ov[i]+=keys[i][2]=='walk'
  pp=[]
  for rr in itertools.combinations(ids,nr):
   rem=[i for i in ids if i not in rr]
   for ww in itertools.combinations(rem,nw):
    u=np.zeros(n);v=u.copy();u[ids]=-nr/nc;v[ids]=-nw/nc;u[list(rr)]+=1;v[list(ww)]+=1;pp.append((u,v))
  perms.append(pp)
 det=g00*g11-g01*g01
 stat=lambda u,v:(g11*norm(u)-2*g01*np.einsum('...i,ij,...j->...',u,G,v)+g00*norm(v))/det
 obs=float(stat(ou,ov));u=np.array([a[0]+b[0] for a in perms[0] for b in perms[1]]);v=np.array([a[1]+b[1] for a in perms[0] for b in perms[1]]);null=stat(u,v)
 return dict(overall_p=float(np.mean(null>=obs-1e-10)),overall_statistic=obs,overall_permutations=len(null),pairs=results)
out=root/'tail-metrics/CDF-D14-and-change'
trials=list(csv.DictReader((out/'trial-index.csv').open()));a=np.genfromtxt(out/'frame-values.csv',delimiter=',',names=True);reports={}
for metric,field in [('score','MotionScore'),('height','MotionHeightMM')]:
 vals=a[field];grid=np.unique(vals[np.isfinite(vals)])
 # Primary distance integrates over original physical/score units, as with speed.
 # Signed-log is a display transform only, not chosen to improve a test result.
 weights=np.diff(grid);mouseTrials={}
 for i,t in enumerate(trials,1):
  z=np.sort(vals[(a['TrialIndex']==i)&np.isfinite(vals)])
  if not len(z):continue
  mouseTrials.setdefault((t['MouseID'],t['Day']),[]).append(np.searchsorted(z,grid,side='right')/len(z))
 mouse={k:np.mean(v,axis=0) for k,v in mouseTrials.items()};ids=sorted({m for m,d in mouse if (m,'0') in mouse and (m,'14') in mouse});keys=sorted({meta[m] for m in ids});result={}
 for period in ('D14','D14-D0'):
  valsByMouse={m:mouse[m,'14']-(mouse[m,'0'] if period=='D14-D0' else 0) for m in ids}
  profiles=np.array([np.mean([valsByMouse[m] for m in ids if meta[m]==k],axis=0)[:-1] for k in keys]);result[period]=test(keys,profiles,weights)
 reports[metric]=dict(nMice=len(ids),nCages=len(keys),thresholds=len(grid),results=result)
 print(metric,json.dumps(result),flush=True)
 del mouseTrials,mouse,profiles,valsByMouse
report=dict(method='Exact whole-cage label permutations within cohort; mean per-frame crossing CDFs within mouse then cage means. Paired D14-D0 within mouse. Integrated squared curve differences on original linear score or mm scale, exact right-continuous empirical intervals. Signed-log score display is not the integration scale. Existing cohort-adjusted omnibus and equal-cohort pairwise contrasts; Holm across 3 pairs per metric/period.',limitations='Exploratory; assumes exchangeability of cage labels within cohort. No correction across measures or periods. Frames/crossings are not independent replicates. Nonsignificance does not establish equivalence.',results=reports)
(out/'whole_CDF_cage_statistics.json').write_text(json.dumps(report,indent=2))
