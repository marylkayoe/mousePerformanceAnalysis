"""Figures/statistics for fixed exploratory centroid-height mask variants."""
from pathlib import Path
import csv,json,runpy,collections,statistics,math
import numpy as np
from scipy.io import loadmat
from bbSimpleSVG import Figure
ROOT=Path(__file__).resolve().parents[1];B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS');O=B/'balance_beam_tail_centroid_boundary_20261113';OLD=B/'balance_beam_whole_tail_no_vertical_weight_20261113';MOV=B/'balance_beam_tail_minwidth15_smooth5_20261112'
read=lambda p:list(csv.DictReader(p.open()))
index={r['File']:r for r in read(ROOT/'BEAMCROSS/DRAFTFIGS/tail-metrics/CDF-D14-and-change/trial-index.csv')}
test=runpy.run_path(str(ROOT/'BEAMCROSS/DRAFTFIGS/tail-metrics/whole-motion-reweighted/cage_tests.py'))['test']
colors={'sedentary':'#232323','walk':'#00b526','run':'#002bff'};metrics=[('LocomotingMean','Tail motion','0.001 a.u./pixel'),('MeanHeight','Motion height','mm above bar'),('CountHeightFiltered','Tail swing count','count'),('TotalScoreHeightFiltered','Tail swing score','a.u. × frames')]
allstats=[];values=[]
for stem in ['D0_first','D14_last']:
 assert json.loads((O/(stem+'_failures.json')).read_text())==[]
 tables={str(f):read(O/f'factor{f}'/(stem+'_summary.csv')) for f in [2,3]};oldrows=read(OLD/'per_crop_pixel/locomotion_scatters'/(stem+'_summary.csv'));oldscore={r['File']:r for r in read(B/'balance_beam_tail_current_criteria_scatters_20261112'/(stem+'_summary.csv'))}
 baseline=[]
 for r in oldrows:
  z=loadmat(OLD/'traces'/(r['File']+'.mat'),simplify_cells=True);v=~np.asarray(z['invalid'],bool)
  baseline.append(dict(File=r['File'],LocomotingMean=float(r['LocomotingMean']),MeanHeight=float(np.mean(z['motionHeight'][v])),CountHeightFiltered=float(oldscore[r['File']]['CountHeightFiltered']),TotalScoreHeightFiltered=float(oldscore[r['File']]['TotalScoreHeightFiltered'])))
 tables['current']=baseline
 fig=Figure(4,3);axs=np.array(fig.axes)
 for i,(metric,label,unit) in enumerate(metrics):
  ymax=max(float(r[metric]) for tab in tables.values() for r in tab)*1.15
  if metric=='CountHeightFiltered':ymax=3*math.ceil(ymax/3)
  else:
   step=ymax/3;power=10**math.floor(math.log10(step));ymax=3*next(v*power for v in [1,2,2.5,5,10] if v*power>=step)
  for j,variant in enumerate(['current','2','3']):
   rows=[]
   for r in tables[variant]:
    m=index[r['File']];rows.append(dict(file=r['File'],mouseID=m['MouseID'],cohort=m['Cohort'],cageID=m['CageID'],group=m['Group'],value=float(r[metric])))
   assert len(rows)==42 and len({r['cageID'] for r in rows})==15
   om,pairs=test(rows);allstats.append(dict(selection=stem,variant=variant,metric=metric,omnibus_p=om,pairs=pairs,nMice=42,nCages=15));values.extend(dict(r,selection=stem,variant=variant,metric=metric) for r in rows)
   ax=axs[i,j]
   ax.setup((-.6,2.4),(min(0,min(r['value'] for r in rows)*1.15),ymax),f'{label}: '+('current' if variant=='current' else variant+'× centroid'),unit,[0,1,2],['SED','WALK','RUN'])
   for g,group in enumerate(colors):
    rr=[r for r in rows if r['group']==group];ys=[r['value'] for r in rr];jit=np.random.default_rng(17).uniform(-.14,.14,len(rr));[ax.dot(g+x,y,colors[group],opacity=.42) for x,y in zip(jit,ys)]
    cells=collections.defaultdict(list)
    for r in rr:cells[r['cageID']].append(r['value'])
    [ax.dot(g-.29,np.mean(v),colors[group],diamond=True) for v in cells.values()]
    ax.line([g-.17,g+.17],[np.mean(ys)]*2,colors[group],2.5)
   ax.p(om)
 fig.text(30,26,stem.replace('_',' ')+' retained crossings · exploratory cage/cohort permutation omnibus',20)
 fig.save(O/(stem+'_comparison.svg'))
 print(stem,'complete',flush=True)
