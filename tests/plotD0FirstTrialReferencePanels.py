"""Five first-retained-D0 panels matching supplied Illustrator layout."""
from pathlib import Path
from collections import defaultdict
import csv,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];D=R/'BEAMCROSS/DRAFTFIGS';O=D/'D0-first-trial-panels';O.mkdir(exist_ok=True);csv.field_size_limit(10000000)
assets={r['fileName']:r for r in csv.DictReader((R/'assets/Tara-BB-trial-data.csv').open())};by=defaultdict(list)
for r in csv.DictReader((D/'analysis-data/trial_manifest.csv').open()):
 if r['Day']=='0':by[r['MouseID']].append(r)
sel=[min(rr,key=lambda r:int(r['TrialNumber'])) for m,rr in sorted(by.items())];assert len(sel)==42
source=json.loads((D/'speed-presentation/speed-profile-source.json').read_text());edges=np.array(source['edges']);xx=np.array(source['x']);keep=(xx>=42)&(xx<=1243);pos=(1243-xx[keep])*700/1201;order=np.argsort(pos);pos=pos[order]
events=defaultdict(list)
for e in csv.DictReader((D/'analysis-data/events.csv').open()):
 if e['Type']=='slip':events[e['File']].append(e)
root=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials');data=[];profiles=defaultdict(list);ev=defaultdict(list);audit=[];profile_rows=[]
for t in sel:
 f=t['File'];a=assets[f];rr=list(csv.DictReader((root/(f+'.trace.csv')).open()));speed=np.array([float(r['ForwardSpeed']) for r in rr]);cx=np.array([float(r['CentroidX']) for r in rr]);stop=np.array([int(r['StopMask']) for r in rr],bool);assert len(rr)==int(t['Frames']) and stop.sum()==int(t['CorrectStoppedFrames']);assert abs(np.nanmean(speed[~stop])-float(a['meanSpeedLoco']))<1e-7
 good=~stop & np.isfinite(cx)&np.isfinite(speed);pp=np.full(len(xx),np.nan)
 for j in range(len(xx)):
  mask=good&(cx>=edges[j])&(cx<edges[j+1])
  if mask.any():pp[j]=speed[mask].mean()*700/1201
 pp=pp[keep][order];profiles[t['Group']].append(pp)
 profile_rows.extend(dict(file=f,mouseID=t['MouseID'],group=t['Group'],positionMM=p,speed=v) for p,v in zip(pos,pp))
 scores=[]
 for e in events[f]:
  aa,bb=int(e['StartTraversalFrame']),int(e['EndTraversalFrame']);v=np.array([float(r['MovementTrace']) for r in rr[aa-1:bb]]);assert np.isfinite(v).all();scores.append(float(np.maximum(v-2.5,0).sum()))
 assert len(scores)==int(float(a['nSlips'])) and math.isclose(sum(scores),float(a['totalSlipMagnitude']),rel_tol=1e-6,abs_tol=1e-6);assert all(v>0 for v in scores)
 if scores:ev[t['Group']].append(np.array(scores))
 data.append(dict(file=f,mouseID=t['MouseID'],cohort=t['Cohort'],cageID=t['CageID'],group=t['Group'],trialNumber=t['TrialNumber'],speed=float(a['meanSpeedLoco'])*700/1201,slips=float(a['nSlips']),stopped=100*stop.sum()/len(rr)))
 audit.append(dict(file=f,nEvents=len(scores),eventSum=sum(scores),referenceTotal=float(a['totalSlipMagnitude'])))
W,H,Z=1020,760,2;im=Image.new('RGB',(W*Z,H*Z),'white');dr=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
base=(R/'tests/plotD0FirstLastSpeedCDF.py').read_text();exec(base[base.index('def text('):base.index('text(35,27,')])
groups=['sedentary','walk','run'];colors=['#232323','#00b226','#002bff'];scattercolors=['#232323','#008d3f','#0864cf']
def dot(x,y,c,r=2.5):
 svg.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>');dr.ellipse(((x-r)*Z,(y-r)*Z,(x+r)*Z,(y+r)*Z),fill=c)
