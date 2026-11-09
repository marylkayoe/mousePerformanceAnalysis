import csv, statistics, math
from collections import defaultdict
from pathlib import Path
p=Path(__file__).resolve().parent
with (p/'mouse-position-bin-means.csv').open(newline='') as f: rows=list(csv.DictReader(f))
bins=defaultdict(list)
for r in rows:bins[(int(r['Day']),int(r['Bin']))].append(float(r['mean']))
with (p/'pooled-position-bin-summary.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['Day','Bin','PositionMM','nMice','mean','sd','sem']);w.writeheader()
 for (day,b),v in sorted(bins.items()):
  sd=statistics.stdev(v) if len(v)>1 else float('nan')
  w.writerow(dict(Day=day,Bin=b,PositionMM=10*b+5,nMice=len(v),mean=statistics.mean(v),sd=sd,sem=sd/math.sqrt(len(v))))
