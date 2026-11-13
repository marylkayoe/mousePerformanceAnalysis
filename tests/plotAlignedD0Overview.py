"""Rebuild supplied six-panel D0 overview without anisotropic transforms."""
from pathlib import Path
from collections import defaultdict
import csv,statistics,runpy,json,math
R=Path(__file__).resolve().parents[1];D=R/'BEAMCROSS/DRAFTFIGS';I=D/'D0-first-trial-panels';O=I/'aligned-overview';O.mkdir(exist_ok=True)
rows=list(csv.DictReader((I/'trial_values.csv').open()));tot={r['file']:float(r['eventSum']) for r in csv.DictReader((I/'event_validation.csv').open())};ps={r['metric']:float(r['p_raw']) for r in csv.DictReader((I/'group_statistics.csv').open())};data=[dict(r,value=tot[r['file']]) for r in rows];om,pairs=runpy.run_path(str(D/'tail-metrics/whole-motion-reweighted/cage_tests.py'))['test'](data);ps['total']=om
W,H=282,180;S=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>'];colors=['#232323','#008d3f','#0864cf'];pale=['#a7a7a7','#99d1b2','#9cc1ec'];groups=['sedentary','walk','run']
def text(x,y,s,size=5,anchor='start'):S.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="#232323">{s}</text>')
def line(p,c='#262626',w=.4,dash=None):S.append('<polyline points="'+' '.join(f'{x:.5f},{y:.5f}' for x,y in p)+f'" fill="none" stroke="{c}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"'+(f' stroke-dasharray="{dash}"' if dash else '')+'/>')
def rect(x,y,w,h,c):S.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"/>')
for k,(key,title,unit,lo,hi,ticks) in enumerate([('speed','Locomoting speed, D0','mm/s',50,200,[50,100,150,200]),('stopped','Time stopped, D0','%',0,40,[0,10,20,30,40]),('slips','Slip count, D0','count',0,20,[0,5,10,15,20]),('total','Total slip score, D0','10³ a.u. × frames',0,None,None)]):
 col=k%2;row=k//2;L=130+col*79;T=17+row*86;B=T+58;PW=63;vals=[(tot[r['file']]/1000 if key=='total' else float(r[key])) for r in rows]
 if hi is None:hi=max(2,2*math.ceil(max(vals)/2));ticks=list(range(0,int(hi)+1,2))
 assert min(vals)>=lo and max(vals)<=hi
 Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
 text(L-2,T-10,title,5.8);text(L,T-3,unit,3.6);line([(L,T),(L,B)])
 for v in ticks:line([(L,Y(v)),(L+1,Y(v))]);text(L-2,Y(v)+1.7,f'{v:g}',5,'end')
 text(L+PW-1,T+6,f'p = {ps[key]:.3f}',4.4,'end')
 for j,g in enumerate(groups):
  rr=[(r,v) for r,v in zip(rows,vals) if r['group']==g];cx=L+13+j*22.5;cells=defaultdict(list)
  for ii,(r,v) in enumerate(rr):
   x=cx-4.7+9.4*ii/max(1,len(rr)-1);y=Y(v);S.append(f'<circle cx="{x}" cy="{y}" r="1.1" fill="{pale[j]}"/>');cells[r['cohort'],r['cageID']].append(v)
  for vv in cells.values():
   x=cx-8;y=Y(statistics.mean(vv));S.append(f'<polygon points="{x-1.35},{y} {x},{y-1.7} {x+1.35},{y} {x},{y+1.7}" fill="{colors[j]}" stroke="#231f20" stroke-width=".13"/>')
  y=Y(statistics.mean(v for r,v in rr));line([(cx-5,y),(cx+5,y)],colors[j],.9);text(cx,B+6,['SED','WALK','RUN'][j],5,'middle')
# speed spatial profile: same first retained data, physical scale bars
sp=list(csv.DictReader((I/'spatial_summary.csv').open()));L,RR,T,B=13,111,17,75;X=lambda p:L+p/700*(RR-L);Y=lambda v:B-v/240*(B-T)
text(L-2,7,'Locomoting speed along the beam, D0',5.3)
for g,c in zip(groups,colors):
 rr=[r for r in sp if r['group']==g];points=[(X(float(r['positionMM'])),Y(float(r['mean'])+float(r['SEM']))) for r in rr]+[(X(float(r['positionMM'])),Y(float(r['mean'])-float(r['SEM']))) for r in rr[::-1]];S.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in points)+f'" fill="{c}" opacity=".18"/>');line([(X(float(r['positionMM'])),Y(float(r['mean']))) for r in rr],c,.8)
