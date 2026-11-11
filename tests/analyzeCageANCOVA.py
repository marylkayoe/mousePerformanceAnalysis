"""Exploratory cage-level D14 ANCOVA; NumPy only, no new dependencies.

Primary model: cage mean D14 ~ intercept + WALK + RUN + TMCS3 + cage mean D0.
Unweighted cages; common group effects across cohorts. Parametric t inference.
"""
import csv, json, math
from pathlib import Path
from collections import defaultdict
import numpy as np

ROOT=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS'
OUT=ROOT/'outcome-specific-contrasts/ANCOVA';OUT.mkdir(exist_ok=True)

def betacf(a,b,x):
    qab=a+b;qap=a+1;qam=a-1;c=1.;d=1-qab*x/qap
    if abs(d)<1e-300:d=1e-300
    d=1/d;h=d
    for m in range(1,501):
        aa=m*(b-m)*x/((qam+2*m)*(a+2*m));d=1+aa*d;c=1+aa/c
        if abs(d)<1e-300:d=1e-300
        if abs(c)<1e-300:c=1e-300
        d=1/d;h*=d*c
        aa=-(a+m)*(qab+m)*x/((a+2*m)*(qap+2*m));d=1+aa*d;c=1+aa/c
        if abs(d)<1e-300:d=1e-300
        if abs(c)<1e-300:c=1e-300
        d=1/d;delta=d*c;h*=delta
        if abs(delta-1)<3e-14:return h
    raise ArithmeticError('beta continued fraction did not converge')

def ibeta(a,b,x):
    if x<=0:return 0.
    if x>=1:return 1.
    bt=math.exp(math.lgamma(a+b)-math.lgamma(a)-math.lgamma(b)+a*math.log(x)+b*math.log1p(-x))
    return bt*betacf(a,b,x)/a if x<(a+1)/(a+b+2) else 1-bt*betacf(b,a,1-x)/b

def tp(t,df):return ibeta(df/2,.5,df/(df+t*t))
def fp(f,d1,d2):return ibeta(d2/2,d1/2,d2/(d2+d1*max(0,f)))
def tcrit(df):
    lo,hi=0.,100.
    for _ in range(80):
        mid=(lo+hi)/2
        if tp(mid,df)>.05:lo=mid
        else:hi=mid
    return (lo+hi)/2

def fit(X,y):
    assert np.linalg.matrix_rank(X)==X.shape[1]
    b=np.linalg.lstsq(X,y,rcond=None)[0];e=y-X@b;df=len(y)-X.shape[1]
    inv=np.linalg.inv(X.T@X);sse=float(e@e);h=np.sum((X@inv)*X,axis=1)
    cov=inv*(sse/df)
    hc3=inv@(X.T@((e/np.maximum(1-h,1e-12))[:,None]**2*X))@inv
    return dict(b=b,e=e,df=df,sse=sse,cov=cov,hc3=hc3,h=h)

assert abs(tp(1,1)-.5)<1e-12
assert abs(tp(2.2281388519649385,10)-.05)<1e-10
assert abs(fp(1,2,2)-.5)<1e-12
assert abs(tcrit(10)-2.2281388519649385)<1e-9

