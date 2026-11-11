"""D0 event-weighted magnitude distributions, all slips including stops/outside tape."""
import csv,json,math,hashlib
from pathlib import Path
from collections import defaultdict
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];data=R/'BEAMCROSS/DRAFTFIGS/analysis-data';out=R/'BEAMCROSS/DRAFTFIGS/figMaterials';source=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')
read=lambda p:list(csv.DictReader(p.open()))
trials=[r for r in read(data/'trial_manifest.csv') if r['Day']=='0'];events=defaultdict(list)
for e in read(data/'events.csv'):
 if e['Day']=='0':events[e['File']].append(e)
rows=[];issues=[]
for t in trials:
 file=t['File'];es=events[file];slips=[e for e in es if e['Type']=='slip'];stops=[e for e in es if e['Type']=='stop']
 if len(slips)!=int(t['NSlips']):issues.append({'File':file,'issue':'Event count mismatch'})
 trace=read(source/(file+'.trace.csv'))
 for e in slips:
  a,b=int(e['StartTraversalFrame']),int(e['EndTraversalFrame']);values=[float(r['MovementTrace']) for r in trace[a-1:b]]
  assert len(values)==b-a+1
  valid=all(math.isfinite(v) for v in values);mag=sum(max(v-2.5,0) for v in values) if valid else float('nan')
  rows.append(dict(File=file,MouseID=t['MouseID'],CageID=t['CageID'],Group=t['Group'],EventNumber=e['EventNumber'],StartTraversalFrame=a,EndTraversalFrame=b,StartOriginalFrame=e['StartOriginalFrame'],EndOriginalFrame=e['EndOriginalFrame'],Magnitude=mag,Finite=int(valid),OverlapsStop=int(any(int(s['StartTraversalFrame'])<=b and int(s['EndTraversalFrame'])>=a for s in stops))))
# Check reconstructed event sums against existing independently saved mouse-day totals.
validation=[]
for r in read(data/'pooled-exposures.csv'):
 if r['day']!='D00':continue
 actual=sum(e['Magnitude'] for e in rows if e['MouseID']==r['mouseID']);expected=float(r['combinedSlipMagnitude']);ok=math.isclose(actual,expected,rel_tol=1e-6,abs_tol=1e-6)
 validation.append(dict(MouseID=r['mouseID'],Reconstructed=actual,Saved=expected,Match=ok))
 if not ok:issues.append(validation[-1])
values=np.array([r['Magnitude'] for r in rows if r['Finite']]);q1,q3=np.percentile(values,[25,75]);fd=2*(q3-q1)/len(values)**(1/3);nb=min(80,max(15,math.ceil(values.max()/fd)));edges=np.linspace(0,math.ceil(values.max()/100)*100,nb+1)
groups=['sedentary','walk','run'];cols=['#232323','#00B226','#002BFF'];hist={g:np.histogram([r['Magnitude'] for r in rows if r['Group']==g and r['Finite']],edges)[0] for g in groups};ymax=math.ceil(max(100*h.max()/h.sum() for h in hist.values())/5)*5
W,H,S=760,620,2;im=Image.new('RGB',(W*S,H*S),'white');draw=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=14,anchor='start',color='#222222'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>');f=ImageFont.truetype(font,size*S);w=draw.textlength(s,font=f);draw.text((x*S-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*S),s,font=f,fill=color)
def line(x,y,xx,yy,col='#222222'):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{col}" fill="none"/>');draw.line((x*S,y*S,xx*S,yy*S),fill=col,width=2)
text(75,29,'D0 slip magnitudes',23);text(75,52,'All detected slips, including those during stops',14)
summary={}
for j,(g,col) in enumerate(zip(groups,cols)):
 top=94+j*160;bottom=top+115;h=hist[g];rs=[r for r in rows if r['Group']==g];n=len(rs);summary[g]=dict(events=n,mice=len({r['MouseID'] for r in rs}),cages=len({r['CageID'] for r in rs}),trials=sum(t['Group']==g for t in trials),median=float(np.median([r['Magnitude'] for r in rs])),maximum=max(r['Magnitude'] for r in rs))
 text(75,top-10,g.upper(),16,color=col);text(710,top-10,f"{n} events · {summary[g]['mice']} mice",13,'end')
 for v in (0,ymax/2,ymax):
  y=bottom-v/ymax*115;line(75,y,710,y,'#E5E5E5');text(65,y+4,f'{v:g}%',12,'end')
 for i,v in enumerate(h):
  x=75+i*635/nb;w=635/nb;bh=(100*v/h.sum())/ymax*115;y=bottom-bh
  svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{bh}" fill="{col}"/>');draw.rectangle((x*S,y*S,(x+w)*S,bottom*S),fill=col)
 line(75,top,75,bottom);line(75,bottom,710,bottom)
 for v in np.linspace(0,edges[-1],5):
  x=75+v/edges[-1]*635;line(x,bottom,x,bottom+4);text(x,bottom+20,f'{v:g}',12,'middle')
text(392,586,'Slip magnitude (sum above threshold; a.u. × frames)',15,'middle');text(392,609,'Percentage of events within each group · common linear bins and axes',12,'middle')
stem=out/'D0_slip_magnitude_group_histograms';svg.append('</svg>');stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
stem.with_suffix('.json').write_text(json.dumps(dict(definition='sum(max(MovementTrace-2.5,0)) over saved inclusive event frames, no division by fps',selection='All D0 slips; no stop-overlap or position exclusions',summary=summary,binEdges=edges.tolist(),binRule='Pooled Freedman-Diaconis count capped at 80 bins; axis upper limit rounded up to 100',nonfiniteEvents=sum(not r['Finite'] for r in rows),validation=validation,issues=issues,source=str(source),caveat='Event weighted descriptive distribution; events not independent animals, trial-normalized detector magnitudes not physical displacement'),indent=2))
print(json.dumps(dict(summary=summary,bins=nb,maximum=float(values.max()),issues=issues,validatedMouseTotals=len(validation)),indent=2))
