"""Paired mouse spatial tail changes using existing D0 rules and exported D14."""
from pathlib import Path
from collections import defaultdict
import csv,math,statistics,json
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/tail-metrics';out=root/'D14-minus-D0-spatial-motion-and-height'
read=lambda p:list(csv.DictReader(p.open()))
def write(name,rows):
 with (out/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
base={(r['MouseID'],r['Metric'],int(r['Bin'])):r for r in read(root/'D0-spatial-motion-and-height/mouse-position-bins.csv')}
by=defaultdict(list)
for r in read(out/'trial-position-bins.csv'):by[r['MouseID'],int(r['Bin'])].append(r)
mice=[]
for (mouse,b),rs in sorted(by.items()):
 for metric in ('Height','Score'):
  vals=[float(r[metric+'Mean']) for r in rs if int(r[metric+'Frames'])>0 and math.isfinite(float(r[metric+'Mean']))]
  old=base.get((mouse,metric,b))
  if vals and old and math.isfinite(float(old['value'])):
   assert old['Group']==rs[0]['Group']
   v=statistics.mean(vals);mice.append(dict(MouseID=mouse,Group=rs[0]['Group'],Cohort=rs[0]['Cohort'],CageID=rs[0]['CageID'],Metric=metric,Bin=b,DistanceFromEntryMM=b*10+5,D0=float(old['value']),D14=v,value=v-float(old['value']),D0Crossings=int(old['nCrossings']),D14Crossings=len(vals)))
write('paired-mouse-position-changes.csv',mice);by=defaultdict(list)
for r in mice:by[r['Metric'],r['Group'],r['Bin']].append(r['value'])
group=[]
for (metric,g,b),vs in sorted(by.items()):group.append(dict(Metric=metric,Group=g,Bin=b,DistanceFromEntryMM=b*10+5,nMice=len(vs),mean=statistics.mean(vs),SEM=statistics.stdev(vs)/math.sqrt(len(vs)) if len(vs)>1 else float('nan')))
write('group-position-change-summary.csv',group)
W,H,Z=620,290,2;L,RR,T,B=45,600,45,225;X=lambda v:L+v/700*(RR-L);font='/System/Library/Fonts/Supplemental/Arial.ttf';report={}
for metric,title,step,unit in [('Height','Tail motion-height change, D14−D0',10,'mm'),('Score','Tail motion-score change, D14−D0',.5,'a.u.')]:
 data=[r for r in group if r['Metric']==metric];minimum={'sedentary':6,'walk':6,'run':9};dense=[r for r in data if r['nMice']>=minimum[r['Group']]]
 lo=math.floor(min(0,min(r['mean']-r['SEM'] for r in dense))/step)*step;hi=math.ceil(max(0,max(r['mean']+r['SEM'] for r in dense))/step)*step;Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
 im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">'];
 def text(x,y,s,size=12,anchor='start'):
  svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{s}</text>');d.text((x*Z,y*Z),s,font=ImageFont.truetype(font,size*Z),fill='black',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
 def line(x,y,xx,yy,c='#333333',width=1):
  svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{width}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(width*Z)))
 text(L,25,title,19);line(L,Y(0),RR,Y(0),'#999999');text(RR-4,Y(0)-6,'0 '+unit+' change',10,'end')
 for g,col in [('sedentary','#232323'),('walk','#00B226'),('run','#002BFF')]:
  a=sorted([r for r in data if r['Group']==g],key=lambda r:r['Bin']);segments=[];seg=[]
  for r in a:
   if r['nMice']<minimum[g] or not math.isfinite(r['SEM']):
    if seg:segments.append(seg);seg=[]
    continue
   if seg and r['Bin']!=seg[-1]['Bin']+1:segments.append(seg);seg=[]
   seg.append(r)
  if seg:segments.append(seg)
  for ss in segments:
   if len(ss)<2:continue
   pts=[(X(r['DistanceFromEntryMM']),Y(r['mean']+r['SEM'])) for r in ss]+[(X(r['DistanceFromEntryMM']),Y(r['mean']-r['SEM'])) for r in ss[::-1]]
   svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{col}" fill-opacity=".16"/>');layer=Image.new('RGBA',im.size);ld=ImageDraw.Draw(layer);rgb=tuple(int(col[j:j+2],16) for j in (1,3,5));ld.polygon([(x*Z,y*Z) for x,y in pts],fill=rgb+(41,));im.paste(Image.alpha_composite(im.convert('RGBA'),layer).convert('RGB'))
   pts=[(X(r['DistanceFromEntryMM']),Y(r['mean'])) for r in ss];svg.append('<path d="M'+' L'.join(f'{x},{y}' for x,y in pts)+f'" fill="none" stroke="{col}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>');d.line([(x*Z,y*Z) for x,y in pts],fill=col,width=4,joint='curve')
  report[metric+'_'+g]=dict(binsShown=sum(len(s) for s in segments),pairedMiceRange=[min(r['nMice'] for r in a),max(r['nMice'] for r in a)])
 for x,t in [(L,'Start'),(RR,'Finish')]:
  svg.append(f'<path d="M{x},{T}V{B}" stroke="#999999" stroke-dasharray="5 4" fill="none"/>')
  for y in range(T,B,9):d.line((x*Z,y*Z,x*Z,min(y+5,B)*Z),fill='#999999',width=2)
  text(x,247,t,11,'middle')
 line(L+15,T+10,L+15,T+10+step/(hi-lo)*(B-T),width=3);text(L+23,T+23,f'{step:g} {unit}',12)
 line(280,263,280+100/700*(RR-L),263,width=3);text(280+50/700*(RR-L),281,'10 cm',12,'middle')
 svg.append('</svg>');stem=out/f'tail_{metric.lower()}_change_along_beam';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
