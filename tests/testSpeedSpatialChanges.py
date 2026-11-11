"""Exploratory exact cage-label permutations within cohort for spatial changes.
Two-sided maximum absolute cohort-balanced difference across all complete bins;
Bonferroni across three pairwise comparisons. No selected centre window.
"""
from pathlib import Path
import csv,json,itertools,hashlib
import numpy as np
R=Path(__file__).resolve().parents[1]; root=R/'BEAMCROSS/DRAFTFIGS';out=root/'speed-presentation/spatial-change-tests';out.mkdir(exist_ok=True)
p=root/'speed-presentation/speed-profile-source.json';src=json.loads(p.read_text());x=np.array(src['x']);distance=(max(x)-x)*700/1201
meta=list(csv.DictReader((root/'analysis-data/weighted-speed/speed-D14-minus-D0.csv').open()));lookup={(r['mouseID'],r['day']):r for r in src['traces']}
cages={};groups={}
for r in meta:
 k=(r['cohort'],r['cageID']);groups.setdefault(k,r['group']);assert groups[k]==r['group']
 a=np.array(lookup[r['mouseID'],'D14']['speedRelative'],float);b=np.array(lookup[r['mouseID'],'D00']['speedRelative'],float)
 cages.setdefault(k,[]).append((a-b)*700/1201)
# Require all constituent mice finite within cage for a bin to enter inference.
# Fixed complete-cage support makes coverage independent of permuted labels.
profiles={k:np.mean(v,axis=0) for k,v in cages.items()}
results=[];summary=[]
for ga,gb in [('run','sedentary'),('run','walk'),('walk','sedentary')]:
 cohorts=sorted({k[0] for k in cages});blocks=[];observed=[];keys=[]
 for co in cohorts:
  kk=sorted(k for k in cages if k[0]==co and groups[k] in (ga,gb));keys+=kk
  a=np.array([profiles[k] for k in kk]);labels=np.array([groups[k]==ga for k in kk]);na=sum(labels)
  observed.append(np.mean(a[labels],axis=0)-np.mean(a[~labels],axis=0))
  perms=[]
  for inds in itertools.combinations(range(len(kk)),na):
   mask=np.zeros(len(kk),bool);mask[list(inds)]=True
   perms.append(np.mean(a[mask],axis=0)-np.mean(a[~mask],axis=0))
  blocks.append(perms)
 good=np.all(np.isfinite(np.array([profiles[k] for k in keys])),axis=0)
 obs=np.mean(observed,axis=0);null=np.array([np.mean(pair,axis=0) for pair in itertools.product(*blocks)])
 assert np.all(np.isfinite(null[:,good]));mx=np.max(np.abs(null[:,good]),axis=1)
 pu=np.full(len(x),np.nan);pm=pu.copy();pf=pu.copy()
 for i in np.flatnonzero(good):
  pu[i]=np.mean(np.abs(null[:,i])>=abs(obs[i])-1e-10)
  pm[i]=np.mean(mx>=abs(obs[i])-1e-10);pf[i]=min(1,3*pm[i])
 for i in range(len(x)):
  results.append(dict(comparison=f'{ga} minus {gb}',camera_position_px=x[i],distance_from_entry_boundary_mm=distance[i],eligible=int(good[i]),difference_mm_s=obs[i],p_pointwise=pu[i],p_max_across_bins=pm[i],p_bins_and_three_pairs=pf[i],significant=int(good[i] and pf[i]<.05)))
 summary.append(dict(comparison=f'{ga} minus {gb}',permutations=len(null),eligibleBins=int(sum(good)),totalBins=len(x),minPointwiseP=float(np.nanmin(pu)),minSpatialAdjustedP=float(np.nanmin(pm)),minFamilyAdjustedP=float(np.nanmin(pf)),significantBins=int(sum(pf<.05)),cagesByCohort={co:{g:sum(k[0]==co and groups[k]==g for k in keys) for g in (ga,gb)} for co in cohorts}))
with (out/'binwise_tests.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(results[0]));w.writeheader();w.writerows(results)
(out/'summary.json').write_text(json.dumps(summary,indent=2))
notes='''# Exploratory spatial tests of speed change, D14−D0

Within each mouse, subtract saved D0 spatial speed from D14 at each identical bin; convert pixels/s to mm/s using 700/1201. Average mouse changes within cage. The statistic is the equally weighted mean of the two cohort-specific between-group cage-mean differences. Permute whole cage profiles between the two groups within cohort, preserving group cage counts; enumerate every allocation. Two-sided tests assume cage labels are exchangeable within cohort under the null. This does not establish that allocation was randomized.

Only bins with every contributing mouse finite in every cage of that comparison enter inference; missing values remain missing, without interpolation. The fixed support is unchanged under permutations. Profile graphics retain their existing mouse-mean/SEM display and coverage rule; the inference uses cage means and stricter support. Adjacent bins are not independent: each permutation retains the complete spatial profile.

At each bin, compare the absolute observed difference to the permutation maximum absolute difference over all eligible bins. This controls the spatial family under the exchangeability null; multiply those p-values by three (capped at one) to also correct across the three group comparisons. Alpha 0.05, two-sided; no cluster threshold, selected centre window, new smoothing, or choice of test based on its result. Raw pointwise p-values are diagnostic, not significance annotations. This maximum-difference statistic is unstudentized and therefore may be conservative where variance is smaller.

The question is whether groups differ in D14−D0 change, not whether one group changes from zero or is faster in absolute terms at D14. Analysis is exploratory, prompted by inspecting the profiles. Small cage numbers give coarse exact p-values. No significant bin is not evidence of equivalence. No inference identifies a precisely bounded biological centre region.

Reproduce: `tests/testSpeedSpatialChanges.py` (Python with NumPy). Source `speed-profile-source.json` from saved speed-absolute-position-data.mat; cage/group metadata from weighted-speed/speed-D14-minus-D0.csv. Original measurements unchanged.
'''
for r in summary:notes+=f"\n- {r['comparison']}: {r['permutations']} allocations; {r['eligibleBins']}/{r['totalBins']} bins eligible; min raw p={r['minPointwiseP']:.6g}; min spatial-corrected p={r['minSpatialAdjustedP']:.6g}; min spatial+three-pair p={r['minFamilyAdjustedP']:.6g}; {r['significantBins']} significant bins.\n"
(out/'README.md').write_text(notes)
print(json.dumps(summary,indent=2))
