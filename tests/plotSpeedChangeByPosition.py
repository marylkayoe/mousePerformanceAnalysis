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
  for i,v in enumerate(delta):data.append(dict(MouseID=mouse,Group=g,CameraPositionPixels=xs[i],DistanceFromEntryBoundaryMM=dist[i],D0SpeedMMPerSecond=b[i]*scale,D14SpeedMMPerSecond=a[i]*scale,ChangeMMPerSecond=v,PairedFinite=int(np.isfinite(v))))
 arr=np.array(changes);n=np.sum(np.isfinite(arr),axis=0);mu=np.full(len(xs),np.nan);sem=mu.copy()
 for i in range(len(xs)):
  vals=arr[:,i][np.isfinite(arr[:,i])]
  if len(vals)>=2:mu[i]=np.mean(vals);sem[i]=np.std(vals,ddof=1)/np.sqrt(len(vals))
 curves[g]=(mu,sem,n);counts[g]=len(changes)
with (out/'speed_D14_minus_D0_by_position_mouse_values.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
W,H,Z=660,310,2;L,RR,T,B=65,640,65,245;xmax=max(dist);X=lambda v:L+v/xmax*(RR-L)
lo=min(np.nanmin(mu-sem) for mu,sem,n in curves.values());hi=max(np.nanmax(mu+sem) for mu,sem,n in curves.values());lo=math.floor(min(0,lo)/20)*20;hi=math.ceil(hi/20)*20;Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=12,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{s}</text>');f=ImageFont.truetype(font,size*Z);w=d.textlength(s,font=f);d.text((x*Z-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*Z),s,font=f,fill='black')
def line(x,y,xx,yy,c='#222222',width=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{width}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(width*Z)))
text(L,24,'Forward-speed change along the beam, D14−D0',20);text(L,45,'Paired change (mm/s) · mean ± SEM across mice',12)
for v in range(int(lo),int(hi)+1,20):y=Y(v);line(L,y,RR,y,'#e8e8e8');text(L-9,y+4,str(v),11,'end')
line(L,Y(0),RR,Y(0),'#777777',1)
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
 x=100+j*160;line(x,281,x+22,281,c,2);text(x+28,285,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g]+f' (n={counts[g]})',12)
line(L,T,L,B);line(L,B,RR,B)
for v in range(0,701,100):x=X(v);line(x,B,x,B+4);text(x,B+18,str(v),11,'middle')
text((L+RR)/2,306,'Distance from entry-side profile boundary (mm)',12,'middle')
svg.append('</svg>');stem=out/'speed_D14_minus_D0_by_position_mean_sem';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
summary=[]
for g,(mu,sem,n) in curves.items():
 for i in range(len(xs)):summary.append(dict(Group=g,CameraPositionPixels=xs[i],DistanceFromEntryBoundaryMM=dist[i],nMice=int(n[i]),mean=mu[i],SEM=sem[i],Displayed=int(n[i]>=math.ceil(counts[g]/2) and np.isfinite(sem[i]))))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(summary[0]));w.writeheader();w.writerows(summary)
stem.with_suffix('.json').write_text(json.dumps(dict(source='analysis-data/speed-absolute-position-data.mat via speed-profile-source.json',method='Saved speedRelative absolute profiles; subtract D0 from D14 within mouse at each identical spatial bin, then mean and SEM across mice. No added smoothing; finite paired bins only.',counts=counts,calibrationMMPerPixel=scale,coordinate='Original camera x descending from1255 to35; distance=(1255-x)*700/1201. Entry-side profile boundary, not independently detected tape mark.',coverage='At least half group contributes to displayed bins; no bridging gaps. SEM is descriptive across mice, not cage-adjusted inference.',statistics='No new tests; plot does not establish a group difference in change.'),indent=2));print(counts,lo,hi)
