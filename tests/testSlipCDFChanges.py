"""Exploratory whole-curve tests of paired mouse CDF changes.
Exact cage-label permutations within cohort; integrated squared differences
on log10 score. Holm across three pairwise group tests.
"""
from pathlib import Path
from collections import defaultdict
import csv,json,itertools,runpy
import numpy as np
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS';cells=defaultdict(list)
meta={r['mouseID']:(r['cohort'],r['cageID'],r['group']) for r in csv.DictReader((R/'BEAMCROSS/DRAFTFIGS/analysis-data/pooled-exposures.csv').open())}
mouse=defaultdict(list)
for r in csv.DictReader((out/'slip_score_CDF_change_D14_minus_D0_paired_mouse_values.csv').open()):mouse[r['MouseID']].append((float(r['Score']),float(r['CDFChange'])))
xx=None
for m,rr in sorted(mouse.items()):
 a=np.array(rr);assert xx is None or np.array_equal(xx,a[:,0]);xx=a[:,0];cells[meta[m]].append(a[:,1])
# Right-continuous exact integration: F(x_i) applies until x_(i+1).
weights=np.diff(np.log10(xx));assert np.all(weights>0)
keys=sorted(cells);profiles=np.array([np.mean(cells[k],axis=0)[:-1] for k in keys]);assert np.all(np.isfinite(profiles))
results=[]
for A,B in [('walk','sedentary'),('run','sedentary'),('run','walk')]:
 nulls=[];obs=[];sizes={}
 for co in ('TMCS2','TMCS3'):
  ids=[i for i,k in enumerate(keys) if k[0]==co and k[2] in (A,B)];a=profiles[ids];labels=np.array([keys[i][2]==A for i in ids]);na=sum(labels)
  obs.append(a[labels].mean(axis=0)-a[~labels].mean(axis=0));per=[]
  for ix in itertools.combinations(range(len(ids)),na):
   mask=np.zeros(len(ids),bool);mask[list(ix)]=True;per.append(a[mask].mean(axis=0)-a[~mask].mean(axis=0))
  nulls.append(per);sizes[co]={A:int(na),B:int(len(ids)-na)}
 delta=np.mean(obs,axis=0);stat=float(np.sum(weights*delta**2));null=np.array([np.sum(weights*((a+b)/2)**2) for a in nulls[0] for b in nulls[1]])
 p=float(np.mean(null>=stat-1e-12));results.append(dict(comparison=A+' minus '+B,integrated_squared_difference=stat,p_raw=p,permutations=len(null),cages=sizes))
holm=runpy.run_path(str(R/'BEAMCROSS/DRAFTFIGS/tail-metrics/whole-motion-reweighted/cage_tests.py'))['holm']
for r,p in zip(results,holm([r['p_raw'] for r in results])):r['p_holm_3_pairs']=p
# Omnibus cohort-adjusted multivariate regression sum of squares integrated
# over log-score, extending the existing scalar cage test pointwise.
scores=[];obsu=np.zeros(profiles.shape[1]);obsv=obsu.copy();g00=g01=g11=0.
for co in ('TMCS2','TMCS3'):
 ids=[i for i,k in enumerate(keys) if k[0]==co];a=profiles[ids];a=a-a.mean(axis=0);labels=[keys[i][2] for i in ids];n=len(ids);nr=labels.count('run');nw=labels.count('walk');g00+=nr-nr*nr/n;g01-=nr*nw/n;g11+=nw-nw*nw/n
 obsu+=a[np.array(labels)=='run'].sum(axis=0);obsv+=a[np.array(labels)=='walk'].sum(axis=0);per=[]
 for rr in itertools.combinations(range(n),nr):
  rem=[i for i in range(n) if i not in rr]
  for ww in itertools.combinations(rem,nw):per.append((a[list(rr)].sum(axis=0),a[list(ww)].sum(axis=0)))
 scores.append(per)
det=g00*g11-g01*g01
stat=lambda u,v:np.sum(weights*(g11*u*u-2*g01*u*v+g00*v*v)/det,axis=-1)
observed=float(stat(obsu,obsv));ge=0;total=0
# Batch the small cohort to avoid allocating a large permutation tensor.
bu=np.array([x[0] for x in scores[1]]);bv=np.array([x[1] for x in scores[1]])
for u,v in scores[0]:
 z=stat(u+bu,v+bv);ge+=int(sum(z>=observed-1e-12));total+=len(z)
report=dict(analysis='Between-group comparison of D14−D0 CDF changes; not within-group tests',nMice=len(mouse),nCages=len(keys),omnibus=dict(statistic=observed,p_raw=ge/total,permutations=total),pairwise=results,method='Mean paired mouse CDF changes within cage; exact group-label permutations of whole cage curves within cohort. Pair statistic: integrated squared equal-cohort mean difference on log10 score. Omnibus: integrated cohort-adjusted group regression sum of squares. Exact integration over every empirical interval, without bins or smoothing. Holm over 3 pairwise comparisons.',limitations='Exploratory after viewing CDFs; assumes cage-label exchangeability within cohort. Equal cage weighting for inference differs from descriptive mouse-weighted curves. No correction across other outcomes or exploratory tests. No threshold-specific localization. Nonsignificance does not establish equivalence.',input='slip_score_CDF_change_D14_minus_D0_paired_mouse_values.csv',validation='42 mice, common exact score grid, all finite; tails have zero difference and contribute zero to integral.')
assert len(mouse)==42 and len(keys)==15
(out/'slip_score_CDF_change_whole_curve_statistics.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
