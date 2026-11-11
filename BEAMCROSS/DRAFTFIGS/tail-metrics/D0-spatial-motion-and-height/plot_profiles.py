"""Mouse-weighted D0 spatial profiles; mean +/- SEM, no group inference."""
from pathlib import Path
from collections import defaultdict
import csv,math,statistics,json
from PIL import Image,ImageDraw,ImageFont
out=Path(__file__).resolve().parent
read=lambda p:list(csv.DictReader(p.open()))
def write(name,rows):
 with (out/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
trials=read(out/'trial-position-bins.csv');by=defaultdict(list)
for r in trials:by[r['MouseID'],r['Bin']].append(r)
mice=[]
for (mouse,b),rs in sorted(by.items()):
 for metric in ('Height','Score'):
  vals=[float(r[metric+'Mean']) for r in rs if int(r[metric+'Frames'])>0 and math.isfinite(float(r[metric+'Mean']))]
  if vals:mice.append(dict(MouseID=mouse,Cohort=rs[0]['Cohort'],CageID=rs[0]['CageID'],Group=rs[0]['Group'],Bin=int(b),DistanceFromEntryMM=int(b)*10+5,Metric=metric,nCrossings=len(vals),value=statistics.mean(vals)))
write('mouse-position-bins.csv',mice);by=defaultdict(list)
for r in mice:by[r['Metric'],r['Group'],r['Bin']].append(r['value'])
group=[]
for (metric,g,b),vs in sorted(by.items()):group.append(dict(Metric=metric,Group=g,Bin=b,DistanceFromEntryMM=b*10+5,nMice=len(vs),mean=statistics.mean(vs),SEM=statistics.stdev(vs)/math.sqrt(len(vs)) if len(vs)>1 else float('nan')))
write('group-position-summary.csv',group)
W,H,Z=620,290,2;L,RR,T,B=60,600,48,225;X=lambda v:L+v/700*(RR-L);font='/System/Library/Fonts/Supplemental/Arial.ttf';report={}
for metric,title,unit in [('Height','Vertical location of tail motion, D0','mm relative to bar'),('Score','Whole-range tail-motion score, D0','a.u.')]:
 data=[r for r in group if r['Metric']==metric];dense=[r for r in data if r['nMice']>=({'sedentary':6,'walk':6,'run':9}[r['Group']])];lo=min(r['mean']-r['SEM'] for r in dense);hi=max(r['mean']+r['SEM'] for r in dense);step=10 if metric=='Height' else .5;lo=math.floor(min(0,lo)/step)*step;hi=math.ceil(hi/step)*step;Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
 im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>']
 def text(x,y,s,size=12,anchor='start',color='#222222'):
  svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>');f=ImageFont.truetype(font,size*Z);w=d.textlength(s,font=f);d.text((x*Z-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*Z),s,font=f,fill=color)
 def line(x,y,xx,yy,c='#333333',width=1):
  svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{width}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(width*Z)))
 text(L,22,title,19);text(L,39,unit+' · mean ± SEM across mice',11)
 for i in range(round((hi-lo)/step)+1):
  v=lo+i*step;y=Y(v);line(L,y,RR,y,'#eeeeee');text(L-8,y+4,f'{v:g}',11,'end')
 for gi,(g,col) in enumerate([('sedentary','#232323'),('walk','#00B226'),('run','#002BFF')]):
  a=sorted([r for r in data if r['Group']==g],key=lambda r:r['Bin']);minimum={'sedentary':6,'walk':6,'run':9}[g];segments=[];seg=[]
  for r in a:
   if r['nMice']<minimum or not math.isfinite(r['SEM']):
    if seg:segments.append(seg);seg=[]
    continue
   if seg and r['Bin']!=seg[-1]['Bin']+1:segments.append(seg);seg=[]
   seg.append(r)
  if seg:segments.append(seg)
  rgb=tuple(int(col[i:i+2],16) for i in (1,3,5))
  for ss in segments:
   pts=[(X(r['DistanceFromEntryMM']),Y(r['mean']+r['SEM'])) for r in ss]+[(X(r['DistanceFromEntryMM']),Y(r['mean']-r['SEM'])) for r in reversed(ss)]
   if len(ss)>1:
    svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{col}" fill-opacity=".16"/>');overlay=Image.new('RGBA',im.size);od=ImageDraw.Draw(overlay);od.polygon([(x*Z,y*Z) for x,y in pts],fill=rgb+(41,));im.paste(Image.alpha_composite(im.convert('RGBA'),overlay).convert('RGB'));d=ImageDraw.Draw(im)
    for u,v in zip(ss,ss[1:]):line(X(u['DistanceFromEntryMM']),Y(u['mean']),X(v['DistanceFromEntryMM']),Y(v['mean']),col,2)
  x=340+gi*87;line(x,34,x+18,34,col,2);text(x+23,38,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],11)
  report[metric+'_'+g]=dict(minMice=min(r['nMice'] for r in a),maxMice=max(r['nMice'] for r in a),binsShown=sum(r['nMice']>=minimum for r in a),totalBins=70)
 line(L,T,L,B);line(L,B,RR,B)
 for v in range(0,701,100):x=X(v);line(x,B,x,B+4);text(x,B+18,str(v),11,'middle')
 text(L,273,'Entry',11);text((L+RR)/2,273,'Distance from entry (mm)',13,'middle');text(RR,273,'Exit',11,'end')
 svg.append('</svg>');stem=out/('D0_tail_'+metric.lower()+'_spatial_mean_sem');stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
(out/'coverage.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
