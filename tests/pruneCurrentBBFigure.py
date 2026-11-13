"""Explicit current-figure allowlist; verify archived bytes before any removal."""
from pathlib import Path
import json,csv,hashlib,re,tarfile
R=Path(__file__).resolve().parents[1];D=R/'BEAMCROSS/DRAFTFIGS';C=D/'CURRENT';A=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_repo_cleanup_20261113')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Current artwork plus source artwork required by retained panel composers.
art={
'figMaterials/TMCS2_S18_D0_T2_f514_centroid_trajectory.svg','figMaterials/TMCS2_S18_D0_T2_f514_slip_gradient_tail_weightbar_purple.svg',
'figMaterials/TMCS2_S18_D0_T2_forward_speed_stops.svg','figMaterials/TMCS2_S18_D0_T2_under_bar_motion_slips_downward_areas.svg',
'within-session-diagnostics-20261112/first_to_last_locomoting_speed_D0_D14_markers_matched.svg','within-session-diagnostics-20261112/supplied_first_last_speed.svg',
'last-crossing-spatial/speed_change_D14_minus_D0_last_retained_reference.svg','last-crossing-spatial/speed_change_reference_template.svg',
'D0-first-trial-panels/aligned-overview/D0_aligned_overview_total_slip_score.svg',
'last-crossing-paired-20261112/aligned-four-D14/D14_last_four_metrics.svg',
'font-alignment-20261112/supplied_assembly.svg','assembled-panel-layout-20261112/supplied_assembly.svg','L-panel-layout-20261112/supplied_assembly.svg'}
keepdirs=['CURRENT/','analysis-data/','within-session-diagnostics-20261112/','last-crossing-spatial/','last-crossing-D14/','last-crossing-paired-20261112/','tail-metrics/centroid3-height10-example-panels/','tail-metrics/current-centroid3-height10/','slip-movie-example-review/']
# Data consumed directly by current generation or validation, without alternate renders.
keepdata=['D0-first-trial-panels/trial_values.csv','D0-first-trial-panels/event_validation.csv','D0-first-trial-panels/spatial_source.csv','D0-first-trial-panels/spatial_summary.csv','D0-first-trial-panels/group_statistics.csv','D0-first-trial-panels/group_statistics.json','D0-first-trial-panels/aligned-overview/statistics.json','D0-first-trial-panels/aligned-overview/total_slip_score_mouse_values.csv','speed-presentation/speed-profile-source.json','posture-presentation/posture-profile-source.json','tail-metrics/CDF-D14-and-change/trial-index.csv','tail-metrics/whole-motion-reweighted/cage_tests.py','figMaterials/D0_pooled_event_positions_10mm_mirrored.csv','figMaterials/D0_pooled_event_positions_10mm_mirrored.json']
# Main pipeline, direct figure producers, movie producers and reproducibility audits.
seeds='''plotAlignedD0Overview.py plotD0FirstTrialReferencePanels.py testD0FirstTrialReferencePanels.py plotD14LastFourAbsolute.py plotLastCrossingD14.py plotLastCrossingSpatialProfiles.py plotLastSpeedChangeReference.m analyzeWithinSessionBB.m summarizeLastCrossingBB.m analyzeLastCrossingPairedBB.m focusLastCrossingBB.m plotFirstLastSpeedCompact.m resizePastedSpeedMarkers.rb repairBeamTraceAlignment.py makeTailCentroid3ExamplePanels.py makeTailCentroid3Height10Scatters.py renderMarkedTailExamples.py tailMovieDisplay.py bbSimpleSVG.py prepareCentroidBoundaryMovies.py validateTailCentroidBoundary.py exportSelectedGroupMovieColumns.m createThreeGroupUnderbarPresentations.py renderUnderbarMotionMovie.py stackUnderbarTriplets.py selectGroupMovieExamples.py selectD14TailMovieExamples.py prepareNormalizedTailExamples.m prepareMarkedTailExamples.m exportAllWholeTailTraces.m summarizeWholeTailNoVerticalWeight.m summarizeLocomotingWholeTail.m plotWholeTailPerPixel.py plotLocomotingWholeTail.py reportTailCentroidBoundary.py runTailBoundaryMovies.py scoreTailEventsPawConvention.m analyzeNormalizedTailSlips.m packageCurrentBBFigure.py pruneCurrentBBFigure.py verifyBBfigurePackage.py'''.split()
allcode={p.name:p for p in (R/'tests').iterdir() if p.is_file() and p.suffix in {'.py','.m','.rb','.sh'}};keep=set(seeds)
# Retain code invoked or read as a helper by current code, recursively (incl MATLAB names).
while True:
 old=keep.copy();texts='\n'.join(allcode[n].read_text(errors='replace') for n in keep if n in allcode)
 for n in allcode:
  if n in texts or (Path(n).suffix=='.m' and re.search(r'\b'+re.escape(Path(n).stem)+r'\b',texts)):keep.add(n)
 if old==keep:break