def scatter(key,L,T,title,ticks,lo,hi):
 B=T+235;RR=L+250;Y=lambda v:B-(v-lo)/(hi-lo)*235
 vals=[r[key] for r in data];assert min(vals)>=lo and max(vals)<=hi,(key,min(vals),max(vals))
 text(L,T-24,title,18);path([(L,T),(L,B)])
 for v in ticks:path([(L,Y(v)),(L+4,Y(v))]);text(L-7,Y(v)+4,str(v),12,'end')
 if key=='speed':text(L-35,T+130,'mm/s',12)
 for j,(g,c) in enumerate(zip(groups,scattercolors)):
  rr=[r for r in data if r['group']==g];center=L+45+j*83;cells=defaultdict(list)
  for i,r in enumerate(rr):
   x=center-10+20*i/(len(rr)-1);y=Y(r[key]);cc='#'+''.join(f'{round(int(c[k:k+2],16)*.4+255*.6):02x}' for k in [1,3,5]);dot(x,y,cc);cells[r['cohort'],r['cageID']].append(r[key])
  for vv in cells.values():
   x=center-24;y=Y(np.mean(vv));pts=[(x-2.6,y),(x,y-4),(x+2.6,y),(x,y+4)];svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" stroke="#232323" stroke-width=".5"/>');dr.polygon([(x*Z,y*Z) for x,y in pts],fill=c,outline='#232323')
  y=Y(np.mean([r[key] for r in rr]));path([(center-12,y),(center+12,y)],c,2.5);text(center,B+23,['SED','WALK','RUN'][j],14,'middle')
# Spatial upper left: scale bars instead of axes, stop-excluded.
L,RR,T,B=35,625,75,290;X=lambda p:L+p/700*(RR-L);Y=lambda v:B-(v-20)/250*(B-T)
text(L,32,'Locomoting speed along the beam, D0 · first crossing',20)
summary=[]
for g,c in zip(groups,colors):
 a=np.array(profiles[g]);n=np.sum(np.isfinite(a),0);mu=np.nanmean(a,0);se=np.nanstd(a,axis=0,ddof=1)/np.sqrt(n);valid=(n>=math.ceil(len(a)/2))&np.isfinite(se);segments=[];ss=[]
 for j in range(len(pos)):
  summary.append(dict(group=g,positionMM=pos[j],nMice=int(n[j]),mean=mu[j],SEM=se[j]))
  if valid[j]:ss.append(j)
  elif ss:segments.append(ss);ss=[]
 if ss:segments.append(ss)
 for ss in segments:
  pts=[(X(pos[j]),Y(mu[j]+se[j])) for j in ss]+[(X(pos[j]),Y(mu[j]-se[j])) for j in ss[::-1]];svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" fill-opacity=".15"/>');lay=Image.new('RGBA',im.size);ImageDraw.Draw(lay).polygon([(x*Z,y*Z) for x,y in pts],fill=tuple(int(c[k:k+2],16) for k in [1,3,5])+(38,));im.paste(Image.alpha_composite(im.convert('RGBA'),lay).convert('RGB'));path([(X(pos[j]),Y(mu[j])) for j in ss],c,2)
