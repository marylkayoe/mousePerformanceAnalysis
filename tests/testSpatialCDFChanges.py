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
for metric,folder,source,field in [('speed','speed-presentation','speed-profile-source.json','trialSpeedRelative'),('posture','posture-presentation','posture-profile-source.json','trialHeight')]:
 out=root/folder;s=json.loads((out/source).read_text());records=[r for r in s['traces'] if r['day'] in ('D00','D14')];pos=np.array(s['x']);arrays=[np.array(r[field],float) for r in records];support=np.all(np.isfinite(np.concatenate(arrays)),axis=0)&(pos>=42)&(pos<=1243);grid=np.unique(np.concatenate([a[:,support].ravel()*700/1201 for a in arrays]));weights=np.diff(grid);mouse={}
 for r,a in zip(records,arrays):
  assert a.shape[0]==len(r['trialNumbers']);curves=[np.searchsorted(np.sort(v[support]*700/1201),grid,side='right')/sum(support) for v in a];mouse[r['mouseID'],r['day']]=np.mean(curves,axis=0)
 ids=sorted({m for m,day in mouse});keys=sorted({meta[m] for m in ids});reports={}
 for period in ('D14','D14-D0'):
  vals={m:mouse[m,'D14']-(mouse[m,'D00'] if period=='D14-D0' else 0) for m in ids};profiles=np.array([np.mean([vals[m] for m in ids if meta[m]==k],axis=0)[:-1] for k in keys]);assert np.all(np.isfinite(profiles))
  # Check Gram integration against direct integration for a fixed contrast.
  c=np.arange(len(keys),dtype=float);c-=c.mean();assert np.isclose(c@((profiles*weights)@profiles.T)@c,np.sum(weights*(c@profiles)**2),rtol=1e-9)
  reports[period]=test(keys,profiles,weights)
 report=dict(metric=metric,source=source,commonBins=int(sum(support)),cameraBinCenters=pos[support].tolist(),excludedWithinTapeBins=pos[(pos>=42)&(pos<=1243)&~support].tolist(),mice=len(ids),cages=len(keys),results=reports,method='Spatial-bin mean values; equal positions within crossing, equal crossing ECDFs within mouse, paired D14-D0 within mouse. Average curves within cage. Exact whole-cage group-label permutations within cohort. Integrated squared differences on linear physical-unit axis, exact right-continuous integration. Equal-cohort pairwise contrasts; cohort-adjusted regression omnibus. Holm over three pairs within each metric/period.',limitations='Exploratory after viewing data. Assumes exchangeable cage assignments within cohort; not ensured by design. No correction across outcomes or periods; D14-D0 is primary question, D14 secondary. CDFs discard spatial location; bins and frames are not replicates. Complete-position support is outcome-specific. Descriptive plots weight mice equally whereas tests weight cages.')
 (out/(metric+'_spatial_CDF_cage_statistics.json')).write_text(json.dumps(report,indent=2));print(metric,'bins',sum(support),json.dumps(reports))
