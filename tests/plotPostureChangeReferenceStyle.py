"""D0 locomoting-speed panel styled to the user's Illustrator SVG example."""
from pathlib import Path
import csv,statistics,json,hashlib
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS'
OUT=ROOT/'BEAMCROSS/DRAFTFIGS/posture-presentation'
src=ROOT/'BEAMCROSS/DRAFTFIGS/analysis-data/posture-statistics/tail-changes.csv'
rows=[r for r in csv.DictReader(src.open()) if r['day']=='D14']
for r in rows:r['count']=float(r['value'])*700/1201
ymax=3
W,H=92.92,83.93;zoom=10
im=Image.new('RGB',(round(W*zoom),round(H*zoom)),'white');draw=ImageDraw.Draw(im)
a=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<title>D0 percentage of traversal time stopped: mouse values, cage means and group means</title>']
def line(x1,y1,x2,y2,color='#262626',width=.5):
 a.append(f'<line x1="{x1:.4f}" y1="{y1:.4f}" x2="{x2:.4f}" y2="{y2:.4f}" stroke="{color}" stroke-width="{width}" stroke-linecap="square"/>');draw.line(tuple(v*zoom for v in (x1,y1,x2,y2)),fill=color,width=max(1,round(width*zoom)))
def text(x,y,s,size=6,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#000000">{escape(s)}</text>')
 draw.text((x*zoom,y*zoom),s,font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',round(size*zoom)),fill='black',anchor={'start':'ls','end':'rs','middle':'ms'}[anchor])
Y=lambda v:70.92-(v+3)*58.74/6
line(17.38,74.06,17.38,11.29)
for v in [-3,-1.5,0,1.5,3]:
 y=Y(v);line(17.38,y,18.79,y)
 text(15,y+2,f'{v:g}',6,'end')
text(17.87,6.44,'Posture change, D14−D0',6.5)
a.append('<text transform="translate(4 43) rotate(-90)" text-anchor="middle" font-family="Arial" font-size="6">mm</text>')
label=Image.new('RGBA',(180,70));ld=ImageDraw.Draw(label);ld.text((90,35),'mm',font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',60),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(0,340),label)
line(18.79,Y(0),87,Y(0),'#bbbbbb',.25)
export=[];counts={}
for g,color,start,stop,cagex,barleft,barright,labelx,label in [('sedentary','#000000',25.82,35.16,21.82,25.15,35.83,24.43,'SED'),('walk','#008d3f',48.72,58.06,44.72,48.05,58.73,44.99,'WALK'),('run','#0864cf',72.92,82.27,68.92,72.26,82.93,70.42,'RUN')]:
 start+=3.57;stop+=3.57;cagex+=3.57;barleft+=3.57;barright+=3.57;labelx+=3.57
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
 a.append('</g>');y=Y(statistics.mean(r['count'] for r in rs));line(barleft,y,barright,y,color,1);text(labelx,81.99,label)
 counts[g]=dict(mice=len(rs),cages=len(cages),count=statistics.mean(r['count'] for r in rs))
a.append('</svg>');stem=OUT/'posture_change_scatter_reference_style';stem.with_suffix('.svg').write_text('\n'.join(a));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
meta=dict(source=str(src),conversionMMPerPixel=700/1201,counts=counts,style='Reference 92.92 x83.93; Arial6 ticks, .5 axes, original black/green/blue colours, filled cage diamonds with .13 border, coloured mouse alpha .4; title reduced to6.5 to fit change label',ticks=[-3,-1.5,0,1.5,3],valuesUnchanged=True)
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2));assert len(rows)==42
