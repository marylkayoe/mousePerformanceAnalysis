"""Three group panels: equally mouse-weighted D0/D14 ECDFs of slip-event score."""
from pathlib import Path
from collections import defaultdict
import csv,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];data=R/'BEAMCROSS/DRAFTFIGS/analysis-data';out=R/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS';read=lambda p:list(csv.DictReader(p.open()))
rows=read(R/'BEAMCROSS/DRAFTFIGS/figMaterials/D0_slip_magnitude_group_histograms.csv')
for r in rows:r['Day']='D00'
by=defaultdict(list)
for e in read(data/'events.csv'):
 if e['Day']=='14' and e['Type']=='slip':by[e['File']].append(e)
source=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')
for filename,es in by.items():
 trace=read(source/(filename+'.trace.csv'))
 for e in es:
  a,b=int(e['StartTraversalFrame']),int(e['EndTraversalFrame']);v=[float(x['MovementTrace']) for x in trace[a-1:b]];assert len(v)==b-a+1 and all(math.isfinite(z) for z in v)
  rows.append(dict(File=filename,MouseID=e['MouseID'],CageID=e['CageID'],Group=e['Group'],Day='D14',EventNumber=e['EventNumber'],Magnitude=sum(max(z-2.5,0) for z in v)))
validation=[]
for r in read(data/'pooled-exposures.csv'):
 if r['day'] not in ('D00','D14'):continue
 val=sum(float(e['Magnitude']) for e in rows if e['MouseID']==r['mouseID'] and e['Day']==r['day']);expected=float(r['combinedSlipMagnitude']);assert math.isclose(val,expected,rel_tol=1e-6,abs_tol=1e-6)
 validation.append(dict(MouseID=r['mouseID'],Day=r['day'],Reconstructed=val,Saved=expected))
assert all(math.isfinite(float(r['Magnitude'])) and float(r['Magnitude'])>0 for r in rows)
groups=['sedentary','walk','run'];colors=['#232323','#00B226','#002BFF'];curves={};summary={}
for g in groups:
 sets=[]
 for day in ('D00','D14'):
  rs=[r for r in rows if r['Group']==g and r['Day']==day];mice=sorted({r['MouseID'] for r in rs});sets.append(set(mice));vs=[np.sort([float(r['Magnitude']) for r in rs if r['MouseID']==m]) for m in mice]
  x=np.unique(np.concatenate(vs));y=np.mean([np.searchsorted(v,x,side='right')/len(v) for v in vs],axis=0);assert y[-1]==1
  curves[g,day]=(x,y);summary[g+'_'+day]=dict(mice=len(mice),cages=len({r['CageID'] for r in rs}),events=len(rs))
 assert sets[0]==sets[1]
lo=math.floor(math.log10(min(float(r['Magnitude']) for r in rows)));hi=math.ceil(math.log10(max(float(r['Magnitude']) for r in rows)))
W,H,Z=1050,340,2;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=13,anchor='start',color='#232323'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>');d.text((x*Z,y*Z),s,font=ImageFont.truetype(font,size*Z),fill=color,anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,c='#333333',w=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{c}" stroke-width="{w}" fill="none"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=round(w*Z))
for j,(g,c) in enumerate(zip(groups,colors)):
 L=45+350*j;RR=L+290;T=68;B=270;X=lambda v:L+(math.log10(v)-lo)/(hi-lo)*(RR-L);Y=lambda v:B-v*(B-T)
 text((L+RR)/2,24,g.upper(),19,'middle',c);text((L+RR)/2,44,f"{summary[g+'_D00']['mice']} mice · D0: {summary[g+'_D00']['events']} / D14: {summary[g+'_D14']['events']} events",10,'middle')
 for a in (0,.25,.5,.75,1):
  y=Y(a);line(L,y,RR,y,'#e5e5e5');text(L-6,y+4,f'{100*a:g}%',10,'end')
 for a in range(lo,hi+1):
  x=X(10**a);line(x,B,x,B+4);text(x,B+18,f'{10**a:g}',10,'middle')
 for day,col in [('D00','#999999'),('D14',c)]:
  x,y=curves[g,day];pts=[(X(10**lo),Y(0))];prev=0
  for a,b in zip(x,y):pts.extend([(X(a),Y(prev)),(X(a),Y(b))]);prev=b
  pts.append((X(10**hi),Y(1)));svg.append(f'<path id="{g}-{day}" d="M'+' L'.join(f'{a:.5f},{b:.5f}' for a,b in pts)+f'" fill="none" stroke="{col}" stroke-width="1.8"/>');d.line([(a*Z,b*Z) for a,b in pts],fill=col,width=4)
 line(L,T,L,B);line(L,B,RR,B)
 for k,(label,col) in enumerate([('D0','#999999'),('D14',c)]):
  y=215+k*21;line(RR-75,y,RR-52,y,col,2);text(RR-44,y+4,label,12)
text(W/2,316,'Slip-event score (a.u. × frames; logarithmic axis)',14,'middle');text(W/2,336,'Mean of individual mouse CDFs · all slips, including during stops · no clipping or smoothing',11,'middle')
stem=out/'slip_score_CDF_D0_D14_by_group';svg.append('</svg>');stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['Group','Day','Score','MeanMouseCumulativeFraction'])
 for (g,day),(x,y) in curves.items():w.writerows((g,day,a,b) for a,b in zip(x,y))
stem.with_suffix('.json').write_text(json.dumps(dict(summary=summary,method='Equal-weight mean of per-mouse right-continuous ECDFs; identical mouse sets on D0 and D14; all retained crossings including two-crossing D0 mouse. All slips including stop overlaps and outside tape; no new clipping/smoothing/binning. No inferential tests; cages not equally weighted.',score='Sum max(MovementTrace-2.5,0) over inclusive slip frames',validation='All 84 reconstructed mouse-day totals match saved combinedSlipMagnitude at rtol=1e-6 atol=1e-6; all scores finite and positive',sourceD0='figMaterials/D0_slip_magnitude_group_histograms.csv',sourceD14=str(source),logLimits=[10**lo,10**hi]),indent=2));print(json.dumps(summary))
