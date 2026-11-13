"""Exploratory cohort-stratified cage-label group tests for first D0 panels."""
from pathlib import Path
from collections import defaultdict
import csv,json,itertools,runpy
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS';O=R/'D0-first-trial-panels';rows=list(csv.DictReader((O/'trial_values.csv').open()));meta={r['mouseID']:r for r in rows};files={r['file'] for r in rows};ct=runpy.run_path(str(R/'tail-metrics/whole-motion-reweighted/cage_tests.py'));results=[]
for key in ['speed','slips','stopped']:
 om,pairs=ct['test']([dict(r,value=float(r[key])) for r in rows]);results.append(dict(metric=key,p_raw=om,nMice=len(rows),nCages=15,pairs=pairs))
def curve_test(mouse,weights):
 cells=defaultdict(list)
 for m,v in mouse.items():
  r=meta[m];cells[r['cohort'],r['cageID'],r['group']].append(v)
 keys=sorted(cells);a=np.array([np.mean(cells[k],axis=0) for k in keys]);n=len(keys);assert np.isfinite(a).all()
 # Within-cohort centred cage vectors. Gram matrix integrates over curve domain.
 for co in ['TMCS2','TMCS3']:
  ix=[i for i,k in enumerate(keys) if k[0]==co];a[ix]-=a[ix].mean(0)
 gram=(a*weights)@a.T;scores=[];g00=g01=g11=0
 obsr=np.array([k[2]=='run' for k in keys],float);obsw=np.array([k[2]=='walk' for k in keys],float)
 for co in ['TMCS2','TMCS3']:
  ids=[i for i,k in enumerate(keys) if k[0]==co];nr=sum(keys[i][2]=='run' for i in ids);nw=sum(keys[i][2]=='walk' for i in ids);nn=len(ids);g00+=nr-nr*nr/nn;g01-=nr*nw/nn;g11+=nw-nw*nw/nn;per=[]
  for rr in itertools.combinations(ids,nr):
   rem=[i for i in ids if i not in rr]
   for ww in itertools.combinations(rem,nw):
    ar=np.zeros(n);aw=np.zeros(n);ar[list(rr)]=1;aw[list(ww)]=1;per.append((ar,aw))
  scores.append(per)
 det=g00*g11-g01*g01
 def statistic(r,w):return (g11*np.einsum('...i,ij,...j->...',r,gram,r)-2*g01*np.einsum('...i,ij,...j->...',r,gram,w)+g00*np.einsum('...i,ij,...j->...',w,gram,w))/det
 obs=statistic(obsr,obsw);bs=np.array(scores[1]);ge=total=0
 for ar,aw in scores[0]:
  vals=statistic(ar+bs[:,0],aw+bs[:,1]);ge+=int(np.sum(vals>=obs-1e-10));total+=len(vals)
 return dict(p_raw=ge/total,statistic=float(obs),permutations=total,nMice=len(mouse),nCages=n)
# Fixed complete support for trajectory inference, independent of labels.
by=defaultdict(list)
for r in csv.DictReader((O/'spatial_source.csv').open()):by[r['mouseID']].append((float(r['positionMM']),float(r['speed'])))
ids=sorted(by);pos=np.array([x for x,v in sorted(by[ids[0]])]);a=np.array([[v for x,v in sorted(by[m])] for m in ids]);good=np.isfinite(a).all(0);assert good.any();s=curve_test({m:v[good] for m,v in zip(ids,a)},np.ones(good.sum())*(10*700/1201));results.append(dict(metric='speed_profile',eligibleBins=int(good.sum()),excludedPositionsMM=pos[~good].tolist(),**s))
# Existing validated reconstruction covers all first trials with events.
ev=defaultdict(list)
for r in csv.DictReader((R/'D0-within-day-trials/first_last_slips_event_values.csv').open()):
 if r['file'] in files:ev[r['mouseID']].append(float(r['score']))
