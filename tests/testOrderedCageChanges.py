"""Exploratory equality-versus-order tests, cohort-adjusted cage mean D14-D0 changes.

Two-dimensional cone solved by enumerating its interior, rays and vertex.
Gaussian Monte Carlo calibrates finite-sample null conditional on fixed design.
Exhaustive null-residual wild signs provide a heteroscedasticity sensitivity,
not an exact randomization test. No independence of mice is assumed.
"""
from pathlib import Path
import csv,json
import numpy as np

ROOT=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/outcome-specific-contrasts/ANCOVA'
OUT=ROOT/'ordered-change';OUT.mkdir(exist_ok=True)
N=200000;SEED=20261111
rows=list(csv.DictReader((ROOT/'cage_inputs.csv').open()))
spec=[('speed',1),('tail_score',-1),('motion_height',-1)]

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
    x=np.array([float(r['D0']) for r in rs]);y=np.array([float(r['D14'])-float(r['D0']) for r in rs])*sign
    Z=np.column_stack([np.ones(n),[r['cohort']=='TMCS3' for r in rs]])
    G=np.column_stack([[r['group']=='walk' for r in rs],[r['group']=='run' for r in rs]]).astype(float)
    M,A,H,inv=setup(Z,G);df=n-4
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
    check=statistics((2*y+Z@np.array([2.,3.]))[:,None],M,A,H,inv,df)[0][0]
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

report="""# Ordered-pattern tests of D14−D0 changes

These tests match the change-score panels: speed, tail-motion score and motion height. Same paired mice and cage inputs as ../cage_inputs.csv; average within-mouse D14−D0 changes within each cage. Fifteen independent cage observations, additive cohort term; no additional D0 predictor. Four parameters in the unrestricted model, 11 residual df. Common group effects across cohorts are assumed. This differs from the original equal-cohort permutation contrast analysis; these are model-based ordered-pattern tests, not replacements for its pairwise p-values.

Null: all three adjusted mean changes equal. Alternative: either SED ≤ WALK ≤ RUN or the reverse, with at least one strict inequality. Unequal steps and plateaus allowed. The either-direction Gaussian Monte Carlo p-value is the main reported result because direction was data-informed. Directional values (speed increasing, tail score and height decreasing) are saved only for transparency. Height direction was not previously specified; no directional claim is made for it. These tests do not establish both adjacent differences, or RUN versus WALK specifically.

Calibration: 200,000 fixed-design Gaussian response simulations; statistic is constrained improvement over equal-group null divided by unrestricted residual variance. Nuisance intercept/cohort projected out. Null distribution invariant to nuisance means and common scale. All 32,768 HC2 null-residual Rademacher wild-bootstrap signs supply an approximate unequal-variance sensitivity. Wild bootstrap is not an exact randomization test. Same cone fitting, feasibility and scale/nuisance invariance checks as tests/testOrderedCageANCOVA.py; see ../ordered-trend/REPORT.md for background. No across-outcome correction. Selection of outcomes and directions followed inspection; results are exploratory, not confirmatory. Nonrandom allocation, sparse cages and influential observations remain limitations.

| Change outcome | Either-direction Gaussian p | Either-direction wild p | Gaussian simulation SE (directional) |
|---|---:|---:|---:|
"""
for r in results:
    report+=f"| {r['metric']} | {r['gaussian_either_direction_p']:.4f} | {r['wild_either_direction_p']:.4f} | {r['monte_carlo_se']:.5f} |\n"
report+="\nReproduce: tests/testOrderedCageChanges.py. Existing sources, plots, ANCOVA tests and original results preserved. Use these change-test values only on matching D14−D0 panels; do not substitute ANCOVA p-values.\n"
(OUT/'REPORT.md').write_text(report)
print(report)
