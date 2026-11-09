import itertools,statistics,collections

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