keys=['speed','time_stopped','posture','slip_count','slip_score','motion_height','tail_score']
results=[];diagnostics=[];inputs=[]
for key in keys:
    meta=json.loads((ROOT/'contrast-layout-examples'/f'{key}_baseline_changes_contrasts.json').read_text())
    rows=list(csv.DictReader((ROOT/meta['source']).open()))
    rows=[r for r in rows if r['day'] in ('D00','D14') and (key not in ('slip_count','slip_score') or int(r['nRuns'])==3)]
    look={(r['mouseID'],r['day']):r for r in rows};cells=defaultdict(list)
    for r in rows:
        if r['day']=='D14' and (r['mouseID'],'D00') in look:
            pre=look[r['mouseID'],'D00'];vals=[float(t[meta['field']])*meta['conversion'] for t in (pre,r)]
            assert all(math.isfinite(v) for v in vals)
            cells[r['cohort'],r['cageID'],r['group']].append(vals)
    labels=sorted(cells);a=np.array([np.mean(cells[k],axis=0) for k in labels]);x=a[:,0];y=a[:,1]
    z=(x-x.mean())/x.std();walk=np.array([g=='walk' for co,ca,g in labels],float);run=np.array([g=='run' for co,ca,g in labels],float);co=np.array([c=='TMCS3' for c,ca,g in labels],float)
    X=np.column_stack([np.ones(15),walk,run,co,z]);m=fit(X,y);df=m['df'];critical=tcrit(df)
    assert len(labels)==15
    for k,(v0,v1) in zip(labels,a):inputs.append(dict(metric=key,cohort=k[0],cage=k[1],group=k[2],n_mice=len(cells[k]),D0=v0,D14=v1))
    inter=fit(np.column_stack([X,z*walk,z*run]),y);quad=fit(np.column_stack([X,z*z]),y)
    saturated=fit(np.column_stack([X,co*walk,co*run]),y)
    # Same additive model with baseline fixed to zero/one, to separate model from adjustment changes.
    unadjusted=fit(X[:,:4],y);change=fit(X[:,:4],y-x)
    cook=m['e']**2/(5*(m['sse']/df))*m['h']/(1-m['h'])**2
    diagnostics.append(dict(metric=key,n_mice=sum(map(len,cells.values())),n_cages=15,df=df,
        baseline_slope=m['b'][4]/x.std(),baseline_slope_p=tp(m['b'][4]/math.sqrt(m['cov'][4,4]),df),
        slope_interaction_p=fp((m['sse']-inter['sse'])/2/(inter['sse']/inter['df']),2,inter['df']),
        quadratic_p=fp((m['sse']-quad['sse'])/(quad['sse']/quad['df']),1,quad['df']),
        max_cooks_distance=float(max(cook)),max_cook_cage='/'.join(labels[int(np.argmax(cook))][:2]),
        max_leverage=float(max(m['h'])),condition_number=float(np.linalg.cond(X))))
    for pair,c in [('run minus walk',np.array([0,-1,1,0,0.])),('run minus sedentary',np.array([0,0,1,0,0.])),('walk minus sedentary',np.array([0,1,0,0,0.]))]:
        estimate=float(c@m['b']);se=math.sqrt(c@m['cov']@c);seh=math.sqrt(c@m['hc3']@c)
        # Average the cohort-specific contrasts equally in the interaction sensitivity.
        cs=np.r_[c,.5*c[1],.5*c[2]];ss=math.sqrt(cs@saturated['cov']@cs)
        loo=[]
        for i in range(15):
            keep=np.arange(15)!=i;f=fit(X[keep],y[keep]);est=float(c@f['b']);s=math.sqrt(c@f['cov']@c)
            loo.append(dict(omitted='/'.join(labels[i][:2]),estimate=est,p=tp(est/s,f['df'])))
        results.append(dict(metric=key,contrast=pair,role='primary' if pair=='run minus walk' else 'secondary',
            unit='percentage points' if key=='time_stopped' else meta['unit'],estimate=estimate,
            ci95_low=estimate-critical*se,ci95_high=estimate+critical*se,p=tp(estimate/se,df),
            hc3_p=tp(estimate/seh,df),hc3_ci95_low=estimate-critical*seh,hc3_ci95_high=estimate+critical*seh,
            same_model_D14_p=tp((c[:4]@unadjusted['b'])/math.sqrt(c[:4]@unadjusted['cov']@c[:4]),unadjusted['df']),
            same_model_change_p=tp((c[:4]@change['b'])/math.sqrt(c[:4]@change['cov']@c[:4]),change['df']),
            cohort_interaction_estimate=float(cs@saturated['b']),cohort_interaction_p=tp((cs@saturated['b'])/ss,saturated['df']),
            leave_one_cage_out=loo))
    # Editable diagnostic: actual cage means, cohort symbols, common fitted slope.
    colors={'sedentary':'#232323','walk':'#00b226','run':'#002bff'}
    lo=x.min();hi=x.max();yl=y.min();yh=y.max();px=lambda v:65+400*(v-lo)/(hi-lo);py=lambda v:300-240*(v-yl)/(yh-yl)
    svg=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 570 365">',f'<text x="60" y="25" font-family="Arial" font-size="18">{key}: cage means D0 versus D14</text>','<path d="M65 50V300H465" fill="none" stroke="black"/>']
    for (cohort,ca,g),(v0,v1) in zip(labels,a):
        xx=px(v0);yy=py(v1);col=colors[g]
        shape=f'<circle cx="{xx}" cy="{yy}" r="4" fill="{col}"/>' if cohort=='TMCS2' else f'<rect x="{xx-4}" y="{yy-4}" width="8" height="8" fill="{col}"/>'
        svg.append('<g><title>'+cohort+' '+ca+' '+g+'</title>'+shape+'</g>')
    for j,g in enumerate(colors):svg.append(f'<text x="480" y="{80+20*j}" fill="{colors[g]}" font-family="Arial" font-size="12">{g}</text>')
    for v in np.linspace(lo,hi,5):svg.append(f'<text x="{px(v)}" y="320" text-anchor="middle" font-family="Arial" font-size="11">{v:.3g}</text>')
    for v in np.linspace(yl,yh,5):svg.append(f'<text x="58" y="{py(v)+4}" text-anchor="end" font-family="Arial" font-size="11">{v:.3g}</text>')
    svg+=['<text x="240" y="345" font-family="Arial" font-size="14">D0</text>','<text x="10" y="40" font-family="Arial" font-size="14">D14</text>','<text x="65" y="362" font-family="Arial" font-size="11">Circles: TMCS2; squares: TMCS3. Each point is one cage.</text>','</svg>']
    (OUT/f'{key}_baseline_endpoint.svg').write_text('\n'.join(svg))

for name,data in [('results',results),('diagnostics',diagnostics),('cage_inputs',inputs)]:
    (OUT/(name+'.json')).write_text(json.dumps(data,indent=2))
    fields=[k for k in data[0] if k!='leave_one_cage_out']
    with (OUT/(name+'.csv')).open('w',newline='') as f:
        w=csv.DictWriter(f,fields,extrasaction='ignore');w.writeheader();w.writerows(data)
print('PRIMARY RUN-WALK')
for r in results:
    if r['role']=='primary':print(r['metric'], 'effect',round(r['estimate'],4),'CI',round(r['ci95_low'],4),round(r['ci95_high'],4),'p',round(r['p'],4),'HC3',round(r['hc3_p'],4),'cohort-interaction',round(r['cohort_interaction_p'],4))
print('DIAGNOSTICS',json.dumps(diagnostics,indent=2))
