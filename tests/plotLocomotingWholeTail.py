from pathlib import Path
import csv,math,shutil,json,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1];O=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_no_vertical_weight_20261113/per_crop_pixel/locomotion_scatters')
source=(R/'tests/plotTailCandidateResults.py').read_text()
for metric in ['LocomotingMean','SpeedScaledMean']:
 out=O/metric;out.mkdir(exist_ok=True)
 upper=1.5*math.ceil(max(float(r[metric]) for stem in ['D0_first','D14_last'] for r in csv.DictReader((O/(stem+'_summary.csv')).open()))/1.5)
 s=source.replace("O=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_MAD3p5_height7p5_results_20261112')",f'O=Path({str(out)!r})').replace('I=O',f'I=Path({str(O)!r})').replace("stem+'_peak_counts.csv'","stem+'_summary.csv'").replace("q['PeakCount']",f"q[{metric!r}]").replace(",validSeconds=float(q['JointValidSeconds']),rawThreshold=float(q['RawProminenceThreshold'])",",retainedFrames=int(q['RetainedFrames']),tailValidFrames=int(q['TailValidFrames']),retainedFraction=float(q['RetainedFraction'])")
 s=s.replace('Tail slips,','Whole-tail motion,').replace('_tail_slips','_whole_tail_motion').replace("om,pairs=test(rows);","assert len(rows)==42;om,pairs=test(rows);")
 s=s.replace("upper=max(3,3*math.ceil(max(r['value'] for r in rows)/3))",f'upper={upper}').replace("txt(texts[0],","txt(texts[1],'10⁻³ a.u./pixel');txt(texts[0],")
 s=s.replace("f'p = {om:.3f}'","('p < 0.001' if om<.001 else f'p = {om:.3f}')").replace("txt(e,f'{v:g}')","txt(e,f'{v:g}');e.set('text-anchor','end');e.set('transform','translate(5 '+e.get('transform').split()[-1])")
 exec(compile(s,str(R/'tests/plotTailCandidateResults.py'),'exec'),{'__file__':str(R/'tests/plotTailCandidateResults.py'),'__name__':'__main__'})
ns='http://www.w3.org/2000/svg';E.register_namespace('',ns);combined=E.Element('{'+ns+'}svg',viewBox='-8 0 174 223',width='870',height='1115')
for i,(metric,label) in enumerate([('LocomotingMean','Stops excluded; no speed division'),('SpeedScaledMean','Stops excluded; motion × 100 / speed (mm/s)')]):
 E.SubElement(combined,'{'+ns+'}text',x='7',y=str(6+i*111),attrib={'font-family':'Arial','font-size':'4.6'}).text=label
 for j,stem in enumerate(['D0_first','D14_last']):
  root=E.parse(O/metric/(stem+'_whole_tail_motion.svg')).getroot();root.set('x',str(j*83));root.set('y',str(10+i*111));root.set('width','73.01');root.set('height','94.19');root.set('overflow','visible');combined.append(root)
E.ElementTree(combined).write(O/'whole_tail_locomotion_comparison.svg',encoding='utf-8',xml_declaration=True)
notes='D0 first retained and D14 last retained crossing,42 mice/15 cages each. Same eligibility as six-trial traces: current tail validity AND no saved stop flag AND finite speed>=40px/s. Means calculated from unsmoothed samples; no MAD/vertical weighting. Crop-area normalization retained. Speed-scaled mean=mean(motion_per_pixel*100/speed_mm_s) across eligible frames, NOT ratio of trial means. Conversion700/1201mm/px; reference100mm/s. Retained fractions and original filenames in summaries. Existing cohort-stratified exact cage permutation omnibus and raw/Holm-three pairwise results; exploratory, no across-metric correction. Speed division is an exploratory adjustment, not proof of proportionality. All frames aligned exactly; no video reprocessing. Source measurements preserved. Producers tests/summarizeLocomotingWholeTail.m and tests/plotLocomotingWholeTail.py.\n'
(O/'README.md').write_text(notes)
dest=R/'BEAMCROSS/DRAFTFIGS/tail-metrics/whole-no-vertical-weight/per-crop-pixel/locomotion-scatters';dest.mkdir(exist_ok=True)
for p in O.rglob('*'):
 if p.is_file() and p.suffix in ['.svg','.csv','.json','.md']:
  q=dest/p.relative_to(O);q.parent.mkdir(exist_ok=True);shutil.copy2(p,q)
combined.set('viewBox','-8 0 223 223');combined.set('width','1115');E.ElementTree(combined).write(O/'preview.svg')
