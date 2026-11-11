"""D0 locomoting-speed panel styled to the user's Illustrator SVG example."""
from pathlib import Path
import csv,statistics,json,hashlib
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
import sys
mode=sys.argv[1] if len(sys.argv)>1 else 'D14'
assert mode in ('D14','change')
kind='slip'
src=ROOT/'BEAMCROSS/DRAFTFIGS/analysis-data/pooled-exposures.csv'
allrows=list(csv.DictReader(src.open()))
lookup={(r['mouseID'],r['day']):r for r in allrows if int(r['nRuns'])==3}
rows=[]
for r in allrows:
 if r['day']!='D14' or int(r['nRuns'])!=3:continue
 if mode=='change' and (r['mouseID'],'D00') not in lookup:continue
 r=r.copy();r['D14Score']=float(r['combinedSlipMagnitude'])
 r['D0Score']=float(lookup[r['mouseID'],'D00']['combinedSlipMagnitude']) if (r['mouseID'],'D00') in lookup else ''
 r['count']=r['D14Score']-(r['D0Score'] if mode=='change' else 0)
 rows.append(r)
ymin,ymax=(0,12000) if mode=='D14' else (-12000,12000)
W,H=85.45,84.36;zoom=10
im=Image.new('RGB',(round(W*zoom),round(H*zoom)),'white');draw=ImageDraw.Draw(im)
a=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<title>Slip counts: mouse values, cage means and group means</title>']
def line(x1,y1,x2,y2,color='#262626',width=.5):
 a.append(f'<line x1="{x1:.4f}" y1="{y1:.4f}" x2="{x2:.4f}" y2="{y2:.4f}" stroke="{color}" stroke-width="{width}" stroke-linecap="square"/>');draw.line(tuple(v*zoom for v in (x1,y1,x2,y2)),fill=color,width=max(1,round(width*zoom)))
def text(x,y,s,size=6,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#000000">{escape(s)}</text>')
 draw.text((x*zoom,y*zoom),s,font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',round(size*zoom)),fill='black',anchor={'start':'ls','end':'rs','middle':'ms'}[anchor])
Y=lambda v:71.35-(v-ymin)*(71.35-12.61)/(ymax-ymin)
line(13.81,74.49,13.81,11.72)
for v in (range(0,12001,4000) if mode=='D14' else range(-10000,10001,5000)):
 y=Y(v);line(13.81,y,15.22,y)
 text(12,y+2,f'{v/1000:g}',6,'end')
text(14.3,6.87,('Total slip score, D14' if mode=='D14' else 'Total slip score, D14−D0'),5.7)
text(1,11,'×10³ a.u.',3.5)
if mode=='change':line(15.22,Y(0),84,Y(0),'#bbbbbb',.3)
export=[];counts={}
for g,color,start,stop,cagex,barleft,barright,labelx,label in [('sedentary','#000000',25.82,35.16,21.82,25.15,35.83,24.43,'SED'),('walk','#008d3f',48.72,58.06,44.72,48.05,58.73,44.99,'WALK'),('run','#0864cf',72.92,82.27,68.92,72.26,82.93,70.42,'RUN')]:
 rs=sorted([r for r in rows if r['group']==g],key=lambda r:r['mouseID']);cages={}
 a.append(f'<g id="{g}-mouse-points">')
 for i,r in enumerate(rs):
  x=start+(stop-start)*i/(len(rs)-1);y=Y(r['count']);opacity=1 if g=='sedentary' else .4
  a.append(f'<ellipse id="{r["mouseID"]}" cx="{x:.5f}" cy="{y:.5f}" rx="1.14" ry="1.09" fill="{color}" fill-opacity="{opacity}"><title>{r["mouseID"]}: {r["count"]:.6f} a.u.</title></ellipse>')
  rgb=tuple(int(color[j:j+2],16) for j in (1,3,5));blend=tuple(round(v*opacity+255*(1-opacity)) for v in rgb)
  draw.ellipse(((x-1.14)*zoom,(y-1.09)*zoom,(x+1.14)*zoom,(y+1.09)*zoom),fill=blend)
  cages.setdefault((r['cohort'],r['cageID']),[]).append(r['count']);export.append(r)
 a.append('</g>');a.append(f'<g id="{g}-cage-means">')
 for (co,ca),vs in sorted(cages.items()):
  y=Y(statistics.mean(vs));pts=[(cagex-1.42,y),(cagex,y+1.79),(cagex+1.42,y),(cagex,y-1.79)]
  a.append(f'<polygon id="{co}-{ca}" points="'+ ' '.join(f'{x:.5f},{v:.5f}' for x,v in pts)+f'" fill="{color}" stroke="#231f20" stroke-width=".13"/>');draw.polygon([(x*zoom,v*zoom) for x,v in pts],fill=color,outline='#231f20')
 a.append('</g>');y=Y(statistics.mean(r['count'] for r in rs));line(barleft,y,barright,y,color,1);text(labelx,82.42,label)
 counts[g]=dict(mice=len(rs),cages=len(cages),count=statistics.mean(r['count'] for r in rs))
a.append('</svg>');stem=(ROOT/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS' if kind=='slip' else OUT)/('slip_magnitude_'+('D14' if mode=='D14' else 'D14_minus_D0')+'_mouse_cage_comparison');stem.with_suffix('.svg').write_text('\n'.join(a));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
meta=dict(source=str(src),sourceSHA256=hashlib.sha256(src.read_bytes()).hexdigest(),metric='Sum of slip-event scores across three retained crossings per mouse' if mode=='D14' else 'Paired D14 minus D0 change in summed slip-event scores across three retained crossings per day',counts=counts,layout='Circles: mice; diamonds: cohort-specific cage means; bars: equally weighted mouse means. Standard Illustrator palette and dimensions.',exclusion='Require three retained crossings for each included day; change excludes TMCS2_S10 with only two D0 crossings. D14 includes that mouse.',slipOverlapPolicy='Slips during stops included, matching existing D0 count panel',statisticalTests='Not recomputed or displayed',axisMinimum=ymin,axisMaximum=ymax,axisDisplayMultiplier=1000,scoreDefinition='Saved combinedSlipMagnitude; untransformed sum, including slips during stops. No clipping or normalization added.')
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2))
assert len(rows)==(42 if mode=='D14' else 41)
assert all(ymin<=r['count']<=ymax for r in rows)
print(mode,json.dumps(counts))
