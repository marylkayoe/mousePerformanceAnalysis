"""Seven descriptive baseline/change/contrast triptychs; unchanged scalar outcomes."""
from pathlib import Path
from collections import defaultdict
import csv,json,runpy,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];root=R/'BEAMCROSS/DRAFTFIGS';out=root/'contrast-layout-examples';out.mkdir(exist_ok=True);ct=runpy.run_path(str(root/'tail-metrics/whole-motion-reweighted/cage_tests.py'))
read=lambda p:list(csv.DictReader((root/p).open()));rng=np.random.default_rng(20261111);N=100000
configs=[('posture','Posture height','mm','analysis-data/posture-statistics/tail-days.csv','value',700/1201,False,(10,17),(-3,3)),('speed','Locomoting speed','mm/s','analysis-data/weighted-speed/speed-days-input.csv','value',700/1201,False,(50,200),(-55,105)),('slip_count','Slip count','count','analysis-data/pooled-exposures.csv','combinedSlips',1,True,(0,60),(-40,30)),('slip_score','Total slip score','a.u. × frames','analysis-data/pooled-exposures.csv','combinedSlipMagnitude',1,True,None,None),('time_stopped','Time stopped','%','SLIPS&STOPS/stop-time-percentage/mouse-day-values.csv','value',1,False,(0,40),(-30,20)),('motion_height','Motion height','mm','tail-metrics/height-exploratory/mouse-day-motion-height.csv','medianHeight',1,False,(0,60),(-30,30)),('tail_score','Tail-motion score','a.u.','tail-metrics/whole-motion-reweighted/mouse-day-values.csv','meanLegacy',1,False,(0,.8),(-.5,.6))]
allstats=[];groups=['sedentary','walk','run'];colors=['#000000','#008d3f','#0864cf'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
for key,title,unit,src,field,factor,three,baseylim,deltaylim in configs:
 rows=read(src);rows=[dict(r,value=float(r[field])*factor) for r in rows if (not three or int(r['nRuns'])==3)];lookup={(r['mouseID'],r['day']):r for r in rows};baseline=[r for r in rows if r['day']=='D00'];changes=[dict(r,value=r['value']-lookup[r['mouseID'],'D00']['value']) for r in rows if r['day']=='D14' and (r['mouseID'],'D00') in lookup];om,pairs=ct['test'](changes)
 cells=defaultdict(list)
 for r in changes:cells[r['cohort'],r['cageID'],r['group']].append(r['value'])
 cage={k:np.mean(v) for k,v in cells.items()};effects=[]
 for A,B in [('run','walk'),('run','sedentary')]:
  boot=np.zeros(N);estimate=0;counts={}
  for co in ('TMCS2','TMCS3'):
   for g,sign in [(A,1),(B,-1)]:
    v=np.array([a for (c,ca,gg),a in cage.items() if c==co and gg==g]);counts[co+'_'+g]=len(v);estimate+=.5*sign*v.mean();boot+=.5*sign*rng.choice(v,(N,len(v)),replace=True).mean(axis=1)
  low,high=np.quantile(boot,[.025,.975]);p=next(r for r in pairs if r['pair']==A+' minus '+B);assert np.isclose(estimate,p['difference_cage_cohort_balanced']);effects.append(dict(pair=A+' minus '+B,estimate=estimate,lower=float(low),upper=float(high),pHolm=p['p_holm_3_pairs'],cages=counts))
 W,H,Z=1100,365,2;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">']
 def text(x,y,t,size=12,anchor='start'):
  svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{t}</text>');d.text((x*Z,y*Z),t,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
 def line(x,y,xx,yy,c='#333333',w=1):
  svg.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{c}" stroke-width="{w}" fill="none"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
 def circle(x,y,c,rad=3,opacity=1):
  svg.append(f'<circle cx="{x}" cy="{y}" r="{rad}" fill="{c}" fill-opacity="{opacity}"/>');rgb=tuple(round(int(c[k:k+2],16)*opacity+255*(1-opacity)) for k in (1,3,5));d.ellipse(((x-rad)*Z,(y-rad)*Z,(x+rad)*Z,(y+rad)*Z),fill=rgb)
 def bounds(vals):
  lo=min(0,min(vals));hi=max(vals);span=max(hi-lo,1e-4);step=10**math.floor(math.log10(span))/2;return math.floor((lo-.06*span)/step)*step,math.ceil((hi+.06*span)/step)*step
 for panel,rs,limits,label in [(0,baseline,baseylim,'D0'),(1,changes,deltaylim,'D14−D0')]:
  L=55+330*panel;RR=L+250;T=65;B=280;lo,hi=limits or bounds([r['value'] for r in rs]);Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
  assert all(lo<=r['value']<=hi for r in rs),(key,label,min(r['value'] for r in rs),max(r['value'] for r in rs))
  text(L,27,title+', '+label,17);text(L,47,'percentage points' if key=='time_stopped' and panel else unit,11)
  for v in np.linspace(lo,hi,5):line(L,Y(v),L+4,Y(v));text(L-7,Y(v)+4,f'{v:.3g}',10,'end')
  line(L,T,L,B)
  if panel:line(L,Y(0),RR,Y(0),'#bbbbbb')
  for j,(g,c) in enumerate(zip(groups,colors)):
   a=sorted([r for r in rs if r['group']==g],key=lambda r:r['mouseID']);cx=L+48+j*82;cc=defaultdict(list)
   for i,r in enumerate(a):
    x=cx-12+24*i/(len(a)-1);circle(x,Y(r['value']),c,3,1 if g=='sedentary' else .4);cc[r['cohort'],r['cageID']].append(r['value'])
   for val in cc.values():
    x=cx-25;y=Y(np.mean(val));pts=[(x-3,y),(x,y-4.5),(x+3,y),(x,y+4.5)];svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+f'" fill="{c}" stroke="#232323" stroke-width=".4"/>');d.polygon([(a*Z,b*Z) for a,b in pts],fill=c,outline='#232323')
   y=Y(np.mean([r['value'] for r in a]));line(cx-16,y,cx+16,y,c,3);text(cx,305,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],13,'middle')
 # Contrast panel: include zero and all descriptive intervals.
 L,RR=890,1080;T,B=80,275;lo,hi=bounds([0]+[r[k] for r in effects for k in ('lower','upper')]);X=lambda v:L+(v-lo)/(hi-lo)*(RR-L)
 text(710,27,'Comparisons of changes',17);text(710,47,'Cage/cohort-balanced estimates',11);line(X(0),70,X(0),255,'#aaaaaa')
 for i,r in enumerate(effects):
  y=115+i*100;text(710,y-5,'RUN − WALK' if i==0 else 'RUN − SED',14);text(710,y+13,'Beyond shared routine' if i==0 else 'Overall procedure',10);line(X(r['lower']),y,X(r['upper']),y,'#002bff',2);circle(X(r['estimate']),y,'#002bff',4);text((L+RR)/2,y+26,f"Holm p = {r['pHolm']:.3f}",10,'middle')
 line(L,B,RR,B)
 for v in np.linspace(lo,hi,4):line(X(v),B,X(v),B+4);text(X(v),B+19,f'{v:.3g}',10,'middle')
 text((L+RR)/2,316,'Difference ('+('percentage points' if key=='time_stopped' else unit)+')',10,'middle')
 text(20,344,'Exploratory 95% cage-bootstrap intervals; original three-pair Holm p-values retained.',11)
 text(20,361,'Sparse cages limit interval reliability. Intervals are unadjusted; no new hypothesis hierarchy has been adopted.',10)
 svg.append('</svg>');stem=out/(key+'_baseline_changes_contrasts');stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
 report=dict(metric=key,source=src,field=field,unit=unit,conversion=factor,nD0=len(baseline),nPaired=len(changes),overallChangeP=om,allThreePairTests=pairs,effects=effects,bootstrapReplicates=N,seed=20261111)
 stem.with_suffix('.json').write_text(json.dumps(report,indent=2));allstats.append(report)
 with stem.with_suffix('.csv').open('w',newline='') as f:
  w=csv.writer(f);w.writerow(['MouseID','Cohort','CageID','Group','Period','Value'])
  for period,rs in [('D0',baseline),('D14-D0',changes)]:
   for r in rs:w.writerow([r['mouseID'],r['cohort'],r['cageID'],r['group'],period,r['value']])
 print(key,len(baseline),len(changes),flush=True)
