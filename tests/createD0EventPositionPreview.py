"""Compact editable D0 position preview; preserves existing pooled event selection."""
import csv, json, math
from pathlib import Path
from collections import defaultdict
from PIL import Image, ImageDraw, ImageFont
R=Path(__file__).resolve().parents[1]; data=R/'BEAMCROSS/DRAFTFIGS/analysis-data'; out=R/'BEAMCROSS/DRAFTFIGS/figMaterials'; out.mkdir(exist_ok=True)
read=lambda p:list(csv.DictReader(p.open()))
files={r['File'] for r in read(data/'trial_manifest.csv') if r['Day']=='0' and r['ValidSlipPlotCrossing']=='1' and r['Group'] in ('sedentary','walk','run')}
by=defaultdict(list)
for e in read(data/'events.csv'):
 if e['File'] in files:by[e['File']].append(e)
counts={k:[0]*28 for k in ('stop','slip')}; old={k:[0]*70 for k in counts}; selected=[]
for file,es in by.items():
 stops=[e for e in es if e['Type']=='stop' and e['PositionFinite']=='1']
 for e in es:
  k=e['Type']
  if k not in counts or e['PositionFinite']!='1' or (k=='slip' and e['EligibleForPositionPlot']!='1'):continue
  if k=='slip' and any(int(s['StartTraversalFrame'])<=int(e['EndTraversalFrame']) and int(s['EndTraversalFrame'])>=int(e['StartTraversalFrame']) for s in stops):continue
  pos=(float(e['XEntryRightFraction'])*1279-42)*700/1201
  if not 0<=pos<=700:continue
  old[k][min(int(pos//10),69)]+=1
  distance=700-pos;counts[k][min(int(distance//25),27)]+=1
  selected.append(dict(File=file,Type=k,EventNumber=e['EventNumber'],DistanceFromEntryMM=distance))
reference=read(R/'BEAMCROSS/DRAFTFIGS/tail-metrics/d0-pooled-tail-slips-stops-10mm.csv')
for k in counts:assert old[k]==[int(r[k+'_count']) for r in reference],k
assert sum(counts['slip'])==592 and sum(counts['stop'])==262
W,H=660,330; scale=2; im=Image.new('RGB',(W*scale,H*scale),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<rect width="660" height="330" fill="white"/>']
fontpath='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=13,anchor='start',color='#222222'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>')
 f=ImageFont.truetype(fontpath,size*scale);w=d.textlength(s,font=f);xx=x*scale-(w/2 if anchor=='middle' else w if anchor=='end' else 0);d.text((xx,(y-size)*scale),s,font=f,fill=color)
def line(x,y,x2,y2,color='#333333',width=1):
 svg.append(f'<path d="M{x},{y} L{x2},{y2}" fill="none" stroke="{color}" stroke-width="{width}"/>');d.line((x*scale,y*scale,x2*scale,y2*scale),fill=color,width=max(1,round(width*scale)))
def rect(x,y,w,h,color):
 svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}"/>');d.rectangle((x*scale,y*scale,(x+w)*scale,(y+h)*scale),fill=color)
text(60,25,'D0 event positions · all groups pooled',19)
for k,top,bottom,col,label in [('stop',65,150,'#AFC7D9','Stops'),('slip',195,280,'#DF7B32','Slips outside stops')]:
 vals=counts[k]; ymax=math.ceil(max(vals)/10)*10
 text(60,top-12,label,16);text(620,top-12,f'{sum(vals)} events',12,'end','#666666')
 for v in (0,ymax//2,ymax):
  y=bottom-v/ymax*(bottom-top);line(60,y,620,y,'#E7E7E7');text(51,y+4,str(v),11,'end')
 for i,v in enumerate(vals):rect(60+i*20,bottom-v/ymax*(bottom-top),20,v/ymax*(bottom-top),col)
 line(60,top,60,bottom);line(60,bottom,620,bottom)
text(16,178,'Count',12)
for v in (0,175,350,525,700):
 x=60+v*.8;line(x,280,x,284);text(x,299,str(v),11,'middle')
text(60,320,'Entry',12);text(340,320,'Distance from entry (mm)',13,'middle');text(620,320,'Exit',12,'end')
svg.append('</svg>');stem=out/'D0_pooled_event_positions_25mm_preview';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['DistanceFromEntryBinStartMM','DistanceFromEntryBinEndMM','Stops','SlipsOutsideStops']);w.writerows((i*25,(i+1)*25,counts['stop'][i],counts['slip'][i]) for i in range(28))
stem.with_suffix('.json').write_text(json.dumps(dict(selection='Exact existing prepare_d0_tail_slips_stops.py rules; 10 mm counts independently matched before rebinning',display='25 mm bins, entry left; counts, not exposure-adjusted risk. Stops above slips. Separate y scales.',calibration='Existing approximate (fraction*1279-42)*700/1201; reversed for distance from entry',crossingDenominator='Unresolved by request; not displayed or used for normalization',slips=592,stops=262,source=str(data),generator='tests/createD0EventPositionPreview.py'),indent=2))
print(stem);print({k:(sum(v),max(v)) for k,v in counts.items()})
