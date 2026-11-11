"""Spatially weighted speed CDFs: crossing CDF -> mouse mean -> group mean.
Use a fixed complete-position support across all retained D0/D14 crossings.
"""
from pathlib import Path
import json,csv,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/speed-presentation';src=out/'speed-profile-source.json';s=json.loads(src.read_text());records=[r for r in s['traces'] if r['day'] in ('D00','D14')];pos=np.array(s['x']);arrays=[np.array(r['trialSpeedRelative'],float) for r in records];allvalues=np.concatenate(arrays);good=np.all(np.isfinite(allvalues),axis=0)&(pos>=42)&(pos<=1243);assert good.sum()>0
scale=700/1201;grid=np.unique(np.concatenate([a[:,good].ravel()*scale for a in arrays]));mouse={};export=[]
for r,a in zip(records,arrays):
 assert a.shape[0]==len(r['trialNumbers']) and a.shape[1]==len(pos)
 cdfs=[np.searchsorted(np.sort(v[good]*scale),grid,side='right')/sum(good) for v in a]
 mean=np.mean(cdfs,axis=0);mouse[r['mouseID'],r['day']]=(r['group'],mean)
 for trial,v in zip(r['trialNumbers'],a):
  for x,speed in zip(pos[good],v[good]*scale):export.append([r['mouseID'],r['group'],r['day'],trial,x,speed])
groups=['sedentary','walk','run'];cols=['#232323','#00B226','#002BFF'];curves={};summ=[]
for g in groups:
 ids=sorted(m for (m,day),(gg,v) in mouse.items() if day=='D00' and gg==g)
 for period in ('D00','D14','change'):
  a=np.array([mouse[m,period][1] if period!='change' else mouse[m,'D14'][1]-mouse[m,'D00'][1] for m in ids]);mu=a.mean(axis=0);se=a.std(axis=0,ddof=1)/np.sqrt(len(ids));curves[g,period]=(mu,se)
  for x,v,e in zip(grid,mu,se):summ.append([g,period,x,v,e,len(ids)])
W,H,Z=1100,365,2;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=12,anchor='start'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{t}</text>');d.text((x*Z,y*Z),t,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,c='#333333',w=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{c}" stroke-width="{w}" fill="none"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=round(w*Z))
maxspeed=math.ceil(max(grid)/50)*50
for j,period in enumerate(('D00','D14','change')):
 L=55+365*j;RR=L+290;T=65;B=285;X=lambda x:L+x/maxspeed*(RR-L)
 limit=math.ceil(max(np.max(abs(m)+e) for (g,p),(m,e) in curves.items() if p=='change')*10)/10
 low,high=(-limit,limit) if period=='change' else (0,1);Y=lambda y:B-(y-low)/(high-low)*(B-T)
 text((L+RR)/2,26,{'D00':'D0','D14':'D14','change':'D14 − D0 CDF change'}[period],18,'middle');text((L+RR)/2,47,'Cumulative fraction' if period!='change' else 'Change in cumulative fraction',11,'middle')
 for t in np.linspace(low,high,5):
  line(L,Y(t),RR,Y(t),'#999999' if period=='change' and abs(t)<1e-9 else '#eeeeee');text(L-6,Y(t)+4,f'{t:.2g}',10,'end')
 for t in range(0,maxspeed+1,100):
  line(X(t),B,X(t),B+4);text(X(t),B+19,str(t),10,'middle')
 for g,c in zip(groups,cols):
  mu,se=curves[g,period];xx=np.repeat(grid,2);mm=np.empty(len(xx));ss=mm.copy();mm[::2]=np.r_[0,mu[:-1]];mm[1::2]=mu;ss[::2]=np.r_[0,se[:-1]];ss[1::2]=se
  xx=np.r_[0,xx,maxspeed];mm=np.r_[0,mm,0 if period=='change' else 1];ss=np.r_[0,ss,0]
  if period=='change':
   pts=[(X(a),Y(b+e)) for a,b,e in zip(xx,mm,ss)]+[(X(a),Y(b-e)) for a,b,e in zip(xx[::-1],mm[::-1],ss[::-1])];svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+f'" fill="{c}" fill-opacity=".13"/>');lay=Image.new('RGBA',im.size);ld=ImageDraw.Draw(lay);rgb=tuple(int(c[k:k+2],16) for k in (1,3,5));ld.polygon([(a*Z,b*Z) for a,b in pts],fill=rgb+(33,));im.paste(Image.alpha_composite(im.convert('RGBA'),lay).convert('RGB'))
  pts=[(X(a),Y(b)) for a,b in zip(xx,mm)];svg.append('<path d="M'+' L'.join(f'{a:.4f},{b:.4f}' for a,b in pts)+f'" fill="none" stroke="{c}" stroke-width="1.6"/>');d.line([(a*Z,b*Z) for a,b in pts],fill=c,width=3)
 line(L,T,L,B);line(L,B,RR,B);text((L+RR)/2,326,'Forward speed (mm/s)',13,'middle')
 if j==0:
  for i,(label,c) in enumerate(zip(('SED','WALK','RUN'),cols)):
   y=215+19*i;line(RR-70,y,RR-48,y,c,2);text(RR-40,y+4,label,11)
text(W/2,356,'Equal positions, crossings within mouse, and mice within group · change shading: paired-mouse SEM',12,'middle');svg.append('</svg>');stem=out/'speed_spatial_CDF_D0_D14_and_change';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
for suffix,head,rows in [('group_summary',['Group','Period','SpeedMMPerS','MeanCDF','SEM','nMice'],summ),('source_values',['MouseID','Group','Day','Trial','CameraBinCenterPX','SpeedMMPerS'],export)]:
 with (out/(stem.name+'_'+suffix+'.csv')).open('w',newline='') as f:w=csv.writer(f);w.writerow(head);w.writerows(rows)
stem.with_suffix('.json').write_text(json.dumps(dict(source=str(src),method='Saved per-crossing spatial-bin mean speed including stops; empirical CDF over equal-spaced common bins, then mean crossing CDF per mouse, then mean across mice. Paired mouse D14-D0 CDF difference. These are distributions of spatial-bin mean speeds, not instantaneous frame speeds.',support=dict(bins=int(sum(good)),cameraBinCenters=pos[good].tolist(),excludedWithinTapeCenters=pos[(pos>=42)&(pos<=1243)&~good].tolist(),rule='Complete finite support across all 251 D0/D14 crossings; no interpolation. Approximate tape limits42..1243; 700/1201 mm per pixel. Excludes about first35mm near entry.'),nMice=42,nTrialsD0=125,nTrialsD14=126,statistics='Descriptive only. Paired-mouse SEM for change; not cage-adjusted inference or simultaneous confidence.',interpretation='CDF shift right means faster. Negative D14-D0 CDF means fewer positions at or below that speed at D14.'),indent=2));print(stem)
