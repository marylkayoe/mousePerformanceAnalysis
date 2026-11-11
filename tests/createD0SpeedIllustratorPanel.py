"""D0 locomoting-speed panel styled to the user's Illustrator SVG example."""
from pathlib import Path
import csv,statistics,json,hashlib
from xml.sax.saxutils import escape
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
src=ROOT/'BEAMCROSS/DRAFTFIGS/analysis-data/weighted-speed/speed-days-input.csv'
rows=[r for r in csv.DictReader(src.open()) if r['day']=='D00'];scale=700/1201
for r in rows:r['speedMMPerSecond']=float(r['value'])*scale
W,H=85.45,84.36;zoom=10
im=Image.new('RGB',(round(W*zoom),round(H*zoom)),'white');draw=ImageDraw.Draw(im)
a=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<title>D0 whole-crossing locomoting speed: mouse values, cage means and group means</title>']
def line(x1,y1,x2,y2,color='#262626',width=.5):
 a.append(f'<line x1="{x1:.4f}" y1="{y1:.4f}" x2="{x2:.4f}" y2="{y2:.4f}" stroke="{color}" stroke-width="{width}" stroke-linecap="square"/>');draw.line(tuple(v*zoom for v in (x1,y1,x2,y2)),fill=color,width=max(1,round(width*zoom)))
def text(x,y,s,size=6,anchor='start'):
 a.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="#000000">{escape(s)}</text>')
 draw.text((x*zoom,y*zoom),s,font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',round(size*zoom)),fill='black',anchor={'start':'ls','end':'rs','middle':'ms'}[anchor])
Y=lambda v:71.35-(v-75)*(71.35-12.61)/100
line(13.81,74.49,13.81,11.72)
for v in [75,100,125,150,175]:
 y=Y(v);line(13.81,y,15.22,y)
 if v in [75,125,175]:text(12,y+2,str(v),6,'end')
a.append('<text transform="translate(3.7 56) rotate(-90)" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="6">mm/s</text>')
label=Image.new('RGBA',(200,80));ld=ImageDraw.Draw(label);ld.text((100,40),'mm/s',font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',60),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(0,460),label)
text(14.3,6.87,'Forward speed, D0',7.5)
export=[];counts={}
for g,color,start,stop,cagex,barleft,barright,labelx,label in [('sedentary','#000000',25.82,35.16,21.82,25.15,35.83,24.43,'SED'),('walk','#008d3f',48.72,58.06,44.72,48.05,58.73,44.99,'WALK'),('run','#0864cf',72.92,82.27,68.92,72.26,82.93,70.42,'RUN')]:
 rs=sorted([r for r in rows if r['group']==g],key=lambda r:r['mouseID']);cages={}
 a.append(f'<g id="{g}-mouse-points">')
 for i,r in enumerate(rs):
  x=start+(stop-start)*i/(len(rs)-1);y=Y(r['speedMMPerSecond']);opacity=1 if g=='sedentary' else .4
  a.append(f'<ellipse id="{r["mouseID"]}" cx="{x:.5f}" cy="{y:.5f}" rx="1.14" ry="1.09" fill="{color}" fill-opacity="{opacity}"><title>{r["mouseID"]}: {r["speedMMPerSecond"]:.6f} mm/s</title></ellipse>')
  rgb=tuple(int(color[j:j+2],16) for j in (1,3,5));blend=tuple(round(v*opacity+255*(1-opacity)) for v in rgb)
  draw.ellipse(((x-1.14)*zoom,(y-1.09)*zoom,(x+1.14)*zoom,(y+1.09)*zoom),fill=blend)
  cages.setdefault((r['cohort'],r['cageID']),[]).append(r['speedMMPerSecond']);export.append(r)
 a.append('</g>');a.append(f'<g id="{g}-cage-means">')
 for (co,ca),vs in sorted(cages.items()):
  y=Y(statistics.mean(vs));pts=[(cagex-1.42,y),(cagex,y+1.79),(cagex+1.42,y),(cagex,y-1.79)]
  a.append(f'<polygon id="{co}-{ca}" points="'+ ' '.join(f'{x:.5f},{v:.5f}' for x,v in pts)+f'" fill="{color}" stroke="#231f20" stroke-width=".13"/>');draw.polygon([(x*zoom,v*zoom) for x,v in pts],fill=color,outline='#231f20')
 a.append('</g>');y=Y(statistics.mean(r['speedMMPerSecond'] for r in rs));line(barleft,y,barright,y,color,1);text(labelx,82.42,label)
 counts[g]=dict(mice=len(rs),cages=len(cages),meanMMPerSecond=statistics.mean(r['speedMMPerSecond'] for r in rs))
a.append('</svg>');stem=OUT/'forward_speed_D0_group_comparison_illustrator';stem.with_suffix('.svg').write_text('\n'.join(a));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
meta=dict(source=str(src),sourceSHA256=hashlib.sha256(src.read_bytes()).hexdigest(),metric='Existing mouse-day whole-crossing locomoting speed; stops excluded; original saved aggregation unchanged',conversionMMPerPixel=scale,calibration='Existing approximate 700/1201 mm per pixel',counts=counts,layout='Matches supplied 85.45 x 84.36 Illustrator centroid panel; circles mice, diamonds cage means, lines mouse means. Sorted-ID horizontal spacing is decorative, not another variable.',axis='mm/s, ticks 75/100/125/150/175; no points clipped',statisticalTests='Not recomputed or shown; matches template without p labels')
stem.with_suffix('.json').write_text(json.dumps(meta,indent=2));assert len(rows)==42;print(json.dumps(counts,indent=2))
