"""Rank representative mice and select daily trials, by motion height only."""
import csv,math,statistics,collections
from pathlib import Path
p=Path(__file__).resolve().parent
with (p/'mouse-day-motion-height.csv').open(newline='') as f: rows=list(csv.DictReader(f))
with (p/'trial-motion-height.csv').open(newline='') as f: trials={r['file']:r for r in csv.DictReader(f)}
days=('D00','D07','D14');groups=('sedentary','walk','run');selected=[];ranked=[]
for g in groups:
 group=[r for r in rows if r['group']==g];target={d:statistics.mean(float(r['meanHeight']) for r in group if r['day']==d) for d in days}
 bymouse=collections.defaultdict(dict)
 for r in group:bymouse[r['mouseID']][r['day']]=r
 candidates=[]
 for mid,day in bymouse.items():
  if any(d not in day or int(day[d]['nTrials'])!=3 for d in days):continue
  delta=[float(day[d]['meanHeight'])-target[d] for d in days];score=math.sqrt(sum(x*x for x in delta)/3)
  candidates.append((score,mid,day))
 candidates.sort(key=lambda v:(v[0],v[1]))
 for i,(score,mid,day) in enumerate(candidates):
  ranked.append(dict(group=g,rank=i+1,mouseID=mid,cageID=day['D00']['cageID'],distanceRmsMM=score,**{d+'MouseMM':day[d]['meanHeight'] for d in days},**{d+'GroupMeanMM':target[d] for d in days}))
 score,mid,day=candidates[0]
 for d in days:
  x=day[d];available=[trials[f] for f in x['sourceFiles'].split(' | ')]
  # Same scientific rule for all trials; no review of video or effect selected.
  chosen=min(available,key=lambda r:(abs(float(r['meanHeight'])-float(x['meanHeight'])),r['file']))
  selected.append(dict(group=g,mouseID=mid,cageID=x['cageID'],day=d,sourceFile=chosen['file'],mouseDayMeanMM=x['meanHeight'],trialMeanMM=chosen['meanHeight'],trialValidFraction=chosen['validFraction'],groupDayMeanMM=target[d],mouseTrajectoryRmsDistanceMM=score))
for name,data in [('debug-example-mice-ranking.csv',ranked),('debug-example-trials.csv',selected)]:
 with (p/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=data[0]);w.writeheader();w.writerows(data)
for r in selected:print(r['group'],r['mouseID'],r['day'],r['sourceFile'],'mouse',round(float(r['mouseDayMeanMM']),1),'trial',round(float(r['trialMeanMM']),1),'valid',round(float(r['trialValidFraction'])*100,1))
