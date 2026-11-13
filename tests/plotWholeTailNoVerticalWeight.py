"""Conventional D0-first/D14-last mean raw whole-tail motion scatters."""
from pathlib import Path
import shutil, csv, math
R=Path(__file__).resolve().parents[1];O=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_no_vertical_weight_20261113')
upper=150*math.ceil(max(float(r['MeanWholeMotion']) for stem in ['D0_first','D14_last'] for r in csv.DictReader((O/(stem+'_whole_summary.csv')).open()))/150)
s=(R/'tests/plotTailCandidateResults.py').read_text()
s=s.replace("O=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_MAD3p5_height7p5_results_20261112')",f'O=Path({str(O)!r})').replace("stem+'_peak_counts.csv'","stem+'_whole_summary.csv'").replace("q['PeakCount']","q['MeanWholeMotion']").replace(",validSeconds=float(q['JointValidSeconds']),rawThreshold=float(q['RawProminenceThreshold'])",",validFrames=int(q['ValidFrames'])")
s=s.replace("om,pairs=test(rows);","assert len(rows)==42;om,pairs=test(rows);").replace('Tail slips,','Whole-tail motion,').replace('_tail_slips','_whole_tail_motion')
s=s.replace("txt(texts[0],","txt(texts[1],'raw a.u.');txt(texts[0],").replace("upper=max(3,3*math.ceil(max(r['value'] for r in rows)/3))",f"upper={upper}")
s=s.replace("f'p = {om:.3f}'","('p < 0.001' if om<.001 else f'p = {om:.3f}')")
s=s.replace("txt(e,f'{v:g}')","txt(e,f'{v:g}');e.set('text-anchor','end');e.set('transform','translate(5 '+e.get('transform').split()[-1])")
exec(compile(s,str(R/'tests/plotTailCandidateResults.py'),'exec'),{'__file__':str(R/'tests/plotTailCandidateResults.py'),'__name__':'__main__'})
dest=R/'BEAMCROSS/DRAFTFIGS/tail-metrics/whole-no-vertical-weight';dest.mkdir(exist_ok=True)
(O/'README.md').write_text('Whole-tail motion without vertical weighting. D0 first retained and D14 last retained crossing per mouse; 42 mice/15 cages per day. Mean raw motion over current joint-valid frames. Each frame: sum over all crop rows/columns of absolute adjacent-frame difference /255 times destination-frame no-mouse probability squared, using minimum mouse-present exclusion width15. All vertical weights1. No temporal smoothing or median/MAD normalization of whole motion. Existing height/detector/masks checked exactly against prior current-criteria outputs; original profile reconstruction validated by analyzer. This is raw summed pixel-change, dependent on crop/image geometry and body exclusion, not momentum. Invalid/nonfinite samples excluded explicitly; no-event frames included. Dots and bars describe mice; diamonds cage means. Displayed p is exploratory cohort-stratified cage permutation omnibus; pairwise outputs retained in statistics.json, no across-outcome correction. Canonical source/videos/results unchanged. Producer: BEAMCROSS/analyzeCurrentTailCriteria.m, tests/summarizeWholeTailNoVerticalWeight.m, tests/plotWholeTailNoVerticalWeight.py.\n')
for pattern in ['*.svg','*.json','*_whole_summary.csv','mouse_values.csv','README.md']:
 for p in O.glob(pattern):shutil.copy2(p,dest/p.name)
