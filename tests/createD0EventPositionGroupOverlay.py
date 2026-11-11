"""Overlay raw per-group step histograms on the existing pooled preview."""
import runpy, csv, json
from pathlib import Path
ns=runpy.run_path(str(Path(__file__).with_name('createD0EventPositionPreview.py')))
counts={g:{k:[0]*28 for k in ('stop','slip')} for g in ('sedentary','walk','run')}
groups={r['File']:r['Group'] for r in ns['read'](ns['data']/'trial_manifest.csv')}
for e in ns['selected']:
 counts[groups[e['File']]][e['Type']][min(int(e['DistanceFromEntryMM']//25),27)]+=1
for k in ('stop','slip'):
 assert [sum(counts[g][k][i] for g in counts) for i in range(28)]==ns['counts'][k]
# Remove closing tag, then add editable step paths to the same plot coordinates.
ns['svg'].pop()
colors={'sedentary':'#222222','walk':'#00B226','run':'#002BFF'}
for k,top,bottom in [('stop',65,150),('slip',195,280)]:
 ymax=__import__('math').ceil(max(ns['counts'][k])/10)*10
 for g,col in colors.items():
  vals=counts[g][k]
  for i,v in enumerate(vals):
   x=60+i*20;y=bottom-v/ymax*(bottom-top)
   ns['line'](x,y,x+20,y,col,1.6)
   if i<27:ns['line'](x+20,y,x+20,bottom-vals[i+1]/ymax*(bottom-top),col,1.6)
# Inline legend in free space over first panel.
for x,g,label in [(260,'sedentary','SED'),(365,'walk','WALK'),(480,'run','RUN')]:
 ns['line'](x,84,x+22,84,colors[g],2);ns['text'](x+29,88,label,12)
ns['svg'].append('</svg>')
stem=ns['out']/'D0_pooled_event_positions_25mm_group_overlay'
stem.with_suffix('.svg').write_text('\n'.join(ns['svg']))
ns['im'].save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['Group','Type','BinStartDistanceFromEntryMM','BinEndDistanceFromEntryMM','Count'])
 for g in counts:
  for k in counts[g]:
   for i,v in enumerate(counts[g][k]):w.writerow([g,k,i*25,(i+1)*25,v])
stem.with_suffix('.json').write_text(json.dumps({'units':'Raw event counts; no group rescaling or exposure adjustment','validation':'Group bins sum exactly to pooled bars','selection':'Inherited unchanged from createD0EventPositionPreview.py','group_event_totals':{g:{k:sum(v) for k,v in d.items()} for g,d in counts.items()},'caveat':'Group sample sizes differ; outlines show contributions, not comparable per-animal event rates.'},indent=2))
print(stem)
