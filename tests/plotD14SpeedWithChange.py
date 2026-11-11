"""D14 trajectory + scatter matching supplied compact Illustrator layout."""
from pathlib import Path
import json,csv,math,statistics
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/speed-presentation';source=json.loads((out/'speed-profile-source.json').read_text());tr=[r for r in source['traces'] if r['day']=='D14'];rs=[r for r in csv.DictReader((R/'BEAMCROSS/DRAFTFIGS/analysis-data/weighted-speed/speed-days-input.csv').open()) if r['day']=='D14'];scale=700/1201
W,H,Z=350,120,5;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=6,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{s}</text>');f=ImageFont.truetype(font,round(size*Z));w=d.textlength(s,font=f);d.text((x*Z-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*Z),s,font=f,fill='black')
def line(x,y,xx,yy,c='#222222',w=.5):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{w}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
X=lambda x:4+(1255-x)/1220*145;Y=lambda y:72-y*.20
text(1,12,'Forward speed, all animals at D14',7)
# Reference-style dashed marks at the displayed spatial boundaries.
for bx in (X(1255),X(35)):
 svg.append(f'<line x1="{bx}" y1="25" x2="{bx}" y2="72" stroke="#999999" stroke-width=".31" stroke-dasharray="2.54 1.53"/>')
 yy=25.
 while yy<72:
  d.line((bx*Z,yy*Z,bx*Z,min(yy+2.54,72)*Z),fill='#999999',width=2);yy+=4.07

for j,(g,c) in enumerate([('sedentary','#000000'),('walk','#00B226'),('run','#002BFF')]):
 a=np.array([[np.nan if v is None else v*scale for v in r['speedRelative']] for r in tr if r['group']==g]);n=np.sum(np.isfinite(a),axis=0);mu=np.nanmean(a,axis=0);sem=np.nanstd(a,axis=0,ddof=1)/np.sqrt(n);mask=n>=2;indices=np.flatnonzero(mask);assert np.all(np.diff(indices)==1);xs=np.array(source['x'])[mask];mu=mu[mask];sem=sem[mask];pts=[(X(x),Y(v+e)) for x,v,e in zip(xs,mu,sem)]+[(X(x),Y(v-e)) for x,v,e in reversed(list(zip(xs,mu,sem)))]
 svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" fill-opacity=".18"/>');layer=Image.new('RGBA',im.size);ld=ImageDraw.Draw(layer);rgb=tuple(int(c[k:k+2],16) for k in (1,3,5));ld.polygon([(x*Z,y*Z) for x,y in pts],fill=rgb+(46,));im.paste(Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB'));d=ImageDraw.Draw(im)
 for i in range(len(xs)-1):line(X(xs[i]),Y(mu[i]),X(xs[i+1]),Y(mu[i+1]),c,.8)
 text(33,57+j*8,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],6,'end');line(35,55+j*8,44,55+j*8,c,.9)
line(8,23,8,33,'black',1);text(10,30,'50 mm/s',6)
bw=100/(1220*scale)*145;line(70,53,70+bw,53,'black',.8);text(70+bw/2,61,'100 mm',6,'middle');line(138,62,149,62,'black',.8);text(149,68,'50 mm/s',5,'end');text(4,85,'Start',5);text(149,85,'Finish',5,'end')
text(176,7,'Locomoting speed, D14',5.7);SY=lambda v:73-(v-50)/200*59
line(174,14,174,76)
for v in (50,150,250):y=SY(v);line(174,y,175.5,y);text(172,y+2,str(v),6,'end')
text(169,10,'mm/s',5,'end');export=[]
for j,(g,c) in enumerate([('sedentary','#000000'),('walk','#008d3f'),('run','#0864cf')]):
 a=sorted([r for r in rs if r['group']==g],key=lambda r:r['mouseID']);cx=186+j*24;ca={}
 for i,r in enumerate(a):
  v=float(r['value'])*scale;x=cx+10*i/(len(a)-1);y=SY(v);assert 14<=y<=76
  opacity=1 if j==0 else .4;svg.append(f'<circle cx="{x}" cy="{y}" r="1.05" fill="{c}" fill-opacity="{opacity}"/>');rgb=tuple(int(c[k:k+2],16) for k in (1,3,5));fill=tuple(round(vv*opacity+255*(1-opacity)) for vv in rgb);d.ellipse(((x-1.05)*Z,(y-1.05)*Z,(x+1.05)*Z,(y+1.05)*Z),fill=fill);ca.setdefault((r['cohort'],r['cageID']),[]).append(v);export.append({**r,'speedMMPerSecond':v})
 for vs in ca.values():
  x=cx-4;y=SY(statistics.mean(vs));pts=[(x-1.2,y),(x,y-1.6),(x+1.2,y),(x,y+1.6)];svg.append('<polygon points="'+' '.join(f'{xx},{yy}' for xx,yy in pts)+f'" fill="{c}" stroke="#222222" stroke-width=".13"/>');d.polygon([(xx*Z,yy*Z) for xx,yy in pts],fill=c)
 y=SY(statistics.mean(float(r['value'])*scale for r in a));line(cx-1,y,cx+11,y,c,1);text(cx+5,84,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],6,'middle')