for r in rows:assert len(ev[r['mouseID']])==int(float(r['slips']))
ev={m:np.array(v) for m,v in ev.items() if len(v)};grid=np.unique(np.concatenate(list(ev.values())));weights=np.diff(np.log10(grid));mouse={m:(np.searchsorted(np.sort(v),grid,side='right')/len(v))[:-1] for m,v in ev.items()};results.append(dict(metric='slip_CDF',**curve_test(mouse,weights)))
for r,p in zip(results,ct['holm']([r['p_raw'] for r in results])):r['p_holm5_sensitivity']=p
(O/'group_statistics.json').write_text(json.dumps(results,indent=2))
with (O/'group_statistics.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['metric','nMice','nCages','p_raw','p_holm5_sensitivity'],extrasaction='ignore');w.writeheader();w.writerows(results)
# Add one omnibus p per panel, leaving original editable files intact.
stem=O/'D0_first_retained_five_panels';s=stem.with_suffix('.svg').read_text();im=Image.open(stem.with_suffix('.png'));dr=ImageDraw.Draw(im);font='/System/Library/Fonts/Supplemental/Arial.ttf';extra=[]
loc={'speed_profile':(35,353),'speed':(725,353),'slips':(55,713),'stopped':(725,713),'slip_CDF':(390,727)}
for r in results:
 x,y=loc[r['metric']];t=f"Group comparison: p = {r['p_raw']:.3f}";extra.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="12" fill="#232323">{t}</text>');dr.text((x*2,y*2),t,font=ImageFont.truetype(font,24),fill='#232323',anchor='ls')
# Make room for explicit statistics note.
s=s.replace('viewBox="0 0 1020 760"','viewBox="0 0 1020 785"');canvas=Image.new('RGB',(2040,1570),'white');canvas.paste(im);im=canvas;dr=ImageDraw.Draw(im)
t='Exploratory omnibus p-values · whole cages permuted within cohort · no pairwise significance brackets';extra.append(f'<text x="35" y="775" font-family="Arial" font-size="12">{t}</text>');dr.text((70,1550),t,font=ImageFont.truetype(font,24),fill='#232323',anchor='ls');s=s.replace('</svg>','\n'.join(extra)+'</svg>');out=O/(stem.name+'_with_group_statistics');out.with_suffix('.svg').write_text(s);im.save(out.with_suffix('.png'))
(O/'STATISTICS.md').write_text('''# First-retained D0 group comparisons

One omnibus test per panel, for any SED/WALK/RUN difference. Same selected first trials as figures. Scalar outcomes: existing cage_tests.test; mean mice within cage, cohort-adjusted group sum of squares, exact whole-cage group-label permutations within each cohort preserving cage counts. Pairwise comparisons with Holm3 retained in JSON, not displayed.

Trajectory: finite complete support across all42mice fixed before permutation, average mice within cage. Integrated cohort-adjusted group regression sum of squares over spatial bins; entire cage profile permuted together. Inference excludes incomplete bins while descriptive figure retains half-group coverage. Support listed in JSON. No pointwise tests.

CDF: mean within-mouse ECDF then within cage; exclude one zero-slip mouse only from conditional size distribution. Integrated cohort-adjusted group regression sum of squares over exact log10score intervals; whole cage CDFs permuted together. Event scores reused from validated first_last_slips_event_values.csv; all first-trial event counts checked. 41CDFmice/15cages versus42scalar/profilemice/15cages.

All tests assume exchangeability of group cage labels within cohort under null; this does not establish randomized allocation. Descriptive means weight mice equally, inference cages. Display exploratory raw omnibus p-values; Holm across5paneltests saved as sensitivity, not outcome selection correction. No independent-event/bin replication. No new tracking or measurement changes. Reproduce tests/testD0FirstTrialReferencePanels.py after figure generator; original figures preserved.
''');print(json.dumps(results,indent=2))
