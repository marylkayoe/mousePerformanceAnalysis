"""D0 locomoting-speed panel styled to the user's Illustrator SVG example."""
from pathlib import Path
import csv,statistics,json,hashlib
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
import sys
kind=sys.argv[1] if len(sys.argv)>1 else 'slip'
assert kind in ('slip','stop')
field='combinedSlips' if kind=='slip' else 'combinedStops'
src=ROOT/'BEAMCROSS/DRAFTFIGS/analysis-data/pooled-exposures.csv'
rows=[r for r in csv.DictReader(src.open()) if r['day']=='D00' and int(r['nRuns'])==3]
for r in rows:r['count']=float(r[field]);assert r['count'].is_integer()
ymax=60 if kind=='slip' else 25
W,H=85.45,84.36;zoom=10
im=Image.new('RGB',(round(W*zoom),round(H*zoom)),'white');draw=ImageDraw.Draw(im)
a=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<title>D0 event counts: mouse values, cage means and group means</title>']
def line(x1,y1,x2,y2,color='#262626',width=.5):
 a.append(f'<line x1="{x1:.4f}" y1="{y1:.4f}" x2="{x2:.4f}" y2="{y2:.4f}" stroke="{color}" stroke-width="{width}" stroke-linecap="square"/>');draw.line(tuple(v*zoom for v in (x1,y1,x2,y2)),fill=color,width=max(1,round(width*zoom)))
def text(x,y,s,size=6,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#000000">{escape(s)}</text>')
 draw.text((x*zoom,y*zoom),s,font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',round(size*zoom)),fill='black',anchor={'start':'ls','end':'rs','middle':'ms'}[anchor])
Y=lambda v:71.35-v*(71.35-12.61)/ymax
line(13.81,74.49,13.81,11.72)
for v in (range(0,61,10) if kind=='slip' else range(0,26,5)):
 y=Y(v);line(13.81,y,15.22,y)
 if kind=='stop' or v%20==0:text(12,y+2,f'{v:g}',6,'end')
text(14.3,6.87,('Slip count, D0' if kind=='slip' else 'Stop count, D0'),7.5)
export=[];counts={}
for g,color,start,stop,cagex,barleft,barright,labelx,label in [('sedentary','#000000',25.82,35.16,21.82,25.15,35.83,24.43,'SED'),('walk','#008d3f',48.72,58.06,44.72,48.05,58.73,44.99,'WALK'),('run','#0864cf',72.92,82.27,68.92,72.26,82.93,70.42,'RUN')]:
 rs=sorted([r for r in rows if r['group']==g],key=lambda r:r['mouseID']);cages={}
 a.append(f'<g id="{g}-mouse-points">')
 for i,r in enumerate(rs):
  x=start+(stop-start)*i/(len(rs)-1);y=Y(r['count']);opacity=1 if g=='sedentary' else .4
  a.append(f'<ellipse id="{r["mouseID"]}" cx="{x:.5f}" cy="{y:.5f}" rx="1.14" ry="1.09" fill="{color}" fill-opacity="{opacity}"><title>{r["mouseID"]}: {r["count"]:.6f} count</title></ellipse>')
  rgb=tuple(int(color[j:j+2],16) for j in (1,3,5));blend=tuple(round(v*opacity+255*(1-opacity)) for v in rgb)
  draw.ellipse(((x-1.14)*zoom,(y-1.09)*zoom,(x+1.14)*zoom,(y+1.09)*zoom),fill=blend)
  cages.setdefault((r['cohort'],r['cageID']),[]).append(r['count']);export.append(r)
 a.append('</g>');a.append(f'<g id="{g}-cage-means">')
 for (co,ca),vs in sorted(cages.items()):
  y=Y(statistics.mean(vs));pts=[(cagex-1.42,y),(cagex,y+1.79),(cagex+1.42,y),(cagex,y-1.79)]
  a.append(f'<polygon id="{co}-{ca}" points="'+ ' '.join(f'{x:.5f},{v:.5f}' for x,v in pts)+f'" fill="{color}" stroke="#231f20" stroke-width=".13"/>');draw.polygon([(x*zoom,v*zoom) for x,v in pts],fill=color,outline='#231f20')
 a.append('</g>');y=Y(statistics.mean(r['count'] for r in rs));line(barleft,y,barright,y,color,1);text(labelx,82.42,label)
 counts[g]=dict(mice=len(rs),cages=len(cages),count=statistics.mean(r['count'] for r in rs))
a.append('</svg>');stem=(ROOT/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS' if kind=='slip' else OUT)/(kind+'_count_D0_mouse_cage_comparison');stem.with_suffix('.svg').write_text('\n'.join(a));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
expected={'slip':[25.67,21.33,19.35],'stop':[8.83,5.92,6.53]}[kind]
assert all(abs(counts[g]['count']-e)<.006 for g,e in zip(('sedentary','walk','run'),expected))
meta=dict(source=str(src),sourceSHA256=hashlib.sha256(src.read_bytes()).hexdigest(),metric=f'Total detected {kind}s across three retained D0 crossings per mouse',counts=counts,layout='Circles: mice; diamonds: cage means; bars: equally weighted mouse group means. Existing Illustrator-style panel dimensions and palette.',exclusion='TMCS2_S10 excluded because only two retained D0 crossings; same rule as original count-statistics panels.',slipOverlapPolicy='Slips during stops included',validation='41 mice; group means match saved D0 descriptive table to printed precision',statisticalTests='Not recomputed or displayed',axisMaximum=ymax)
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2));assert len(rows)==41;print(kind,json.dumps(counts))