(O/'statistics.json').write_text(json.dumps(allstats,indent=2))
with (O/'mouse_values.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=values[0]);w.writeheader();w.writerows(values)
# Six paired source examples, same time mapping as movies.
manifest=json.loads((MOV/'presentations_height_trail_right_20261113/manifest.json').read_text())
fig=Figure(6,2,1400,300);axs=np.array(fig.axes);traceRows=[]
from tailMovieDisplay import prepare
for i,m in enumerate(manifest):
 name=m['file'];meta=index[name];start=m['firstOriginalFrame'];variants={v:loadmat((OLD if v=='current' else O/f'factor{v}')/'traces'/(name+'.mat'),simplify_cells=True) for v in ['current','2','3']}
 source=read(MOV/'presentations_height_trail_right_20261113'/(meta['Group']+('_D0' if meta['Day']=='0' else '_D14')+'_display_values.csv'))
 # Existing source speed/stop masks provide identical locomotion eligibility.
 raw=read(B/'balance_beam_events_traces_L40_20261106/trials'/(name+'.trace.csv'))
 size0=next(r for r in read(OLD/'per_crop_pixel'/('D0_first_whole_summary.csv' if meta['Day']=='0' else 'D14_last_whole_summary.csv')) if r['File']==name)
 motionMax=0
 for z in variants.values():
  vv=~np.asarray(z['invalid'],bool);kk=vv&np.array([float(r['StopMask'])==0 and np.isfinite(float(r['ForwardSpeed'])) and float(r['ForwardSpeed'])>=40 for r in raw]);sm,_=prepare(1000*z['wholeUnweighted']/float(size0['CropPixels']),kk,17,0);motionMax=max(motionMax,float(np.nanmax(sm)))
 heightMin=min(-30,min(float(np.nanmin(z['motionHeight'])) for z in variants.values())-5)
 for j in range(2):axs[i,j].setup((0,(variants['current']['originalFrames'][-1]-start)/30),(heightMin,120) if j==0 else (0,motionMax*1.05),meta['MouseID']+' | '+meta['Group']+' | D'+meta['Day'],'Motion height (mm)' if j==0 else 'Whole motion (0.001 a.u./pixel)',xlabel='Movie time (s; 30 fps)')
 for variant,col in [('current','#555555'),('2','#a222ad'),('3','#0085b5')]:
  z=variants[variant];fr=np.asarray(z['originalFrames'],dtype=float);t=(fr-start)/30;valid=~np.asarray(z['invalid'],bool);h=z['motionHeight'];w=int(read(OLD/'per_crop_pixel'/('D0_first_whole_summary.csv' if meta['Day']=='0' else 'D14_last_whole_summary.csv'))[0]['CropHeight'])
  size=next(r for r in read(OLD/'per_crop_pixel'/('D0_first_whole_summary.csv' if meta['Day']=='0' else 'D14_last_whole_summary.csv')) if r['File']==name);motion=1000*z['wholeUnweighted']/float(size['CropPixels'])
  keep=valid&np.array([float(r['StopMask'])==0 and np.isfinite(float(r['ForwardSpeed'])) and float(r['ForwardSpeed'])>=40 for r in raw]);smooth,_=prepare(motion,keep,17,0)
  show=t>=0;axs[i,0].line(t[show],np.where(valid,h,np.nan)[show],col,1.3);axs[i,1].line(t[show],smooth[show],col,1.3)
  traceRows.extend(dict(File=name,Variant=variant,OriginalFrame=int(fr[k]),MovieTimeSeconds=float(t[k]),MotionHeightMM=float(h[k]),WholeMotionTimes1000=float(motion[k]),Invalid=int(not valid[k]),KeepLocomotion=int(keep[k])) for k in range(len(fr)))
 axs[i,0].line([0,max(t)],[0,0],'#aaa',1,True)
fig.text(30,27,'Six examples: gray current | purple 2× centroid | blue 3× centroid; whole motion smoothed17 frames, stops excluded',18)
fig.save(O/'six_example_traces.svg')
with (O/'six_example_traces.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=traceRows[0]);w.writeheader();w.writerows(traceRows)