(out/'coverage.json').write_text(json.dumps(report,indent=2))
(out/'README.md').write_text('''# Tail changes along the beam, D14 minus D0

Reproduce with tests/exportD14TailSpatialProfiles.m then tests/plotTailSpatialChanges.py. Reuses existing D0-spatial-motion-and-height summaries. Reads canonical saved profiles and corrected whole-tail traces in place; no video processing or new tracking. MATLAB verifies frame counts, original-frame mapping, time and bad-frame alignment.

10 mm bins between tape positions; start left. Average valid frames within crossing, then equal crossing means within mouse/day. Subtract D0 from D14 within the same mouse and spatial bin, then group mean and SEM across paired mice. Each displayed bin requires at least half the group (SED6, WALK6, RUN9); missing bins remain gaps. No additional spatial smoothing or binwise tests. Different bins can have different contributing mice/crossings; coverage and paired values are saved.

Height is the probability-weighted full-profile median location of motion, relative to bar top, with five-frame smoothing restricted to contiguous valid runs. Score is NewWholeNormalized, the corrected whole-range tail score, masked for invalid pairs and existing tail bad frames. These spatial profiles use mean height within bins, whereas the scalar height scatter uses mean crossing median heights. The score profile gives crossings equal weight within bins, whereas the scalar score pools finite frames. Do not interpret these spatial curves as an exact decomposition of scalar scatter means.

Horizontal scale is 10 cm (100 mm), not 10 mm. Vertical scales: 10 mm height change and 0.5 a.u. score change. Zero is no change, not physical bar height. Original D0 results preserved.
''')
print(report)
# Editable stacked presentation: height above, score below.
import xml.etree.ElementTree as ET
ns='http://www.w3.org/2000/svg';ET.register_namespace('',ns)
combined=ET.Element('{'+ns+'}svg',{'viewBox':'0 0 620 590'})
preview=Image.new('RGB',(1240,1180),'white')
for i,metric in enumerate(('height','score')):
 stem=out/f'tail_{metric}_change_along_beam';g=ET.SubElement(combined,'{'+ns+'}g',{'transform':f'translate(0 {i*300})'})
 for el in ET.parse(stem.with_suffix('.svg')).getroot():g.append(el)
 preview.paste(Image.open(stem.with_suffix('.png')),(0,i*600))
ET.ElementTree(combined).write(out/'tail_height_and_score_change_along_beam.svg',encoding='utf-8',xml_declaration=True)
preview.save(out/'tail_height_and_score_change_along_beam.png')
