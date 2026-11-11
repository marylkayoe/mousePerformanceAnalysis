"""Exploratory equality-versus-order tests, baseline/cohort adjusted cage means.

Two-dimensional cone solved by enumerating its interior, rays and vertex.
Gaussian Monte Carlo calibrates finite-sample null conditional on fixed design.
Exhaustive null-residual wild signs provide a heteroscedasticity sensitivity,
not an exact randomization test. No independence of mice is assumed.
"""
from pathlib import Path
import csv,json
import numpy as np

ROOT=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/outcome-specific-contrasts/ANCOVA'
OUT=ROOT/'ordered-trend';OUT.mkdir(exist_ok=True)
N=200000;SEED=20261111
rows=list(csv.DictReader((ROOT/'cage_inputs.csv').open()))
spec=[('speed',1),('time_stopped',-1),('slip_count',-1),('tail_score',-1)]

def setup(Z,G):
    q=np.linalg.qr(Z)[0];M=np.eye(len(Z))-q@q.T;A=M@G;H=A.T@A;inv=np.linalg.inv(H)
    return M,A,H,inv

def statistics(Y,M,A,H,inv,df):
    # Columns are response replicates, already oriented so increasing is predicted.
    E=M@Y;v=A.T@E;b=inv@v;sse0=np.sum(E*E,axis=0)
    free=np.sum(v*b,axis=0);ssefree=np.maximum(sse0-free,1e-20)
    feasible=(b[0]>=0)&(b[1]>=b[0])
    interior=np.where(feasible,free,0.)
    # boundary SED=WALK <= RUN; boundary SED <= WALK=RUN.
    ray1=np.maximum(v[1],0)**2/H[1,1]
    ray2=np.maximum(v.sum(axis=0),0)**2/H.sum()
    gain=np.maximum.reduce([np.zeros(Y.shape[1]),interior,ray1,ray2])
    return gain/(ssefree/df),b,np.stack([np.zeros_like(gain),interior,ray1,ray2])

results=[]
for j,(key,sign) in enumerate(spec):
    rs=[r for r in rows if r['metric']==key];n=len(rs);assert n==15
    x=np.array([float(r['D0']) for r in rs]);y=np.array([float(r['D14']) for r in rs])*sign
    Z=np.column_stack([np.ones(n),[r['cohort']=='TMCS3' for r in rs],(x-x.mean())/x.std()])
    G=np.column_stack([[r['group']=='walk' for r in rs],[r['group']=='run' for r in rs]]).astype(float)
    M,A,H,inv=setup(Z,G);df=n-5
    obs,b,candidates=statistics(y[:,None],M,A,H,inv,df);reverse,_,_=statistics(-y[:,None],M,A,H,inv,df)
    obs=float(obs[0]);both=max(obs,float(reverse[0]));rng=np.random.default_rng(SEED+j)
    exceed=exceed_both=0
    for start in range(0,N,5000):
        Y=rng.normal(size=(n,min(5000,N-start)))
        null,_,_=statistics(Y,M,A,H,inv,df);rev,_,_=statistics(-Y,M,A,H,inv,df)
        exceed+=int(np.sum(null>=obs-1e-12));exceed_both+=int(np.sum(np.maximum(null,rev)>=both-1e-12))
    p=(exceed+1)/(N+1);p2=(exceed_both+1)/(N+1)
    # Restricted-null HC2 residual wild bootstrap, all 2^15 Rademacher patterns.
    fit0=y-M@y;e=M@y;h0=1-np.diag(M);adjust=e/np.sqrt(1-h0)
    signs=2*((np.arange(2**n,dtype=np.uint32)[None,:]>>np.arange(n,dtype=np.uint32)[:,None])&1).astype(float)-1
    wy=fit0[:,None]+adjust[:,None]*signs
    wt,_,_=statistics(wy,M,A,H,inv,df);wr,_,_=statistics(-wy,M,A,H,inv,df)
    wild=float(np.mean(wt>=obs-1e-12));wild2=float(np.mean(np.maximum(wt,wr)>=both-1e-12))
    face=int(np.argmax(candidates[:,0]));v=A.T@(M@y)
    beta=[np.zeros(2),b[:,0],np.array([0,max(v[1],0)/H[1,1]]),np.repeat(max(v.sum(),0)/H.sum(),2)][face]
    # Numerical verification: cone feasible, improves null, cannot beat unrestricted.
    assert beta[0]>=-1e-10 and beta[1]>=beta[0]-1e-10
    gain=2*beta@v-beta@H@beta
    assert abs(gain-max(candidates[:,0]))<1e-7*max(1,gain)
    assert gain<=v@inv@v+1e-7*max(1,gain)
    # Invariance to nuisance additions and positive scale.
    check=statistics((2*y+Z@np.array([2.,3.,4.]))[:,None],M,A,H,inv,df)[0][0]
    assert np.isclose(obs,check,rtol=1e-9,atol=1e-9)
    results.append(dict(metric=key,direction='increasing' if sign==1 else 'decreasing',n_cages=n,df=df,
        statistic=obs,gaussian_directional_p=p,monte_carlo_se=float(np.sqrt(p*(1-p)/(N+1))),
        wild_directional_p=wild,gaussian_either_direction_p=p2,wild_either_direction_p=wild2,
        adjusted_WALK_minus_SED=float(sign*beta[0]),adjusted_RUN_minus_SED=float(sign*beta[1]),
        constraint_face=['all_equal','strict_order','SED_equals_WALK','WALK_equals_RUN'][face],
        gaussian_replicates=N,wild_sign_patterns=2**n,seed=SEED+j))