# Add saved paired changes, validating against the absolute mouse-day table.
statroot=R/'BEAMCROSS/DRAFTFIGS/analysis-data/weighted-speed'
changes=[r for r in csv.DictReader((statroot/'speed-D14-minus-D0.csv').open()) if r['day']=='D14']
allrows=list(csv.DictReader((statroot/'speed-days-input.csv').open()));lookup={(r['mouseID'],r['day']):float(r['value']) for r in allrows}
for r in changes:assert abs(float(r['value'])-(lookup[r['mouseID'],'D14']-lookup[r['mouseID'],'D00']))<1e-9
cv=[float(r['value'])*scale for r in changes];lim=math.ceil(max(abs(v) for v in cv)/25)*25
CY=lambda v:73-(v+lim)/(2*lim)*59
text(268,7,'Speed change, D14−D0',6.2);text(261,10,'mm/s',5,'end');line(266,14,266,76)
for v in (-lim,0,lim):
 y=CY(v);line(266,y,267.5,y);text(264,y+2,f'{v:g}',6,'end')
svg.append(f'<path d="M266,{CY(0)} H345" stroke="#aaaaaa" stroke-width=".3" stroke-dasharray="1.5 1.5"/>')
for xx in range(266*Z,345*Z,15):d.line((xx,CY(0)*Z,xx+7,CY(0)*Z),fill='#aaaaaa',width=1)
for j,(g,c) in enumerate([('sedentary','#000000'),('walk','#008d3f'),('run','#0864cf')]):
 a=sorted([r for r in changes if r['group']==g],key=lambda r:r['mouseID']);cx=278+j*24;ca={}
 for i,r in enumerate(a):
  v=float(r['value'])*scale;x=cx+10*i/(len(a)-1);y=CY(v);opacity=1 if j==0 else .4
  svg.append(f'<circle cx="{x}" cy="{y}" r="1.05" fill="{c}" fill-opacity="{opacity}"/>');rgb=tuple(int(c[k:k+2],16) for k in (1,3,5));fill=tuple(round(vv*opacity+255*(1-opacity)) for vv in rgb);d.ellipse(((x-1.05)*Z,(y-1.05)*Z,(x+1.05)*Z,(y+1.05)*Z),fill=fill);ca.setdefault((r['cohort'],r['cageID']),[]).append(v)
 for vs in ca.values():
  x=cx-4;y=CY(statistics.mean(vs));pts=[(x-1.2,y),(x,y-1.6),(x+1.2,y),(x,y+1.6)];svg.append('<polygon points="'+' '.join(f'{xx},{yy}' for xx,yy in pts)+f'" fill="{c}" stroke="#222222" stroke-width=".13"/>');d.polygon([(xx*Z,yy*Z) for xx,yy in pts],fill=c)
 y=CY(statistics.mean(float(r['value'])*scale for r in a));line(cx-1,y,cx+11,y,c,1);text(cx+5,84,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],6,'middle')
for left,base in [(176,'days'),(268,'change')]:
 overall=next(r for r in csv.DictReader((statroot/('speed-'+base+'-omnibus.csv')).open()) if r['day']=='D14')
 pairs=[r for r in csv.DictReader((statroot/('speed-'+base+'-pairwise.csv')).open()) if r['day']=='D14']
 text(left,93,f"Overall p = {float(overall['p_unadjusted']):.3f}",4.5)
 text(left,100,'Holm: S–W / S–R / W–R',4.5)
 text(left,107,' / '.join(f"{float(r.get('holm_within_day',r.get('p_holm_3_pairs'))):.3f}" for r in pairs),4.5)
text(2,116,'Dots: mice; diamonds: cage means; bars: mouse means. Cage-level permutations within cohort; Holm across 3 pairs per panel.',4.7)
with (out/'speed_D14_paired_changes_mm_per_second.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(changes[0])+['changeMMPerSecond']);w.writeheader();w.writerows({**r,'changeMMPerSecond':float(r['value'])*scale} for r in changes)
svg.append('</svg>');stem=out/'speed_D14_trajectory_means_and_change_illustrator';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
stem.with_suffix('.json').write_text(json.dumps(dict(profileSource='analysis-data/speed-absolute-position-data.mat',meanSource='analysis-data/weighted-speed/speed-days-input.csv, value field',statistics='Existing cage-level within-cohort permutations; unadjusted omnibus and within-panel Holm across 3 group pairs; changes verified against saved paired mouse means.',day='D14',nMice=len(rs),profile='Saved absolute speedRelative mouse profiles, group mean +/- SEM across mice, no added smoothing. Camera x decreases left to right: right-side entry displayed on the left.',mmPerPixel=scale,horizontalScaleBarMM=100,horizontalScaleBarWidthSVG=bw,caveat='Approximate inherited calibration; scatter uses saved locomoting-speed mouse means unchanged, stops excluded from that summary. Spatial profile is the existing absolute speed profile, without new filtering.'),indent=2))
