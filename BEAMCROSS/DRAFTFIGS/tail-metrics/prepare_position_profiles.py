"""Build mouse-level tail profiles directly from Mac mini's archived traces."""
import csv, io, math, statistics, zipfile
from collections import defaultdict, Counter
from pathlib import Path
root=Path(__file__).resolve().parent
archive=root.parent/'analysis-data'/'tail-and-behavior-frame-traces.zip'
manifest=root.parent/'analysis-data'/'trial_manifest.csv'
with manifest.open(newline='') as f:
 trials=[r for r in csv.DictReader(f) if r['Day'] in ('0','14') and r['ValidSlipPlotCrossing']=='1']
with zipfile.ZipFile(archive) as z:
 allbins=[];qc=[]
 for t in trials:
  name=t['File']; entry='balance_beam_events_traces_L40_20261106/trials/'+name+'.trace.csv'; bins=defaultdict(list);counts=Counter()
  with z.open(entry) as raw, io.TextIOWrapper(raw,encoding='utf-8',newline='') as text:
   for r in csv.DictReader(text):
    counts['frames']+=1
    try: x=float(r['XEntryRightFraction']); value=float(r['TailAboveBar'])
    except ValueError: counts['invalid']+=1;continue
    if not math.isfinite(x) or not math.isfinite(value) or r['TailBadFrame']=='1':counts['invalid']+=1;continue
    mm=(x*1279-42)*700/1201
    if not 0<=mm<=700:counts['outside_tapes']+=1;continue
    b=min(int(mm//10),69);bins[b].append(value);counts['included']+=1
  for b,v in bins.items():allbins.append(dict(File=name,MouseID=t['MouseID'],Cohort=t['Cohort'],CageID=t['CageID'],Group=t['Group'],Day=t['Day'],Bin=b,PositionMM=10*b+5,Frames=len(v),TailAboveMean=statistics.mean(v)))
  qc.append(dict(File=name,MouseID=t['MouseID'],Group=t['Group'],Day=t['Day'],**{k:counts[k] for k in ['frames','invalid','outside_tapes','included']},bins_with_data=len(bins)))
 def write(name,items):
  with (root/name).open('w',newline='') as f:
   w=csv.DictWriter(f,fieldnames=items[0].keys());w.writeheader();w.writerows(items)
 write('trial-position-bin-means.csv',allbins);write('trial-frame-counts.csv',qc)
 lookup=defaultdict(list)
 for r in allbins:lookup[(r['MouseID'],r['Cohort'],r['CageID'],r['Group'],r['Day'],r['Bin'])].append(r)
 mice=[]
 for (mouse,cohort,cage,group,day,b),rs in sorted(lookup.items()):
  mice.append(dict(MouseID=mouse,Cohort=cohort,CageID=cage,Group=group,Day=day,Bin=b,PositionMM=10*b+5,nCrossings=len(rs),mean=statistics.mean(r['TailAboveMean'] for r in rs)))
 write('mouse-position-bin-means.csv',mice)
 combos=defaultdict(list)
 for r in mice:combos[(r['Day'],r['Group'],r['Bin'])].append(r['mean'])
 group=[]
 for (day,g,b),v in sorted(combos.items(),key=lambda z:(int(z[0][0]),z[0][1],z[0][2])):
  sd=statistics.stdev(v) if len(v)>=2 else float('nan')
  group.append(dict(Day=day,Group=g,Bin=b,PositionMM=10*b+5,nMice=len(v),mean=statistics.mean(v),sd=sd,sem=sd/math.sqrt(len(v))))
 write('group-position-bin-summary.csv',group)
 for day in ('0','14'):
  for groupname in ('sedentary','walk','run'):
   ts=[r for r in qc if r['Day']==day and r['Group']==groupname];print('D'+day,groupname,'trials',len(ts),'mice',len(set(t['MouseID'] for t in ts)),'valid frames',sum(t['included'] for t in ts),'invalid',sum(t['invalid'] for t in ts),'outside',sum(t['outside_tapes'] for t in ts))