(out/'README.md').write_text('''# Baseline / paired changes / biological contrasts: exploratory layout examples

Reproduce: tests/plotAllMetricContrastPanels.py. Seven metrics, same definitions as current main figure. Circles are mice, diamonds cage means, bars mouse means. Third panel uses equal-cohort cage-balanced RUN–WALK and RUN–SED differences of within-mouse D14−D0 changes. All42mice for posture/speed/tail,41 for slips/stopped percentage because those require3crossings per day. Stopped-time change is percentage points. Tail score is existing corrected whole-range Legacy mean; height is mean crossing medianHeight, not anatomical position.

Exact permutation p-values retain Holm across ALL THREE group pairs within outcome/period, including WALK–SED although it is not drawn in the contrast panel. Omnibus and all pairs are in JSON. No changed hierarchy or new multiplicity claim. Intervals:100000 percentile bootstrap replicates, resampling whole cages within cohort/group; fixed seed20261111. 95% intervals are descriptive, unadjusted and not simultaneous. One TMCS3 WALK cage contributes no within-cell resampling variation; few cages can make intervals too narrow. They are visual prototypes, not publication-ready confidence claims. Bootstrap intervals and adjusted exact-permutation p-values need not agree. Both rely on assumptions; nonrandom allocation is not repaired.

Physical/scalar definitions unchanged; all source rows saved alongside plots. Statistics were recomputed using existing cage_tests.py. No inference across all outcomes controlled. Negative contrast means RUN decreased more or increased less than its comparator. RUN–WALK reflects additional demands beyond shared routine, not an isolated causal effect of motor learning. RUN–SED is overall procedure contrast. Original main figure panels are preserved. These new examples were not part of the earlier cleanup or push.
''')
