"""Paired per-mouse D14-D0 spatial speed change, all groups in one panel."""
from pathlib import Path
import json,csv,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/speed-presentation';s=json.loads((out/'speed-profile-source.json').read_text());lookup={(r['mouseID'],r['day']):r for r in s['traces']};scale=700/1201;xs=np.array(s['x']);dist=(max(xs)-xs)*scale;data=[];curves={};counts={}
for g in ('sedentary','walk','run'):
 changes=[]
 for (mouse,day),r in sorted(lookup.items()):
  if day!='D14' or r['group']!=g:continue
  base=lookup[mouse,'D00'];assert base['group']==g
  a=np.array([np.nan if v is None else v for v in r['speedRelative']]);b=np.array([np.nan if v is None else v for v in base['speedRelative']]);assert len(a)==len(b)==len(xs)
  delta=(a-b)*scale;changes.append(delta)
  for i,v in enumerate(delta):data.append(dict(MouseID=mouse,Group=g,CameraPositionPixels=xs[i],DistanceFromEntryBoundaryMM=dist[i],D0SpeedMMPerS=b[i]*scale,D14SpeedMMPerS=a[i]*scale,ChangeMMPerS=v,PairedFinite=int(np.isfinite(v))))
 arr=np.array(changes);n=np.sum(np.isfinite(arr),axis=0);mu=np.full(len(xs),np.nan);sem=mu.copy()
 for i in range(len(xs)):
  vals=arr[:,i][np.isfinite(arr[:,i])]
  if len(vals)>=2:mu[i]=np.mean(vals);sem[i]=np.std(vals,ddof=1)/np.sqrt(len(vals))
 curves[g]=(mu,sem,n);counts[g]=len(changes)
with (out/'speed_D14_minus_D0_by_position_mouse_values.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
W,H,Z=980,350,2;L,RR,T,B=65,640,50,300;xmax=max(dist);X=lambda v:L+v/xmax*(RR-L)
lo=min(np.nanmin(mu-sem) for mu,sem,n in curves.values());hi=max(np.nanmax(mu+sem) for mu,sem,n in curves.values());lo=-100;hi=100;Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=12,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{s}</text>');f=ImageFont.truetype(font,size*Z);w=d.textlength(s,font=f);d.text((x*Z-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*Z),s,font=f,fill='black')
def line(x,y,xx,yy,c='#222222',width=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{width}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(width*Z)))
text(L,24,'Speed change along the beam, D14−D0',20)
line(L,Y(0),RR,Y(0),'#777777',1)
text(RR-4,Y(0)-7,'0 mm/s change',11,'end')
for j,(g,c) in enumerate([('sedentary','#232323'),('walk','#00B226'),('run','#002BFF')]):
 mu,sem,n=curves[g];good=np.isfinite(mu)&np.isfinite(sem)&(n>=math.ceil(counts[g]/2));segments=[];seg=[]
 for i,ok in enumerate(good):
  if ok:seg.append(i)
  elif seg:segments.append(seg);seg=[]
 if seg:segments.append(seg)
 for ii in segments:
  if len(ii)<2:continue
  pts=[(X(dist[i]),Y(mu[i]+sem[i])) for i in ii]+[(X(dist[i]),Y(mu[i]-sem[i])) for i in reversed(ii)]
  svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" fill-opacity=".16"/>');layer=Image.new('RGBA',im.size);ld=ImageDraw.Draw(layer);rgb=tuple(int(c[k:k+2],16) for k in (1,3,5));ld.polygon([(x*Z,y*Z) for x,y in pts],fill=rgb+(41,));im.paste(Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB'));d=ImageDraw.Draw(im)
  vertices=[(X(dist[i]),Y(mu[i])) for i in ii]
  svg.append('<path d="M'+' L'.join(f'{x},{y}' for x,y in vertices)+f'" fill="none" stroke="{c}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>')
  d.line([(x*Z,y*Z) for x,y in vertices],fill=c,width=2*Z,joint='curve')
# Axes-free trajectory presentation with calibrated scale bars.
for bx,label in [(L,'Start'),(RR,'Finish')]:
 svg.append(f'<path d="M{bx},{T} V{B}" fill="none" stroke="#999999" stroke-width="1" stroke-dasharray="5 4"/>')
 yy=T
 while yy<B:
  d.line((bx*Z,yy*Z,bx*Z,min(yy+5,B)*Z),fill='#999999',width=Z);yy+=9
 text(bx,B+18,label,11,'middle')
