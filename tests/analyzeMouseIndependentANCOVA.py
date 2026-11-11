"""Requested sensitivity: D14 ~ D0 + group + cohort, ignoring cage dependence.

Reuses only numerical function definitions from analyzeCageANCOVA.py via AST,
without executing its output-generation code or overwriting its results.
"""
import ast, csv, json, math
from pathlib import Path
import numpy as np

REPO=Path(__file__).resolve().parents[1]
ROOT=REPO/'BEAMCROSS/DRAFTFIGS'
OUT=ROOT/'outcome-specific-contrasts/ANCOVA/mice-independent-sensitivity'
OUT.mkdir(exist_ok=True)
module=ast.parse((REPO/'tests/analyzeCageANCOVA.py').read_text())
functions=ast.Module(body=[n for n in module.body if isinstance(n,ast.FunctionDef)],type_ignores=[])
exec(compile(functions,'analyzeCageANCOVA.py functions','exec'))
assert abs(tp(1,1)-.5)<1e-12 and abs(tp(2.2281388519649385,10)-.05)<1e-10
cage=json.loads((OUT.parent/'results.json').read_text())
results=[];inputs=[]
for key in ['speed','time_stopped','posture','slip_count','slip_score','motion_height','tail_score']:
    meta=json.loads((ROOT/'contrast-layout-examples'/f'{key}_baseline_changes_contrasts.json').read_text())
    rows=list(csv.DictReader((ROOT/meta['source']).open()))
    rows=[r for r in rows if r['day'] in ('D00','D14') and (key not in ('slip_count','slip_score') or int(r['nRuns'])==3)]
    lookup={(r['mouseID'],r['day']):r for r in rows}
    paired=[]
    for r in rows:
        if r['day']=='D14' and (r['mouseID'],'D00') in lookup:
            pre=lookup[r['mouseID'],'D00']
            v=dict(metric=key,mouse=r['mouseID'],cohort=r['cohort'],cage=r['cageID'],group=r['group'],
                   D0=float(pre[meta['field']])*meta['conversion'],D14=float(r[meta['field']])*meta['conversion'])
            paired.append(v);inputs.append(v)
    assert len(paired)==meta['nPaired'] and len({r['mouse'] for r in paired})==len(paired)
    x=np.array([r['D0'] for r in paired]);y=np.array([r['D14'] for r in paired])
    assert np.isfinite(x).all() and np.isfinite(y).all()
    X=np.column_stack([np.ones(len(x)),[r['group']=='walk' for r in paired],[r['group']=='run' for r in paired],
                       [r['cohort']=='TMCS3' for r in paired],(x-x.mean())/x.std()])
    m=fit(X,y);critical=tcrit(m['df'])
    for pair,c in [('run minus walk',np.array([0,-1,1,0,0.])),('run minus sedentary',np.array([0,0,1,0,0.])),('walk minus sedentary',np.array([0,1,0,0,0.]))]:
        estimate=float(c@m['b']);se=math.sqrt(c@m['cov']@c);seh=math.sqrt(c@m['hc3']@c)
        prior=next(r for r in cage if r['metric']==key and r['contrast']==pair)
        results.append(dict(metric=key,contrast=pair,role=prior['role'],n_mice=len(x),df=m['df'],unit=prior['unit'],
            estimate=estimate,ci95_low=estimate-critical*se,ci95_high=estimate+critical*se,
            p=tp(estimate/se,m['df']),hc3_p=tp(estimate/seh,m['df']),
            cage_ANCOVA_estimate=prior['estimate'],cage_ANCOVA_p=prior['p'],cage_ANCOVA_hc3_p=prior['hc3_p'],
            baseline_slope=m['b'][4]/x.std()))
for name,rows in [('results',results),('mouse_inputs',inputs)]:
    (OUT/(name+'.json')).write_text(json.dumps(rows,indent=2))
    with (OUT/(name+'.csv')).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
report='''# Mouse-independent ANCOVA sensitivity — 2026-11-11

Requested hypothetical comparison, NOT a replacement for cage-aware inference. Same paired mouse sets, metric definitions, conversions, D0 adjustment, cohort fixed effect, common slope and additive group effects as the cage-level ANCOVA. Here each mouse is a separate equally weighted observation, and cage dependence is deliberately ignored. There are 42 mice/37 residual df (speed, posture, tail) or 41/36 df (slipping/stopped percentage). All p-values are two-sided, outcome-specific and unadjusted; RUN–WALK remains primary. HC3 allows unequal variance between mice but DOES NOT repair dependence between mice sharing cages.

Comparing the analyses changes both independence assumptions and aggregation/weighting: cage-level means weight cages equally; this model weights mice equally and estimates a mouse-level baseline association. Differences cannot be attributed solely to an arbitrary penalty for cages. Neither model resolves nonrandom group allocation. This check cannot establish that the study would have succeeded under another design, nor that nonsignificant results demonstrate no effect.

| Metric | RUN–WALK p, mice independent | RUN–WALK p, cages | RUN–SED p, mice independent | RUN–SED p, cages | WALK–SED p, mice independent |
|---|---:|---:|---:|---:|---:|
'''
for key in dict.fromkeys(r['metric'] for r in results):
    a,b,c=[r for r in results if r['metric']==key]
    report+=f"| {key} | {a['p']:.4f} | {a['cage_ANCOVA_p']:.4f} | {b['p']:.4f} | {b['cage_ANCOVA_p']:.4f} | {c['p']:.4f} |\n"
report+='\nReproduce: tests/analyzeMouseIndependentANCOVA.py. Full estimates, standard 95% intervals, HC3 sensitivity and baseline slopes are in results.csv/json; exact inputs in mouse_inputs.csv/json. Original cage ANCOVA and canonical source data preserved. These are small repository sensitivity outputs, not new canonical measurement results.\n'
(OUT/'REPORT.md').write_text(report)
print(report)
print('HC3',[(r['metric'],r['contrast'],round(r['hc3_p'],4)) for r in results])