for x,s in [(L,'Start'),(RR,'Finish')]:line([(x,T),(x,B)],'#999999',.4,'2 1.5');text(x,B+6,s,4.5,'middle')
line([(L+4,T+4),(L+4,T+4+50/240*(B-T))],w=.9);text(L+7,T+8,'50 mm/s',4.5)
line([(57,70),(57+100/700*(RR-L),70)],w=.9);text(64,76,'100 mm',4.5,'middle');text(RR-2,T+6,f'p = {ps["speed_profile"]:.3f}',4.4,'end')
for j,c in enumerate(colors):text(26,54+j*5,['SED','WALK','RUN'][j],4.5);line([(41,52.5+j*5),(48,52.5+j*5)],c,.8)
# preserved pooled histogram, stops up / slips down
hh=list(csv.DictReader((D/'figMaterials/D0_pooled_event_positions_10mm_mirrored.csv').open()));T,B=103,161;mid=132;L,RR=13,111;X=lambda p:L+p/700*(RR-L)
text(L-2,93,'Event positions, pooled D0',5.8);text(L,100,'Event count',3.6)
for r in hh:
 x=X(float(r['DistanceFromEntryBinStartMM']));w=10/700*(RR-L);a=float(r['Stops'])/40*27;b=float(r['SlipsOutsideStops'])/20*27;rect(x,mid-a,w,a,'#a9bdc9');rect(x,mid,w,b,'#edb185')
line([(L,T),(L,B)]);line([(L,mid),(RR,mid)])
for v in [0,20,40]:y=mid-v/40*27;line([(L,y),(L+1,y)]);text(L-2,y+1.7,str(v),5,'end')
for v in [10,20]:y=mid+v/20*27;line([(L,y),(L+1,y)]);text(L-2,y+1.7,str(v),5,'end')
text(26,113,'Stops',5);text(26,155,'Slips',5)
for x,s in [(L,'Start'),(RR,'Finish')]:text(x,B+6,s,4.5,'middle')
line([(86,114),(86+10/700*(RR-L),114)],w=.9);text(88,120,'10 mm',4.5,'middle')
text(13,177,'Group panels: first retained D0 crossing · mice/cage means · histogram: pooled D0 crossings',3.4)
S.append('</svg>');(O/'D0_aligned_overview_total_slip_score.svg').write_text('\n'.join(S))
(O/'statistics.json').write_text(json.dumps(dict(p_values=ps,totalSlipScorePairs=pairs),indent=2))
with (O/'total_slip_score_mouse_values.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
(O/'README.md').write_text('''# Aligned D0 overview

Rebuilt supplied six-panel layout in native SVG coordinates; no anisotropic scaling. Four scatter axes share width63/height58; fonts Arial5 for both axis directions, titles5.8 (long spatial title5.3); circular mouse markers radius1.1, identical cage diamonds and mean bars throughout. P-values inside panels formatted p = xxx. Speed trajectory uses unchanged source means/SEM; scale bars retain physical100mm and50mm/s. Histogram retains pooled validated10mm counts, stops up/slips down. No group hypothesis test applies to the pooled histogram; no p invented.

Group panels/spatial speed: first retained D0 per mouse,42mice/15cages, not necessarily original trial1. Scalar speed, stops%, slip count and spatial p values retained from existing first-trial workflow. CDF replaced by total slip score=sum over event scores within crossing (each event=sum max(MovementTrace-2.5,0)); values independently reconstructed/validated in event_validation.csv. All detected slips included, including stop overlap. Display total/1000; cage/cohort permutation test recomputed on unscaled totals using existing cage_tests.py. Raw exploratory omnibus p; no across-metric correction. Pairwise data in JSON, not displayed. Not mean slip-event size.

Pooled histogram is NOT restricted to first crossings: existing592 slips outside stops and262 stops preserved. Its crossing denominator was previously unresolved; not used for normalization. This selection differs from scatters and is noted on figure. Original supplied SVG and prior outputs preserved. No analytical source changes. Reproduce tests/plotAlignedD0Overview.py.
''')
print('total slip score omnibus:',om,'max display:',max(tot.values())/1000)
