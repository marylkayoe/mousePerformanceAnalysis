"""Exploratory cage-level comparisons of within-trial motion-height metrics."""
import csv,sys,math,statistics,collections
from pathlib import Path
p=Path(__file__).resolve().parent
sys.path.insert(0,str(p.parent/'below-bar-reweighted'))
from cage_tests import test

def read(f):
 with f.open(newline='') as h:return list(csv.DictReader(h))
def write(name,rows):
 with (p/name).open('w',newline='') as h:
  w=csv.DictWriter(h,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
manifest={r['File']:r for r in read(p.parent.parent/'analysis-data'/'trial_manifest.csv')}
trials=read(p/'trial-motion-height.csv'); assert len(trials)==377 and len({r['file'] for r in trials})==377
metrics=('meanHeight','medianHeight','sdHeight','iqrHeight','meanWeightedMeanHeight')
for r in trials:
 m=manifest[r['file']];r.update(mouseID=m['MouseID'],cohort=m['Cohort'],cageID=m['CageID'],group=m['Group'],day='D'+str(int(m['Day'])).zfill(2),trialNumber=int(m['TrialNumber']))
 for a in metrics+('nFrames','nValid','validFraction'):r[a]=float(r[a])
by=collections.defaultdict(list)
for t in trials:by[(t['mouseID'],t['day'])].append(t)
mouse=[]
for (mid,day),v in sorted(by.items()):
 v.sort(key=lambda x:x['trialNumber']);a=v[0]
 rec={k:a[k] for k in ('mouseID','cohort','cageID','group','day')}
 rec.update(nTrials=len(v),nFrames=int(sum(r['nFrames'] for r in v)),nValid=int(sum(r['nValid'] for r in v)),sourceFiles=' | '.join(r['file'] for r in v))
 for met in metrics:
  z=[r[met] for r in v if math.isfinite(r[met])];rec[met]=statistics.mean(z) if z else math.nan;rec[met+'NTrials']=len(z)
 mouse.append(rec)
assert len(mouse)==126
write('mouse-day-motion-height.csv',mouse)
lookup={(r['mouseID'],r['day']):r for r in mouse};des=[];comparisons=[]
for met in metrics:
 for period in ('D00','D07','D14','D07-D00','D14-D00'):
  if '-' in period:
   later,base=period.split('-'); ds=[{**r,'value':r[met]-lookup[(r['mouseID'],base)][met]} for r in mouse if r['day']==later and (r['mouseID'],base) in lookup and math.isfinite(r[met]) and math.isfinite(lookup[(r['mouseID'],base)][met])]
  else:ds=[{**r,'value':r[met]} for r in mouse if r['day']==period and math.isfinite(r[met])]
  overall,pairs=test(ds)
  for row in pairs:comparisons.append(dict(metric=met,period=period,nMice=len(ds),overallP=overall,**row))
  for g in ('sedentary','walk','run'):
   d=[r for r in ds if r['group']==g];vals=[r['value'] for r in d];nc=len({(r['cohort'],r['cageID']) for r in d});sd=statistics.stdev(vals)
   des.append(dict(metric=met,period=period,group=g,nCages=nc,nMice=len(vals),mean=statistics.mean(vals),median=statistics.median(vals),sd=sd,sem=sd/math.sqrt(len(vals))))
write('descriptive.csv',des);write('group-comparisons.csv',comparisons)
for met in metrics:
 print('\n',met,flush=True)
 for period in ('D00','D07','D14','D14-D00'):
  dd=[r for r in des if r['metric']==met and r['period']==period];rr=[r for r in comparisons if r['metric']==met and r['period']==period]
  print(period,[(r['group'],round(r['mean'],2)) for r in dd], 'overall',round(rr[0]['overallP'],4),'pairs',[(r['pair'],round(r['p_holm_3_pairs'],4)) for r in rr],flush=True)
print('valid-fraction range',min(t['validFraction'] for t in trials),max(t['validFraction'] for t in trials),flush=True)
