"""Last-retained D14 crossing: nine exploratory outcomes, exact source filenames."""
from pathlib import Path
from collections import defaultdict
import csv,json,math,runpy
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS';O=R/'last-crossing-D14';O.mkdir(exist_ok=True)
ct=runpy.run_path(str(R/'tail-metrics/whole-motion-reweighted/cage_tests.py'))
configs=[('speed','Locomoting speed','mm/s'),('duration','Crossing duration','s'),('time_stopped','Time stopped','%'),('posture','Posture height','mm'),('slip_count','Slip count','count'),('slip_score','Total slip score','10³ a.u. × frames'),('mean_slip','Mean slip-event score','a.u. × frames'),('motion_height','Motion height','mm relative to bar'),('tail_score','Tail-motion score','a.u.')]
W,H,Z=1200,1320,2;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=12,anchor='start'):
 from xml.sax.saxutils import escape
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{escape(t)}</text>');d.text((x*Z,y*Z),t,font=ImageFont.truetype(font,size*Z),fill='#232323',anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,c='#232323',w=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" stroke="{c}" stroke-width="{w}" fill="none"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
text(35,30,'D14: last retained crossing',24)
text(35,53,'Mouse dots · cage diamonds · mouse-group means · exact cage permutations within cohort',13)
csv.field_size_limit(10000000)
assets={r['fileName']:r for r in csv.DictReader((R.parents[1]/'assets/Tara-BB-trial-data.csv').open())}
manifest=list(csv.DictReader((R/'analysis-data/trial_manifest.csv').open()));by=defaultdict(list)
for r in manifest:
 if r['Day']=='14':by[r['MouseID']].append(r)
