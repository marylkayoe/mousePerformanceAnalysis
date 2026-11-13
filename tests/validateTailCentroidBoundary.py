from pathlib import Path
import json,csv,hashlib,statistics
import numpy as np
from scipy.io import loadmat
B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS');O=B/'balance_beam_tail_centroid_boundary_20261113';old=B/'balance_beam_whole_tail_no_vertical_weight_20261113';read=lambda p:list(csv.DictReader(p.open()));changed=[];validation=[]
for stem in ['D0_first','D14_last']:
 for factor in [2,3]:
  rows=read(O/f'factor{factor}'/(stem+'_summary.csv'));assert len(rows)==42
  ee=read(O/f'factor{factor}'/(stem+'_events.csv'));prev=read(B/'balance_beam_tail_current_criteria_scatters_20261112'/(stem+'_events.csv'));key=lambda e:(e['File'],int(e['PeakOriginalFrame']));prior={key(e):e for e in prev};assert len(ee)==len(prev)
  for e in ee:
   p=prior[key(e)]
   for f in ['StartOriginalFrame','EndOriginalFrame','NormalizedPeak','EventScore']:assert np.isclose(float(e[f]),float(p[f]),rtol=1e-10,atol=1e-9)
   if str(e['PassHeight'])!=str(p['PassHeight']):changed.append(dict(File=e['File'],Factor=factor,Selection=stem,OriginalFrame=e['PeakOriginalFrame'],OldHeight=p['HeightAtPeakMM'],NewHeight=e['HeightAtPeakMM'],OldPass=p['PassHeight'],NewPass=e['PassHeight'],Score=e['EventScore']))
  addedInvalid=0
  for r in rows:
   z=loadmat(O/f'factor{factor}'/'traces'/(r['File']+'.mat'),simplify_cells=True);p=loadmat(old/'traces'/(r['File']+'.mat'),simplify_cells=True)
   for f in ['x','smoothed','normalized','originalFrames']:assert np.array_equal(z[f],p[f],equal_nan=True)
   addedInvalid+=int(np.sum(np.asarray(z['invalid'],bool)&~np.asarray(p['invalid'],bool)))
   assert np.array_equal(z['originalInvalid'],p['invalid'])
  validation.append(dict(selection=stem,factor=factor,trials=42,belowTraceAndCandidatesExact=True,newInvalidFrames=addedInvalid,changedAcceptedEvents=sum(e['Factor']==factor and e['Selection']==stem for e in changed),maxRowError=max(float(r['MaxRowProfileError']) for r in rows)))
with (O/'changed_height_gate_events.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=changed[0]);w.writeheader();w.writerows(changed)
(O/'validation.json').write_text(json.dumps(validation,indent=2));print(json.dumps(validation,indent=2))
stats=json.loads((O/'statistics.json').read_text());lines=['# Centroid-boundary comparison results','', '84 crossings; 42 mice / 15 cages per day. No failed trials. Original results preserved.','', '## Exploratory group omnibus p-values','', '| Selection | Metric | Current | 2× | 3× |','|---|---|---:|---:|---:|']
for stem in ['D0_first','D14_last']:
 for metric in ['LocomotingMean','MeanHeight','CountHeightFiltered','TotalScoreHeightFiltered']:
  rs=[next(x for x in stats if x['selection']==stem and x['metric']==metric and x['variant']==v) for v in ['current','2','3']];lines.append('| '+' | '.join([stem,metric]+[f"{x['omnibus_p']:.5f}" for x in rs])+' |')
lines+=['','Group inference uses the existing exact cage permutations within cohort. Raw and Holm-three pairwise estimates/p-values are in statistics.json; no across-outcome/variant correction. Both modified D14 swing-score RUN comparisons have Holm p=0.07143; omnibus significance does not imply those pairwise comparisons pass0.05.','', '## Gate consequence','', 'Below-bar raw/normalized traces and candidate scores/frames are identical. The full-profile height gate stays7.5mm for this comparison. Accepted counts: D0 current88,2×84,3×86; D14 current71,2×58,3×62. This deliberately exposes the consequence of changing the height estimate; it does not validate keeping7.5mm as the final cutoff. User subsequently requested reconsidering this gate. Do not adopt changed swing counts as finalized. See changed_height_gate_events.csv.','', '## Visual interpretation','', 'At walker original1471 (~4s), both masks recover the upright tail; 2× runs close to the back,3× gives more margin. Boundary is shown cyan in movies. Restoring background may also add noise. This is not an anatomical segmentation validation. No mask selected based on p-values.','', '## Deliverables','', 'D0_first_comparison.svg and D14_last_comparison.svg: rows whole motion, motion height, swing count, swing score; columns current,2×,3×. six_example_traces.svg: height and locomotion-only whole motion, same retained movie examples. factor2/presentations and factor3/presentations: individual,pair andsix-panel movies. walker_4s_mask_comparison.png: diagnostic mask illustration. All SVG text/lines editable.']
(O/'REPORT.md').write_text('\n'.join(lines)+'\n');(O/'METHODS.md').write_text(Path('tests/TAIL_CENTROID_BOUNDARY_COMPARISON.md').read_text())