(OUT/'results.json').write_text(json.dumps(results,indent=2))
with (OUT/'results.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(results[0]));w.writeheader();w.writerows(results)
report='''# Exploratory ordered-trend ANCOVA — 2026-11-11

## Question

Null: equal adjusted SED, WALK and RUN means. Alternative: SED ≤ WALK ≤ RUN for speed, or SED ≥ WALK ≥ RUN for stopped percentage, slip count and tail-motion score, with at least one inequality strict. Unequal steps and plateaus are allowed. A positive result does NOT establish RUN differs from WALK, nor prove both steps nonzero. Other outcomes were not assigned arbitrary directions after failing to show an ordered pattern. Both these four outcomes and their directions were selected after examining data; the analysis is exploratory, not confirmatory.

## Model and calibration

Uses the same 15 cage inputs as ../cage_inputs.csv. Independent cage means with additive cohort effect, common linear baseline slope and common group effects across cohorts. No mouse-level independence assumption. Two group coefficients are constrained to an order cone. Exact least-squares solution enumerates interior, both rays and all-equal vertex; nuisance intercept/cohort/D0 terms are projected out. No 0/1/2 dose or equal-spacing assumption. Test statistic is improvement over the equal-group null divided by unrestricted residual variance (10 df). No ordinary chi-square or ordinary regression p-value is substituted for the constrained distribution.

200,000 standard-normal response simulations conditional on each fixed design calibrate the null. The statistic is invariant to nuisance fitted means and common scale, so this Gaussian Monte Carlo calibration requires no estimated null nuisance parameters. It is a finite-sample model calibration under independent homoscedastic Gaussian cage errors, not a randomization test and not a guarantee when errors are heterogeneous. Add-one Monte Carlo p-values and their simulation SEs are saved. Numerical checks verify cone feasibility, objective ordering and nuisance/scale invariance.

Sensitivity: fit the equal-group null, adjust residuals by sqrt(1-null leverage), multiply each cage residual by a Rademacher sign, and refit the statistic for all 32,768 sign patterns. This exhaustive *wild-bootstrap* calculation is still approximate (residuals are estimated), not an exact permutation/randomization p-value. Few cages and influential observations limit its reliability. It addresses unequal variability imperfectly and does not repair allocation confounding.

Because directions were data-informed, an additional calibration uses the maximum statistic over increasing and decreasing cones for both observed and simulated data. This either-direction sensitivity accounts for choosing direction between these two cones, but NOT selection of four outcomes, exploratory metric changes, or all prior analyses. All p-values are per outcome; no across-outcome correction is claimed.

## Results

| Outcome | Direction | Directional Gaussian p | Directional wild sensitivity p | Either-direction Gaussian p | Either-direction wild p |
|---|---|---:|---:|---:|---:|
'''
for r in results:
    report+=f"| {r['metric']} | {r['direction']} | {r['gaussian_directional_p']:.4f} | {r['wild_directional_p']:.4f} | {r['gaussian_either_direction_p']:.4f} | {r['wild_either_direction_p']:.4f} |\n"
report+='''
## Interpretation limits and reproducibility

Retain all calibrations rather than selecting the favorable one. Existing ANCOVA concerns remain: small cage sample, nonrandom allocation, common slope/cohort-effect assumptions, and influential tail-score cage TMCS2_C10. Lower tail score means less of this weighted detector measure, not automatically better balance or less physical tail movement. Background: order-restricted inference has nonstandard null distributions; see https://pmc.ncbi.nlm.nih.gov/articles/PMC2955899/ and https://doi.org/10.1371/journal.pone.0084778 . The implementation here is the documented cone/Monte Carlo procedure, not a claim to reproduce either paper's exact method.

Reproduce with tests/testOrderedCageANCOVA.py using NumPy. Fixed seeds and simulation counts in results.csv/json. No video reads, new tracking, original-result modifications, or bulk scratch. Existing analyses remain intact.
'''
(OUT/'REPORT.md').write_text(report)
print(report[report.index('| Outcome'):report.index('## Interpretation')])