for x in [L,RR]:path([(x,T),(x,B)],'#aaaaaa',1,True)
path([(L+20,T+5),(L+20,T+5+50/250*(B-T))],w=3);text(L+30,T+22,'50 mm/s',14)
path([(X(280),B-20),(X(380),B-20)],w=3);text(X(330),B+2,'100 mm',14,'middle');text(L,B+26,'Start',12,'middle');text(RR,B+26,'Finish',12,'middle')
for j,(lab,c) in enumerate(zip(['SED','WALK','RUN'],colors)):text(L+95,235+j*20,lab,13,'end');path([(L+105,231+j*20),(L+140,231+j*20)],c,2)
scatter('speed',725,75,'Locomoting speed, D0',[50,100,150,200],50,200)
scatter('slips',55,425,'Slip count, D0',[0,20,40,60],0,60)
scatter('stopped',725,425,'Time stopped (%), D0',[0,10,20,30,40],0,40)
# Lower middle eventCDF.
L,RR,T,B=390,640,425,660;grid=np.unique(np.concatenate([v for vv in ev.values() for v in vv]));lo=min(-1,math.floor(np.log10(grid.min())));hi=max(4,math.ceil(np.log10(grid.max())));X=lambda v:L+(np.log10(v)-lo)/(hi-lo)*250;Y=lambda v:B-v*235;text(L,T-24,'Slip-event score, D0',18);cdfrows=[]
for v in [0,.25,.5,.75,1]:path([(L,Y(v)),(RR,Y(v))],'#eeeeee');text(L-7,Y(v)+4,str(v),12,'end')
for v in range(lo,hi+1):path([(X(10**v),B),(X(10**v),B+4)]);text(X(10**v),B+20,str(v),12,'middle')
for g,c in zip(groups,colors):
 vv=ev[g];mu=np.mean([np.searchsorted(np.sort(v),grid,side='right')/len(v) for v in vv],axis=0);pts=[(X(10**lo),Y(0))]
 for j,v in enumerate(grid):pts.extend([(X(v),Y(mu[j-1] if j else 0)),(X(v),Y(mu[j]))]);cdfrows.append(dict(group=g,score=v,CDF=mu[j],nMice=len(vv)))
 pts.append((X(10**hi),Y(1)));path(pts,c,2)
path([(L,T),(L,B),(RR,B)]);text((L+RR)/2,B+43,'log10(slip-event score)',13,'middle')
for j,(lab,c) in enumerate(zip(['SED','WALK','RUN'],colors)):path([(RR-70,B-80+j*20),(RR-45,B-80+j*20)],c,2);text(RR-37,B-76+j*20,lab,12)
text(35,741,'First retained D0 crossing only · 42 mice / 15 cages · speed excludes stops · slip events during stops retained',12)
svg.append('</svg>');stem=O/'D0_first_retained_five_panels';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
for name,rr in [('trial_values',data),('event_validation',audit),('spatial_source',profile_rows),('spatial_summary',summary),('CDF_summary',cdfrows)]:
 with (O/(name+'.csv')).open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(rr[0]));w.writeheader();w.writerows(rr)
(O/'README.md').write_text('''# First-retained D0 reference panels

Requested five-panel layout from attachment ac1d209f-b606-435d-aefd-c13a983fa9c1. Select min original TrialNumber among retained D0 trials for ALL42 mice (12SED/12WALK/18RUN),15cages. Unlike paired complete-triplet panels, includes the mouse with only2retained D0crossings. Source manifest and assets/Tara-BB-trial-data.csv; full filenames saved.

Spatial speed: canonical L40 frame CSVs read in place. Remove StopMask frames before existing10camera-pixel bin means, discard nonfinite samples, preserve gaps. Calibration700/1201mm/px, tape42..1243, entryleft. Equal mouse mean±SEM, bins require halfgroup. No extra smoothing; descriptive SEM not cageCI. Horizontal bar100mm (reference incorrectly says10mm). Scalar speed original meanSpeedLoco, verified reconstructed nonstoppedmean1e-7px/s. Time stopped100*maskcount/framecount, checked manifest. Slip count original nSlips. SlipCDF event score=sum max(MovementTrace−2.5,0) within inclusive eventframes, counts/totals verified1e-6; equal per-mouse ECDF, zero-event mice excluded only from conditionalCDF, all slips including stopoverlaps. See validationtable. Scatter circles mice,diamonds cage means,bars mouse-group means. No newtests; previous all-trial stats must not be attached. All plots first retained trial only. Reproduce tests/plotD0FirstTrialReferencePanels.py. Original results unchanged.
''')
print(stem);print('CDF mice:',{g:len(v) for g,v in ev.items()})
