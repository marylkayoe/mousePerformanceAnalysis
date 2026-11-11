"""Cage-aware exploratory analysis of reweighted whole-range motion."""
import csv,math,statistics,collections,itertools
from pathlib import Path
from cage_tests import test,holm
out=Path(__file__).resolve().parent; draft=out.parent.parent
src=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110')
def read(p):
 with p.open(newline='') as f:return list(csv.DictReader(f))
def write(name,rs):
 with (out/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=rs[0].keys());w.writeheader();w.writerows(rs)
manifest={r['File']:r for r in read(draft/'analysis-data'/'trial_manifest.csv')}; summary=read(src/'comparison_by_file.csv'); trials=[]
assert len(summary)==377
for s in summary:
 assert s['Status']=='complete' and s['OldTotalMatch']=='1' and s['OldAboveMatch']=='1' and s['OldBelowMatch']=='1'
 m=manifest[s['File']]; frames=read(src/'trials'/(s['File']+'.csv'))
 assert len(frames)==int(s['Frames']); values=[];strict=[];raw=[];bad=invalid=0
 for r in frames:
  if r['TailBadFrame']=='1':bad+=1;continue
  x=float(r['NewWholeNormalized']);assert math.isfinite(x);values.append(x)
  if r['InvalidFramePair']=='1':invalid+=1;continue
  before=float(r['NewNormalizedBeforeLegacyNaNReplacement']);v=float(r['NewWholeRaw'])
  if math.isfinite(before):strict.append(before)
  if math.isfinite(v):raw.append(v)
 assert values and strict and raw
 trials.append(dict(file=s['File'],mouseID=m['MouseID'],cohort=m['Cohort'],cageID=m['CageID'],group=m['Group'],day='D'+str(int(m['Day'])).zfill(2),trialNumber=int(m['TrialNumber']),nFrames=len(frames),badFrames=bad,invalidPairsAmongUnmasked=invalid,nLegacy=len(values),sumLegacy=sum(values),nStrict=len(strict),sumStrict=sum(strict),nRaw=len(raw),sumRaw=sum(raw)))
write('trial-values.csv',trials)
by=collections.defaultdict(list)
for t in trials:by[(t['mouseID'],t['day'])].append(t)
mouse=[]
for (id,day),rs in sorted(by.items()):
 rs.sort(key=lambda r:r['trialNumber']); a=rs[0]
 rec={k:a[k] for k in ('mouseID','cohort','cageID','group','day')}; rec.update(nTrials=len(rs),sourceFiles=' | '.join(r['file'] for r in rs))
 for label in ('Legacy','Strict','Raw'):
  n=sum(r['n'+label] for r in rs);rec['n'+label]=n;rec['mean'+label]=sum(r['sum'+label] for r in rs)/n
 mouse.append(rec)
assert len(mouse)==126
write('mouse-day-values.csv',mouse)
lookup={(r['mouseID'],r['day']):r for r in mouse};results=[];desc=[];within=[]
for metric in ('Legacy','Strict','Raw'):
 for period in ('D00','D07','D14','D07-D00','D14-D00'):
  if '-' in period:
   later,base=period.split('-');ds=[]
   for r in mouse:
    if r['day']==later and (r['mouseID'],base) in lookup:
     ds.append({**r,'value':r['mean'+metric]-lookup[(r['mouseID'],base)]['mean'+metric]})
  else:ds=[{**r,'value':r['mean'+metric]} for r in mouse if r['day']==period]
  p,pairs=test(ds)
  for x in pairs:results.append(dict(metric=metric,period=period,nMice=len(ds),overallP=p,**x))
  for g in ('sedentary','walk','run'):
   gg=[r for r in ds if r['group']==g];v=[r['value'] for r in gg]; cages=collections.defaultdict(list)
   for r in gg:cages[(r['cohort'],r['cageID'])].append(r['value'])
   desc.append(dict(metric=metric,period=period,group=g,nMice=len(v),nCages=len(cages),mean=statistics.mean(v),median=statistics.median(v),sd=statistics.stdev(v),sem=statistics.stdev(v)/math.sqrt(len(v))))
  if '-' in period:
   def signflip(vals):
    observed=abs(statistics.mean(vals)); n=len(vals); return sum(abs(sum(s*x for s,x in zip(signs,vals))/n)>=observed-1e-12 for signs in itertools.product((-1,1),repeat=n))/(2**n)
   rawp=[];tmp=[]
   for g in ('sedentary','walk','run'):
    gg=[r for r in ds if r['group']==g];cages=collections.defaultdict(list)
    for r in gg:cages[(r['cohort'],r['cageID'])].append(r['value'])
    vals=[statistics.mean(v) for v in cages.values()];p0=signflip(vals);rawp.append(p0);tmp.append(dict(metric=metric,period=period,group=g,nCages=len(vals),meanCageChange=statistics.mean(vals),pSignflip=p0))
   for x,padj in zip(tmp,holm(rawp)):x['pHolmAcrossGroups']=padj
   within.extend(tmp)
write('group-comparisons.csv',results);write('descriptive.csv',desc);write('within-group-time-exploratory.csv',within)
for metric in ('Legacy','Strict','Raw'):
 print('\n',metric)
 for period in ('D00','D07','D14','D07-D00','D14-D00'):
  rr=[r for r in results if r['metric']==metric and r['period']==period];dd=[r for r in desc if r['metric']==metric and r['period']==period]
  print(period,'means',[(r['group'],round(r['mean'],4)) for r in dd],'overall',round(rr[0]['overallP'],4),'pairs',[(r['pair'],round(r['p_raw'],4),round(r['p_holm_3_pairs'],4)) for r in rr])
print('invalid pair frames retained in legacy',sum(t['invalidPairsAmongUnmasked'] for t in trials))