# 100 mm = 10 cm; vertical length follows the unchanged mm mapping.
sx=L+28;sy=T+12;vertical=abs(Y(50)-Y(0))
line(sx,sy,sx,sy+vertical,'#222222',3);text(sx+8,sy+vertical/2+4,'50 mm/s',12)
horizontal=100/xmax*(RR-L);hx=(L+RR-horizontal)/2;hy=B-25
line(hx,hy,hx+horizontal,hy,'#222222',3);text(hx+horizontal/2,hy+19,'10 cm',12,'middle')
# Companion paired mouse scatter and previously calculated cage statistics.
import statistics
statroot=R/'BEAMCROSS/DRAFTFIGS/analysis-data/weighted-speed'
changes=[r for r in csv.DictReader((statroot/'speed-D14-minus-D0.csv').open()) if r['day']=='D14']
CY=lambda v:300-(v+100)/200*250
text(704,24,'Speed change, D14−D0',18)
svg.append('<text transform="translate(672 175) rotate(-90)" text-anchor="middle" font-family="Arial" font-size="12">mm/s</text>')
label=Image.new('RGBA',(70,32));ld=ImageDraw.Draw(label);ld.text((35,16),'mm/s',font=ImageFont.truetype(font,24),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(int(672*Z-16),int(175*Z-35)),label)
line(710,50,710,300)
for v in (-100,-50,0,50,100):
 y=CY(v);line(710,y,714,y);text(702,y+4,str(v),11,'end')
line(710,CY(0),960,CY(0),'#bbbbbb')
for j,(g,c) in enumerate([('sedentary','#232323'),('walk','#00B226'),('run','#002BFF')]):
 rr=sorted([r for r in changes if r['group']==g],key=lambda r:r['mouseID']);cx=754+j*85;ca={}
 for i,r in enumerate(rr):
  v=float(r['value'])*scale;x=cx-12+i*24/(len(rr)-1);y=CY(v);assert 50<=y<=300
  svg.append(f'<circle cx="{x}" cy="{y}" r="3" fill="{c}" fill-opacity=".45"/>');rgb=tuple(int(c[k:k+2],16) for k in (1,3,5));fill=tuple(round(a*.45+255*.55) for a in rgb);d.ellipse(((x-3)*Z,(y-3)*Z,(x+3)*Z,(y+3)*Z),fill=fill);ca.setdefault((r['cohort'],r['cageID']),[]).append(v)
 for vs in ca.values():
  x=cx-24;y=CY(statistics.mean(vs));pts=[(x-3,y),(x,y-4.5),(x+3,y),(x,y+4.5)];svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+f'" fill="{c}" stroke="#222222" stroke-width=".4"/>');d.polygon([(a*Z,b*Z) for a,b in pts],fill=c)
 y=CY(statistics.mean(float(r['value'])*scale for r in rr));line(cx-15,y,cx+15,y,c,2);text(cx,324,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],12,'middle')
om=next(r for r in csv.DictReader((statroot/'speed-change-omnibus.csv').open()) if r['day']=='D14');pp=[r for r in csv.DictReader((statroot/'speed-change-pairwise.csv').open()) if r['day']=='D14']
svg.append('</svg>');stem=out/'speed_D14_minus_D0_profile_and_scatter_clean';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
summary=[]
for g,(mu,sem,n) in curves.items():
 for i in range(len(xs)):summary.append(dict(Group=g,CameraPositionPixels=xs[i],DistanceFromEntryBoundaryMM=dist[i],nMice=int(n[i]),mean=mu[i],SEM=sem[i],Displayed=int(n[i]>=math.ceil(counts[g]/2) and np.isfinite(sem[i]))))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(summary[0]));w.writeheader();w.writerows(summary)
stem.with_suffix('.json').write_text(json.dumps(dict(source='analysis-data/speed-absolute-position-data.mat via speed-profile-source.json',method='Saved absolute speed profiles; subtract D0 from D14 within mouse at each identical spatial bin, then mean and SEM across mice. No added smoothing; finite paired bins only.',counts=counts,calibrationMMPerPixel=scale,coordinate='Original camera x descending from1255 to35; distance=(1255-x)*700/1201. Entry-side profile boundary, not independently detected tape mark.',coverage='At least half group contributes to displayed bins; no bridging gaps. SEM is descriptive across mice, not cage-adjusted inference.',presentation='Trajectory axes replaced by 10 cm horizontal and 50 mm/s vertical scale bars, labelled zero-change line and dashed start/finish boundaries; scatter plot area 250 by 250 SVG units; ticks at -100,-50,0,50,100; mm label to left; statistical annotations omitted.',statistics='Statistical annotations hidden, saved results retained: cage-level change test, unadjusted omnibus and Holm within 3 pairs. No new spatial tests. Profile and scatter use saved spatial and whole-trial summaries respectively.'),indent=2));print(counts,lo,hi)
