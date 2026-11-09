import csv,itertools,statistics,collections
from pathlib import Path
out=Path(__file__).resolve().parent; root=out.parent.parent/'analysis-data'
read=lambda p:list(csv.DictReader(open(p,newline='')))
events=read(root/'events.csv'); manifest={r['File']:r for r in read(root/'trial_manifest.csv')}
pool=[r for r in read(root/'pooled-exposures.csv') if r['day'] in ('D00','D14') and r['nRuns']=='3']
byfile=collections.defaultdict(list)
for e in events: byfile[e['File']].append(e)
rows=[]; exclusions=[]
for r in pool:
 files=r['sourceFiles'].split(' | '); reasons=[]
 for f in files:
  m=manifest[f]; es=byfile[f]
  assert len([e for e in es if e['Type']=='slip'])==int(m['NSlips'])
  assert len([e for e in es if e['Type']=='stop'])==int(m['NStops'])
  if m['DirectionConsistent']!='1':reasons.append('entry direction inconsistent: '+f)
  if any(e['PositionFinite']!='1' for e in es):reasons.append('event position missing: '+f)
 if reasons:
  exclusions.append({'mouseID':r['mouseID'],'day':r['day'],'reason':' | '.join(reasons)});continue
 es=[e for f in files for e in byfile[f]]
 slips=[e for e in es if e['Type']=='slip'];stops=[e for e in es if e['Type']=='stop']
 assert len(slips)==int(float(r['combinedSlips'])) and len(stops)==int(float(r['combinedStops']))
 def inside(e):return 42 <= float(e['XEntryRightFraction'])*1279 <= 1243
 no_overlap=[e for e in slips if not any(s['File']==e['File'] and int(s['StartTraversalFrame'])<=int(e['EndTraversalFrame']) and int(s['EndTraversalFrame'])>=int(e['StartTraversalFrame']) for s in stops)]
 row={k:r[k] for k in ('mouseID','cohort','cageID','group','day','sourceFiles')}
 for name,ev in [('total_slips',slips),('nonoverlap_slips',no_overlap),('stops',stops)]:
  row[name+'_all']=len(ev);row[name+'_between']=sum(inside(e) for e in ev)
 rows.append(row)
def write(name,items):
 if items:
  with open(out/name,'w',newline='') as f:w=csv.DictWriter(f,fieldnames=items[0]);w.writeheader();w.writerows(items)
write('matched-mouse-days.csv',rows);write('excluded-mouse-days.csv',exclusions)
def holm(ps):
 out=[0.]*len(ps);run=0
 for rank,i in enumerate(sorted(range(len(ps)),key=ps.__getitem__)):
  run=max(run,(len(ps)-rank)*ps[i]);out[i]=min(1.,run)
 return out
def test(data):
 cells=collections.defaultdict(list)
 for r in data:cells[(r['cohort'],r['cageID'],r['group'])].append(float(r['value']))
 strata=[];scores=[];obsr=obsw=0.;g00=g01=g11=0.
 for co in ('TMCS2','TMCS3'):
  a=[(g,statistics.mean(v)) for (c,ca,g),v in sorted(cells.items()) if c==co]
  labs=[x[0] for x in a];y=[x[1] for x in a];n=len(y);mean=statistics.mean(y);yc=[v-mean for v in y]
  nr=labs.count('run');nw=labs.count('walk'); obsr+=sum(v for v,g in zip(yc,labs) if g=='run');obsw+=sum(v for v,g in zip(yc,labs) if g=='walk')
  g00+=nr-nr*nr/n;g01-=nr*nw/n;g11+=nw-nw*nw/n
  vals=[]
  for rr in itertools.combinations(range(n),nr):
   rem=[i for i in range(n) if i not in rr]
   for ww in itertools.combinations(rem,nw):vals.append((sum(yc[i] for i in rr),sum(yc[i] for i in ww)))
  scores.append(vals);strata.append((labs,y))
 det=g00*g11-g01*g01
 def stat(u,v):return (g11*u*u-2*g01*u*v+g00*v*v)/det
 obs=stat(obsr,obsw); total=ge=0
 for a in scores[0]:
  for b in scores[1]:
   total+=1;ge+=stat(a[0]+b[0],a[1]+b[1])>=obs-1e-10
 pairs=[]
 for A,B in [('walk','sedentary'),('run','sedentary'),('run','walk')]:
  per=[]
  for labs,y in strata:
   z=[(g,v) for g,v in zip(labs,y) if g in (A,B)];n=len(z);na=sum(g==A for g,v in z);vals=[]
   for idx in itertools.combinations(range(n),na):
    ix=set(idx);vals.append(statistics.mean(z[i][1] for i in ix)-statistics.mean(z[i][1] for i in range(n) if i not in ix))
   ob=statistics.mean(v for g,v in z if g==A)-statistics.mean(v for g,v in z if g==B);per.append((ob,vals))
  diff=(per[0][0]+per[1][0])/2;null=[(a+b)/2 for a in per[0][1] for b in per[1][1]]
  pairs.append({'pair':A+' minus '+B,'difference_cage_cohort_balanced':diff,'p_raw':sum(abs(x)>=abs(diff)-1e-12 for x in null)/len(null)})
 for r,p in zip(pairs,holm([r['p_raw'] for r in pairs])):r['p_holm_3_pairs']=p
 return ge/total,pairs
results=[];descriptive=[]
for measure in ('total_slips','nonoverlap_slips','stops'):
 for condition in ('all','between'):
  for period in ('D00','D14','D14-D00'):
   if period=='D14-D00':
    lookup={(r['mouseID'],r['day']):r for r in rows}; ds=[]
    for r in rows:
     if r['day']=='D14' and (r['mouseID'],'D00') in lookup:
      b=lookup[(r['mouseID'],'D00')];ds.append({**r,'value':r[measure+'_'+condition]-b[measure+'_'+condition]})
   else:ds=[{**r,'value':r[measure+'_'+condition]} for r in rows if r['day']==period]
   p,prs=test(ds)
   for g in ('sedentary','walk','run'):
    a=[r for r in ds if r['group']==g]
    descriptive.append(dict(measure=measure,condition=condition,period=period,group=g,n_mice=len(a),mean=statistics.mean(r['value'] for r in a)))
   for pr in prs:results.append(dict(measure=measure,condition=condition,period=period,n_mice=len(ds),p_overall=p,**pr))
write('comparisons.csv',results);write('group-means.csv',descriptive)
print('Excluded:',exclusions)
for measure in ('total_slips','nonoverlap_slips','stops'):
 print('\n',measure)
 for period in ('D00','D14','D14-D00'):
  for cond in ('all','between'):
   sub=[x for x in results if x['measure']==measure and x['period']==period and x['condition']==cond]
   means=[x['mean'] for x in descriptive if x['measure']==measure and x['period']==period and x['condition']==cond]
   print(period,cond,'n',sub[0]['n_mice'],'means',*[round(x,2) for x in means],'overall',round(sub[0]['p_overall'],4),'pairs',[(x['pair'],round(x['p_raw'],4),round(x['p_holm_3_pairs'],4)) for x in sub])