assert len(by)==42
selected=[max(ts,key=lambda r:int(r['TrialNumber'])) for m,ts in sorted(by.items())]
assert all(len(ts)==3 for ts in by.values())
height={r['file']:r for r in csv.DictReader((R/'tail-metrics/height-exploratory/trial-motion-height.csv').open())}
tail={r['file']:r for r in csv.DictReader((R/'tail-metrics/whole-motion-reweighted/trial-values.csv').open())}
with (O/'selected_crossings.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(selected[0]));w.writeheader();w.writerows(selected)
results=[];values=[];qc=[]
for idx,(key,title,unit) in enumerate(configs):
 changes=[]
 for t in selected:
  file=t['File'];r=assets[file];n=float(r['nSlips']);total=float(r['totalSlipMagnitude'])
  if key=='speed':v=float(r['meanSpeedLoco'])*700/1201
  elif key=='duration':v=int(t['Frames'])/float(t['AnalysisFrameRate'])
  elif key=='time_stopped':v=100*int(t['CorrectStoppedFrames'])/int(t['Frames'])
  elif key=='posture':v=float(r['meanPosturalHeight'])*700/1201
  elif key=='slip_count':v=n
  elif key=='slip_score':v=total
  elif key=='mean_slip':v=total/n if n>0 else float('nan')
  elif key=='motion_height':v=float(height[file]['medianHeight'])
  elif key=='tail_score':v=float(tail[file]['sumLegacy'])/int(tail[file]['nLegacy']) if int(tail[file]['nLegacy']) else float('nan')
  q=dict(mouseID=t['MouseID'],cohort=t['Cohort'],cageID=t['CageID'],group=t['Group'],value=v,file=file,trial=int(t['TrialNumber']))
  values.append(dict(metric=key,**q))
  if math.isfinite(v):changes.append(q)
  else:qc.append(dict(metric=key,file=file,reason='nonfinite; retained in value table, omitted from plot/test'))
 src='See README for metric-specific sources';field=key;factor=700/1201 if key in ('speed','posture') else 1
 om,pairs=ct['test'](changes);ps={r['pair']:r for r in pairs};results.append(dict(metric=key,title=title,nMice=len(changes),nCages=len({(r['cohort'],r['cageID']) for r in changes}),overall_p=om,pairs=pairs,source=src,source_field=field,conversion=factor))
 col=idx%3;row=idx//3;L=60+col*400;T=115+row*390;B=T+230;RR=L+270;scale=.001 if key=='slip_score' else 1
 extent=max(abs(r['value']*scale) for r in changes);base=extent/3;power=10**math.floor(math.log10(base));step=next(v for v in [1,2,2.5,5,10] if v*power>=base)*power;hi=math.ceil(extent/step)*step;lo=min(0,step*math.floor(min(r['value']*scale for r in changes)/step));Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
 text(L,T-35,title,19);text(L,T-15,unit,12)
 line(L,T,L,B);line(L,Y(0),RR,Y(0),'#bbbbbb')
 for v in np.arange(lo,hi+step*.01,step):line(L,Y(v),L+4,Y(v));text(L-7,Y(v)+4,f'{v:g}',11,'end')
 for j,(g,c) in enumerate(zip(['sedentary','walk','run'],['#232323','#008d3f','#0864cf'])):
  rs=sorted([r for r in changes if r['group']==g],key=lambda r:r['mouseID']);cx=L+53+j*88;cells=defaultdict(list)
  for i,r in enumerate(rs):
   x=cx-13+26*i/max(1,len(rs)-1);y=Y(r['value']*scale);op=1 if j==0 else .4;rgb=tuple(round(int(c[k:k+2],16)*op+255*(1-op)) for k in [1,3,5]);svg.append(f'<circle cx="{x}" cy="{y}" r="3" fill="{c}" fill-opacity="{op}"/>');d.ellipse(((x-3)*Z,(y-3)*Z,(x+3)*Z,(y+3)*Z),fill=rgb);cells[r['cohort'],r['cageID']].append(r['value']*scale)
  for vv in cells.values():
   x=cx-28;y=Y(np.mean(vv));pts=[(x-3,y),(x,y-4.5),(x+3,y),(x,y+4.5)];svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="{c}" stroke="#232323" stroke-width=".5"/>');d.polygon([(x*Z,y*Z) for x,y in pts],fill=c,outline='#232323')
  mean=np.mean([r['value']*scale for r in rs]);line(cx-16,Y(mean),cx+16,Y(mean),c,3);text(cx,B+24,['SED','WALK','RUN'][j],14,'middle')
 text(L,B+47,f"Primary RUN–WALK: p = {ps['run minus walk']['p_raw']:.3f}",12)
 text(L,B+66,f"RUN–SED: {ps['run minus sedentary']['p_raw']:.3f}; WALK–SED: {ps['walk minus sedentary']['p_raw']:.3f}",11)
 text(L,B+85,f"Omnibus p = {om:.3g} · {len(changes)} mice / 15 cages",11)
text(35,1290,'Exploratory direct two-sided p-values; no pairwise or across-outcome correction. Outcomes and analyses are data-informed.',12)
text(35,1310,'Statistics account for cages/cohorts; dots and horizontal bars describe mice. Last-crossing selection followed inspection of within-session slowing.',12)
svg.append('</svg>');stem=O/'D14_last_crossing_nine_metrics';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
(O/'statistics.json').write_text(json.dumps(results,indent=2));(O/'exclusions.json').write_text(json.dumps(qc,indent=2))
with (O/'last_crossing_values.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(values[0]));w.writeheader();w.writerows(values)
flat=[dict(metric=r['metric'],nMice=r['nMice'],overall_p=r['overall_p'],**p) for r in results for p in r['pairs']]
with (O/'statistics.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(flat[0]));w.writeheader();w.writerows(flat)
(O/'README.md').write_text("""# D14 last-retained-crossing figure

Select highest trialNumber among each mouse's three retained D14 crossings, not necessarily filename TRIAL3. Exact full filenames/frame timing in selected_crossings.csv. All42mice have3retained D14 crossings. This is D14-only, not D14−D0. Selection was motivated by previously inspected slowing results and is exploratory; do not substitute it as a prespecified primary endpoint.

Source assets/Tara-BB-trial-data.csv: meanSpeedLoco, meanPosturalHeight (both ×700/1201), nSlips,totalSlipMagnitude; mean event score=total/count. No-slip mean undefined and retained missing. Validated trial_manifest.csv supplies duration Frames/AnalysisFrameRate and stopped percentage CorrectStoppedFrames/Frames×100. Tail height=trial-motion-height.csv medianHeight, corrected full-profile smoothed motion-height index; tail score=whole-motion-reweighted/trial-values.csv sumLegacy/nLegacy, corrected whole-range frame mean with established Legacy mask. Tail measures not anatomical tail position. Source filenames preserved; original results untouched.

Main style: mouse circles,cage-mean diamonds,mouse group mean bars; full linear ranges,no clipping. Total slip score displayed in thousands only. Statistics: exact whole-cage labels within cohort, equal-cohort pairwise contrasts, direct two-sided p-values RUN–WALK primary, other pairs secondary. Original three-pair Holm values also saved; no across-outcome adjustment. Missing values explicitly listed; nonrandom allocation/exchangeability limitations unchanged.

Reproduce tests/plotLastCrossingD14.py. Combined editable SVG/PNG plus standalone panels and machine-readable values/tests. No source video reads or tracking.
""")
# Standalones retain the panel's vector content, with a translated viewBox.
import xml.etree.ElementTree as ET
ET.register_namespace('', 'http://www.w3.org/2000/svg')
for i,(key,title,unit) in enumerate(configs):
 tree=ET.parse(stem.with_suffix('.svg'));root=tree.getroot();x=400*(i%3);y=75+390*(i//3)
 root.set('viewBox',f'{x} {y} 390 370')
 # Prevent the global background rect from extending beyond the selected viewBox is handled by viewport.
 tree.write(O/(key+'_D14_last_crossing.svg'),encoding='unicode',xml_declaration=True)
 im.crop((x*Z,y*Z,(x+390)*Z,(y+370)*Z)).save(O/(key+'_D14_last_crossing.png'))
print([(r['metric'],r['nMice']) for r in results])
