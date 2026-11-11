"""Speed change panel matching the supplied 254.16 x 86.21 Illustrator layout.
Uses saved paired profiles and whole-trial summaries; no new smoothing or tests.
"""
from pathlib import Path
import runpy, csv, statistics, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from xml.sax.saxutils import escape
R=Path(__file__).resolve().parents[1]
v=runpy.run_path(str(R/'tests/plotSpeedChangeClean.py'))
out=v['out']; W,H,Z=254.16,86.21,8
im=Image.new('RGB',(round(W*Z),round(H*Z)),'white');d=ImageDraw.Draw(im)
s=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">']
font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=5,anchor='start',rotate=False):
 transform=f'transform="translate({x} {y}) rotate(-90)"' if rotate else f'x="{x}" y="{y}"'
 s.append(f'<text {transform} font-family="Arial" font-size="{size}" text-anchor="{anchor}">{escape(t)}</text>')
 f=ImageFont.truetype(font,round(size*Z))
 if rotate:
  lay=Image.new('RGBA',(round(50*Z),round(10*Z)));ld=ImageDraw.Draw(lay);ld.text((25*Z,5*Z),t,font=f,fill='black',anchor='mm');lay=lay.rotate(90,expand=True);im.paste(lay,(round(x*Z-lay.width/2),round(y*Z-lay.height/2)),lay)
 else:d.text((x*Z,y*Z),t,font=f,fill='black',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,c='#232323',w=.5,dash=False):
 s.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{w}"'+(' stroke-dasharray="1.5 1.2"' if dash else '')+'/>')
 if dash:
  for a in np.arange(y,yy,2.7):d.line((x*Z,a*Z,xx*Z,min(a+1.5,yy)*Z),fill=c,width=max(1,round(w*Z)))
 else:d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
X=lambda x:3+x/max(v['dist'])*160
Y=lambda x:66-x*.5
text(1.33,6.87,'Speed change along the beam, D14−D0',6.3)
line(3,Y(0),163,Y(0),'#999999',.35)
text(133,Y(0)+5,'0 mm/s change',4,'end')
for g,c in [('sedentary','#232323'),('walk','#00b226'),('run','#002bff')]:
 mu,se,n=v['curves'][g];good=np.isfinite(mu)&np.isfinite(se)&(n>=np.ceil(v['counts'][g]/2))
 runs=np.split(np.flatnonzero(good),np.where(np.diff(np.flatnonzero(good))>1)[0]+1)
 for ii in runs:
  if len(ii)<2:continue
  pts=[(X(v['dist'][i]),Y(mu[i]+se[i])) for i in ii]+[(X(v['dist'][i]),Y(mu[i]-se[i])) for i in ii[::-1]]
  s.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" fill-opacity=".16"/>')
  lay=Image.new('RGBA',im.size);ld=ImageDraw.Draw(lay);rgb=tuple(int(c[j:j+2],16) for j in (1,3,5));ld.polygon([(x*Z,y*Z) for x,y in pts],fill=rgb+(41,));im.paste(Image.alpha_composite(im.convert('RGBA'),lay).convert('RGB'))
  pts=[(X(v['dist'][i]),Y(mu[i])) for i in ii]
  s.append('<path d="M'+' L'.join(f'{x},{y}' for x,y in pts)+f'" fill="none" stroke="{c}" stroke-width=".65" stroke-linejoin="round" stroke-linecap="round"/>')
  d.line([(x*Z,y*Z) for x,y in pts],fill=c,width=round(.65*Z),joint='curve')
for x,t in [(3,'Start'),(163,'Finish')]:
 line(x,15,x,74,'#999999',.35,True);text(x,79,t,4,'start' if t=='Start' else 'end')
line(8,16,8,16+50*.5,w=.85);text(11,23,'50 mm/s',4.5)
length=100/max(v['dist'])*160
line(83-length/2,73,83+length/2,73,w=.85);text(83,80,'10 cm',4.5,'middle')
text(175.9,6.72,'Speed change, D14−D0',6)
CY=lambda a:72-(a+55)*59/155
line(184,13,184,72)
for a in [-50,0,50,100]:
 y=CY(a);line(184,y,185.4,y);text(182,y+1.8,str(a),5,'end')
text(173.5,43,'mm/s',5,'middle',True)
line(185.4,CY(0),253,CY(0),'#bbbbbb',.3)
for g,c,cx in [('sedentary','#000000',199),('walk','#008d3f',220),('run','#0864cf',244)]:
 rows=sorted([r for r in v['changes'] if r['group']==g],key=lambda r:r['mouseID']);cages={}
 for i,r in enumerate(rows):
  val=float(r['value'])*v['scale'];x=cx-4.5+9*i/(len(rows)-1);y=CY(val);opacity=1 if g=='sedentary' else .4
  s.append(f'<circle cx="{x}" cy="{y}" r="1.05" fill="{c}" fill-opacity="{opacity}"><title>{r["mouseID"]}: {val:.6f} mm/s</title></circle>')
  rgb=tuple(round(int(c[j:j+2],16)*opacity+255*(1-opacity)) for j in (1,3,5));d.ellipse(((x-1.05)*Z,(y-1.05)*Z,(x+1.05)*Z,(y+1.05)*Z),fill=rgb)
  cages.setdefault((r['cohort'],r['cageID']),[]).append(val)
 for vals in cages.values():
  x=cx-8;y=CY(statistics.mean(vals));pts=[(x-1.25,y),(x,y-1.6),(x+1.25,y),(x,y+1.6)]
  s.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+f'" fill="{c}" stroke="#232323" stroke-width=".15"/>');d.polygon([(a*Z,b*Z) for a,b in pts],fill=c,outline='#232323')
 y=CY(statistics.mean(float(r['value'])*v['scale'] for r in rows));line(cx-5,y,cx+5,y,c,1)
 text(cx,84,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],5,'middle')
# Exact spatial-family and pair-family adjusted annotations, if available.
testfile=out/'spatial-change-tests/binwise_tests.csv'
if testfile.exists():
 hits=[r for r in csv.DictReader(testfile.open()) if r['significant']=='1']
 for r in hits:
  xx=X(float(r['distance_from_entry_boundary_mm']));half=5*700/1201/max(v['dist'])*160
  line(xx-half,11.5,xx+half,11.5,'#232323',1)
 if hits:text(105,12.5,'RUN–SED: adjusted p < 0.05',3.3)
s.append('</svg>');stem=out/'speed_D14_minus_D0_profile_and_scatter_reference_style_tight';stem.with_suffix('.svg').write_text('\n'.join(s));im.save(stem.with_suffix('.png'))
meta=json.loads((out/'speed_D14_minus_D0_profile_and_scatter_clean.json').read_text());meta['presentation']='254.16 x86.21 reference layout; continuous paths, 50 mm/s and10 cm scale bars; start left; scatter range -55 to100 mm/s; ticks -50,0,50,100; profile lower limit retains all SEM bands; significant-bin strip from exact cage permutations with spatial maximum and three-pair correction.';stem.with_suffix('.json').write_text(json.dumps(meta,indent=2))
print(stem)
