"""Paired mouse CDF differences; descriptive mean +/- SEM, no inference."""
from pathlib import Path
import runpy,csv,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];v=runpy.run_path(str(R/'tests/plotSlipScoreCDFD0D14.py'));rows=v['rows'];out=v['out']
# All event thresholds yield exact right-continuous empirical steps, not bins.
x=np.unique([float(r['Magnitude']) for r in rows]);curves={};paired=[];summ=[]
for g in v['groups']:
 mice=sorted({r['MouseID'] for r in rows if r['Group']==g});deltas=[]
 for m in mice:
  z=[]
  for day in ('D00','D14'):
   vals=np.sort([float(r['Magnitude']) for r in rows if r['MouseID']==m and r['Day']==day]);assert len(vals)>0
   z.append(np.searchsorted(vals,x,side='right')/len(vals))
  delta=z[1]-z[0];deltas.append(delta)
  for a,b in zip(x,delta):paired.append([g,m,a,b])
 a=np.array(deltas);mu=a.mean(axis=0);se=a.std(axis=0,ddof=1)/np.sqrt(len(mice));curves[g]=(mu,se)
 assert abs(mu[-1])<1e-12
 for xx,yy,ss in zip(x,mu,se):summ.append([g,xx,yy,ss,len(mice)])
# Confirm equal mouse weighting gives difference of earlier group CDFs.
for g,(mu,se) in curves.items():
 old=[]
 for day in ('D00','D14'):
  xx,yy=v['curves'][g,day];idx=np.searchsorted(xx,x,side='right')-1;old.append(np.where(idx>=0,yy[np.maximum(idx,0)],0))
 assert np.allclose(mu,old[1]-old[0],atol=1e-14)
W,H,Z=540,470,2;L,RR,T,B=70,515,65,395
lo=min(float(np.min(m-s)) for m,s in curves.values());hi=max(float(np.max(m+s)) for m,s in curves.values());limit=math.ceil(max(abs(lo),abs(hi))*20)/20
X=lambda a:L+(math.log10(a)+1)/5*(RR-L);Y=lambda a:B-(a+limit)/(2*limit)*(B-T)
im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);s=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=12,anchor='start'):
 s.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{t}</text>');d.text((x*Z,y*Z),t,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,c='#333333',w=1):
 s.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{c}" stroke-width="{w}" fill="none"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=round(w*Z))
text(L,25,'Change in slip-event score distribution',20);text(L,46,'D14 − D0 cumulative fraction · paired mice, mean ± SEM',12)
for a in np.linspace(-limit,limit,5):
 line(L,Y(a),RR,Y(a),'#bbbbbb' if abs(a)<1e-10 else '#eeeeee');text(L-9,Y(a)+4,f'{a:.2f}',11,'end')
for a in range(-1,5):
 xx=X(10**a);line(xx,B,xx,B+4);text(xx,B+20,str(a),12,'middle')
for g,c in zip(v['groups'],v['colors']):
 mu,se=curves[g];xx=[X(.1)];mm=[0];ss=[0];prev=0;prevse=0
 for a,b,e in zip(x,mu,se):xx.extend([X(a),X(a)]);mm.extend([prev,b]);ss.extend([prevse,e]);prev=b;prevse=e
 xx.append(X(10000));mm.append(0);ss.append(0)
 pts=list(zip(xx,[Y(a+b) for a,b in zip(mm,ss)]))+list(zip(xx[::-1],[Y(a-b) for a,b in zip(mm,ss)][::-1]))
 s.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+f'" fill="{c}" fill-opacity=".13"/>');layer=Image.new('RGBA',im.size);ld=ImageDraw.Draw(layer);rgb=tuple(int(c[i:i+2],16) for i in (1,3,5));ld.polygon([(a*Z,b*Z) for a,b in pts],fill=rgb+(33,));im.paste(Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB'))
 pts=list(zip(xx,[Y(a) for a in mm]));s.append('<path d="M'+' L'.join(f'{a},{b}' for a,b in pts)+f'" fill="none" stroke="{c}" stroke-width="1.6"/>');d.line([(a*Z,b*Z) for a,b in pts],fill=c,width=3)
line(L,T,L,B);line(L,B,RR,B)
for j,(label,c) in enumerate(zip(('SED','WALK','RUN'),v['colors'])):
 y=325+20*j;line(400,y,425,y,c,2);text(434,y+4,label,12)
text(L+8,T+18,'Positive = more small-score events at D14',11)
text((L+RR)/2,438,'log10(slip-event score)',14,'middle');text((L+RR)/2,461,'Descriptive distribution shift; not a change in event count',11,'middle')
s.append('</svg>');stem=out/'slip_score_CDF_change_D14_minus_D0';stem.with_suffix('.svg').write_text('\n'.join(s));im.save(stem.with_suffix('.png'))
for name,header,data in [('group_summary',['Group','Score','MeanCDFChange','SEM','nMice'],summ),('paired_mouse_values',['Group','MouseID','Score','CDFChange'],paired)]:
 with (out/(stem.name+'_'+name+'.csv')).open('w',newline='') as f:
  w=csv.writer(f);w.writerow(header);w.writerows(data)
stem.with_suffix('.json').write_text(json.dumps(dict(method='Exact right-continuous empirical CDF per mouse/day; subtract D0 from D14 within each mouse, then equal mouse group mean and SEM. SEM is descriptive, not cage-adjusted or simultaneous confidence. No hypothesis tests.',selection='Same 42 mice and all retained slips as D0/D14 CDFs; including during stops and outside tape, no clipping or smoothing.',validation='Paired-mean changes equal D14 minus D0 earlier group ECDFs to atol1e-14; terminal values zero.',interpretation='Positive indicates increased fraction of events <= that score, not fewer events per crossing.',groups=v['summary']),indent=2));print(stem)