plan=[]
for p in D.rglob('*'):
 if not p.is_file() or C in p.parents or "__pycache__" in p.parts:continue
 rel=str(p.relative_to(D));ext=p.suffix.lower();why=None
 if p.name.startswith('~ai-') or ext=='.ai':continue
 if ext in {'.md','.txt'}:continue
 if rel.startswith(('tail-metrics/current-centroid3-height10/','tail-metrics/centroid3-height10-example-panels/')):continue
 if rel in art or rel in keepdata:continue
 if rel.startswith('figMaterials/tail_motion_example_stills/') and ('strong_center_emphasized_f1186' in p.name or 'strong_center_emphasized_f1639' in p.name):continue
 if rel.startswith('figMaterials/') and p.parent==D/'figMaterials' and (p.name.startswith('TMCS2_S18_D0_T2_f514') or p.name.startswith('TMCS2_S18_D0_T2_forward_speed_stops') or p.name.startswith('TMCS2_S18_D0_T2_under_bar_motion_slips_downward_areas')) and ext not in {'.png'}:continue
 if any(rel.startswith(x) for x in keepdirs) and ext not in {'.svg','.png','.pdf','.fig','.jpg'}:continue
 if ext in {'.m','.py','.rb'}:continue # data-local helper code; separately audited below
 why='superseded figure asset/data; canonical/archive preserved'
 plan.append(p)
for p in (R/'tests').iterdir():
 if not p.is_file() or p.suffix not in {'.py','.m','.rb','.sh'} or p.name in keep:continue
 text=p.read_text(errors='replace')
 if 'BEAMCROSS' in text or 'balance_beam' in text or re.search(r'(Tail|Slip|D0|D14|CDF|Posture|Speed|Beam)',p.name):plan.append(p)
# Prior bulk products are externally canonical; retain their notes/manifests only.
for parent in [R/'BEAMCROSS/results',R/'BEAMCROSS/example-videos']:
 for p in parent.rglob('*'):
  if p.is_file() and p.suffix.lower() not in {'.md','.json','.txt'} and str(p.relative_to(R)) in json.loads((A/'snapshot_sha256.json').read_text()):plan.append(p)
plan=sorted(set(plan));hashes=json.loads((A/'snapshot_sha256.json').read_text());rows=[]
for p in plan:
 rel=str(p.relative_to(R));assert rel in hashes and sha(p)==hashes[rel],rel
 rows.append(dict(path=rel,bytes=p.stat().st_size,sha256=hashes[rel],reason='superseded or canonical external duplicate; not current figure dependency'))
with tarfile.open(A/'precleanup_working_state.tar.gz','r:gz') as tar:
 for r in rows:assert hashlib.sha256(tar.extractfile(r['path']).read()).hexdigest()==r['sha256']
with (C/'cleanup_20261113.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
(C/'retained_script_roots.json').write_text(json.dumps(dict(roots=seeds,dependencyClosure=sorted(keep)),indent=2))
for p in plan:p.unlink()
print('Removed after archive verification',len(rows),'files',sum(r['bytes'] for r in rows),'bytes')
