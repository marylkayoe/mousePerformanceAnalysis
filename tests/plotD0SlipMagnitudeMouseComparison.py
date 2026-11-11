"""D0 locomoting-speed panel styled to the user's Illustrator SVG example."""
from pathlib import Path
import csv,statistics,json,hashlib
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS'
src=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials/D0_slip_magnitude_group_histograms.csv'
events=list(csv.DictReader(src.open()));by={}
for e in events:by.setdefault(e['MouseID'],[]).append(e)
rows=[]
for mouse,es in sorted(by.items()):
 vals=[float(e['Magnitude']) for e in es];assert all(__import__('math').isfinite(v) for v in vals)
 rows.append(dict(mouseID=mouse,cohort=mouse.split('_')[0],cageID=es[0]['CageID'],group=es[0]['Group'],nSlips=len(vals),nTrials=len({e['File'] for e in es}),meanMagnitude=statistics.mean(vals),medianMagnitude=statistics.median(vals)))
maximum=max(r['meanMagnitude'] for r in rows)
ymax=__import__('math').ceil(maximum/100)*100
W,H=85.45,84.36;zoom=10
im=Image.new('RGB',(round(W*zoom),round(H*zoom)),'white');draw=ImageDraw.Draw(im)
a=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<title>D0 mean slip magnitude: mouse values, cage means and group means</title>']
def line(x1,y1,x2,y2,color='#262626',width=.5):
 a.append(f'<line x1="{x1:.4f}" y1="{y1:.4f}" x2="{x2:.4f}" y2="{y2:.4f}" stroke="{color}" stroke-width="{width}" stroke-linecap="square"/>');draw.line(tuple(v*zoom for v in (x1,y1,x2,y2)),fill=color,width=max(1,round(width*zoom)))
def text(x,y,s,size=6,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#000000">{escape(s)}</text>')
 draw.text((x*zoom,y*zoom),s,font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',round(size*zoom)),fill='black',anchor={'start':'ls','end':'rs','middle':'ms'}[anchor])
Y=lambda v:71.35-v*(71.35-12.61)/ymax
line(13.81,74.49,13.81,11.72)
for v in [0,ymax/4,ymax/2,3*ymax/4,ymax]:
 y=Y(v);line(13.81,y,15.22,y)
 if v in [0,ymax/2,ymax]:text(12,y+2,f'{v:g}',6,'end')
a.append('<text transform="translate(3.7 56) rotate(-90)" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="6">a.u.</text>')
label=Image.new('RGBA',(200,80));ld=ImageDraw.Draw(label);ld.text((100,40),'a.u.',font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',60),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(0,460),label)
text(14.3,6.87,'Mean slip magnitude, D0',5.5)
export=[];counts={}
for g,color,start,stop,cagex,barleft,barright,labelx,label in [('sedentary','#000000',25.82,35.16,21.82,25.15,35.83,24.43,'SED'),('walk','#008d3f',48.72,58.06,44.72,48.05,58.73,44.99,'WALK'),('run','#0864cf',72.92,82.27,68.92,72.26,82.93,70.42,'RUN')]:
 rs=sorted([r for r in rows if r['group']==g],key=lambda r:r['mouseID']);cages={}
 a.append(f'<g id="{g}-mouse-points">')
 for i,r in enumerate(rs):
  x=start+(stop-start)*i/(len(rs)-1);y=Y(r['meanMagnitude']);opacity=1 if g=='sedentary' else .4
  a.append(f'<ellipse id="{r["mouseID"]}" cx="{x:.5f}" cy="{y:.5f}" rx="1.14" ry="1.09" fill="{color}" fill-opacity="{opacity}"><title>{r["mouseID"]}: {r["meanMagnitude"]:.6f} a.u.</title></ellipse>')
  rgb=tuple(int(color[j:j+2],16) for j in (1,3,5));blend=tuple(round(v*opacity+255*(1-opacity)) for v in rgb)
  draw.ellipse(((x-1.14)*zoom,(y-1.09)*zoom,(x+1.14)*zoom,(y+1.09)*zoom),fill=blend)
  cages.setdefault((r['cohort'],r['cageID']),[]).append(r['meanMagnitude']);export.append(r)
 a.append('</g>');a.append(f'<g id="{g}-cage-means">')
 for (co,ca),vs in sorted(cages.items()):
  y=Y(statistics.mean(vs));pts=[(cagex-1.42,y),(cagex,y+1.79),(cagex+1.42,y),(cagex,y-1.79)]
  a.append(f'<polygon id="{co}-{ca}" points="'+ ' '.join(f'{x:.5f},{v:.5f}' for x,v in pts)+f'" fill="{color}" stroke="#231f20" stroke-width=".13"/>');draw.polygon([(x*zoom,v*zoom) for x,v in pts],fill=color,outline='#231f20')
 a.append('</g>');y=Y(statistics.mean(r['meanMagnitude'] for r in rs));line(barleft,y,barright,y,color,1);text(labelx,82.42,label)
 counts[g]=dict(mice=len(rs),cages=len(cages),meanMagnitude=statistics.mean(r['meanMagnitude'] for r in rs))
a.append('</svg>');stem=OUT/'slip_magnitude_D0_mouse_cage_comparison';stem.with_suffix('.svg').write_text('\n'.join(a));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
meta=dict(source=str(src),sourceSHA256=hashlib.sha256(src.read_bytes()).hexdigest(),metric='Arithmetic mean across all detected D0 slips for each mouse, pooled across retained trials; includes stop overlaps and positions outside tape. No event or mouse clipping.',units='Detector area units: sum(max(MovementTrace-2.5,0)), no division by frame rate; not physical displacement',counts=counts,layout='Circles: mice. Diamonds: arithmetic means of mouse means within cages. Bars: arithmetic means of mouse means within groups. Cohort included in cage identity.',axisMaximum=ymax,statisticalTests='Descriptive only; no independent-event tests',aggregation='Each event equally weighted within mouse; each mouse equally weighted in cage and group summaries. No-slip mice would need separate handling; all 42 D0 mice have events.')
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2));assert len(rows)==42;print(json.dumps(counts,indent=2))
