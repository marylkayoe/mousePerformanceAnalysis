import csv,math
from collections import defaultdict
from pathlib import Path
p=Path(__file__).resolve().parent; root=p.parent/'analysis-data'
def read(q):
 with q.open(newline='') as f:return list(csv.DictReader(f))
manifest=read(root/'trial_manifest.csv');events=read(root/'events.csv');tail=read(p/'pooled-position-bin-summary.csv')
files={r['File'] for r in manifest if r['Day']=='0' and r['ValidSlipPlotCrossing']=='1' and r['Group'] in ('sedentary','walk','run')};by=defaultdict(list)
for e in events:
 if e['File'] in files:by[e['File']].append(e)
counts={'slip':[0]*70,'stop':[0]*70};excluded=defaultdict(int)
for file,es in by.items():
 stops=[r for r in es if r['Type']=='stop' and r['PositionFinite']=='1']
 for e in es:
  typ=e['Type']
  if typ not in counts or e['PositionFinite']!='1' or (typ=='slip' and e['EligibleForPositionPlot']!='1'):continue
  if typ=='slip' and any(int(s['StartTraversalFrame'])<=int(e['EndTraversalFrame']) and int(s['EndTraversalFrame'])>=int(e['StartTraversalFrame']) for s in stops):excluded['stop_overlap']+=1;continue
  pos=(float(e['XEntryRightFraction'])*1279-42)*700/1201
  if not 0<=pos<=700:excluded[typ+'_outside']+=1;continue
  counts[typ][min(int(pos//10),69)]+=1
tailby={int(r['Bin']):r for r in tail if r['Day']=='0'}
with (p/'d0-pooled-tail-slips-stops-10mm.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['Bin','PositionMM','tail_mean','tail_n_mice','slip_count','stop_count']);w.writeheader()
 for i in range(70):
  t=tailby.get(i,{});w.writerow(dict(Bin=i,PositionMM=i*10+5,tail_mean=t.get('mean',''),tail_n_mice=t.get('nMice',0),slip_count=counts['slip'][i],stop_count=counts['stop'][i]))
print('crossings',len(files),'slips',sum(counts['slip']),'stops',sum(counts['stop']),'excluded',dict(excluded))
