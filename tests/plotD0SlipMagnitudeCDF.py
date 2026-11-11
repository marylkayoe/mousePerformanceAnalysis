"""Mouse-equally-weighted D0 magnitude ECDFs; no smoothing, binning or clipping."""
from pathlib import Path
import csv,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/figMaterials';src=out/'D0_slip_magnitude_group_histograms.csv';rows=list(csv.DictReader(src.open()));groups=['sedentary','walk','run'];colors=['#232323','#00B226','#002BFF'];curves={};summary={}
for g in groups:
 rs=[r for r in rows if r['Group']==g];mice=sorted({r['MouseID'] for r in rs});vs=[np.sort([float(r['Magnitude']) for r in rs if r['MouseID']==m]) for m in mice];assert all(np.all(np.isfinite(v)) and np.all(v>0) for v in vs)
 x=np.unique(np.concatenate(vs));y=np.mean([np.searchsorted(v,x,side='right')/len(v) for v in vs],axis=0);curves[g]=(x,y);summary[g]=dict(mice=len(mice),cages=len({r['CageID'] for r in rs}),events=len(rs));assert y[-1]==1
W,H,S=700,410,2;im=Image.new('RGB',(W*S,H*S),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=14,anchor='start',color='#222222'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>');f=ImageFont.truetype(font,size*S);w=d.textlength(s,font=f);d.text((x*S-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*S),s,font=f,fill=color)
def line(x,y,xx,yy,c='#333333'):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}"/>');d.line((x*S,y*S,xx*S,yy*S),fill=c,width=2)
X=lambda x:75+(math.log10(x)+1)/5*590
Y=lambda y:320-y*245
text(75,28,'D0 slip-magnitude distributions',22);text(75,50,'Cumulative percentage · equal weight per mouse',14)
for v in (0,.25,.5,.75,1):
 y=Y(v);line(75,y,665,y,'#E6E6E6');text(65,y+4,f'{v*100:g}%',12,'end')
for v in (.1,1,10,100,1000,10000):
 x=X(v);line(x,320,x,325);text(x,343,f'{v:g}',12,'middle')
for j,(g,c) in enumerate(zip(groups,colors)):
 x,y=curves[g];pts=[(X(.1),Y(0))];prev=0
 for a,b in zip(x,y):pts.extend([(X(a),Y(prev)),(X(a),Y(b))]);prev=b
 pts.append((X(10000),Y(1)));svg.append(f'<path id="{g}-ecdf" d="M'+ ' L'.join(f'{a:.5f},{b:.5f}' for a,b in pts)+f'" fill="none" stroke="{c}" stroke-width="1.8"/>');d.line([(a*S,b*S) for a,b in pts],fill=c,width=4)
 ly=242+j*23;line(425,ly-4,450,ly-4,c);text(460,ly,f"{g.upper()} ({summary[g]['mice']} mice)",13,color=c)
line(75,75,75,320);line(75,320,665,320)
text(370,374,'Slip magnitude (a.u. × frames; logarithmic axis)',15,'middle');text(370,400,'All D0 slips, including stops · no clipping or smoothing',12,'middle')
stem=out/'D0_slip_magnitude_group_CDF_mouse_weighted';svg.append('</svg>');stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['Group','Magnitude','MeanMouseCumulativeFraction'])
 for g,(x,y) in curves.items():w.writerows((g,a,b) for a,b in zip(x,y))
stem.with_suffix('.json').write_text(json.dumps(dict(source=str(src),summary=summary,method='For each mouse, empirical fraction of all D0 events <= each magnitude; group curve is arithmetic mean of mouse CDFs. Right-continuous unsmoothed steps. Each mouse equal, cages not equally weighted.',interpretation='Descriptive baseline comparison; overlap is not evidence of equivalence. No statistical tests.',selection='All 900 D0 events including stop overlaps and outside-tape events; no clipping, no zero or nonfinite magnitudes'),indent=2));print(stem)
