"""Archive unselected DRAFTFIGS plots; copy/hash all before removing originals.
Default dry-run. --apply requires external archive write permission.
"""
from pathlib import Path
import csv,json,hashlib,shutil,sys,datetime
R=Path(__file__).resolve().parents[1];root=R/'BEAMCROSS/DRAFTFIGS'
archive=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/figure_plot_archive_20261111')
keep='''SLIPS&STOPS/D14_minus_D0_slip_count_score_time_stopped_three_panels
SLIPS&STOPS/slip_count_D0_mouse_cage_comparison
SLIPS&STOPS/slip_count_D14_minus_D0_mouse_cage_comparison
SLIPS&STOPS/slip_magnitude_D14_minus_D0_mouse_cage_comparison
SLIPS&STOPS/stop_time_percentage_D0_mouse_cage_comparison
SLIPS&STOPS/stop_time_percentage_D14_minus_D0_mouse_cage_comparison
figMaterials/D0_slip_score_CDF_reference_fraction_log10
figMaterials/TMCS2_S18_D0_T2_f514_centroid_trajectory
figMaterials/TMCS2_S18_D0_T2_f514_slip_gradient_tail_weightbar_purple
figMaterials/TMCS2_S18_D0_T2_forward_speed_stops
figMaterials/TMCS2_S18_D0_T2_tail_height_with_score_bottom
figMaterials/TMCS2_S18_D0_T2_tail_motion_height
figMaterials/TMCS2_S18_D0_T2_tail_motion_score
figMaterials/TMCS2_S18_D0_T2_under_bar_motion_slips_downward_areas
figMaterials/forward_speed_D0_group_comparison_illustrator
figMaterials/sample_sizes_cages_mice_crossings
posture-presentation/posture-by-day-uncentered-mm
posture-presentation/posture-height-statistics-mm
posture-presentation/posture_D14_minus_D0_profile_and_scatter_reference_style
posture-presentation/posture_change_scatter_reference_style
speed-presentation/speed-by-day-mm
speed-presentation/locomoting-speed-statistics-mm
speed-presentation/speed_D14_minus_D0_profile_and_scatter_reference_style_tight
tail-metrics/D0-spatial-motion-and-height/D0_tail_height_spatial_mean_sem
tail-metrics/D0-spatial-motion-and-height/D0_tail_score_spatial_mean_sem
tail-metrics/tail_height_D0_mouse_cage_comparison
tail-metrics/tail_score_D0_mouse_cage_comparison
tail-metrics/tail_height_D14_minus_D0_mouse_cage_comparison
tail-metrics/tail_score_D14_minus_D0_mouse_cage_comparison'''.splitlines()
keep=set(keep);rows=[]
for p in sorted(root.rglob('*')):
 if p.suffix.lower() not in ('.svg','.png','.fig','.pdf'):continue
 rel=p.relative_to(root);stem=str(rel.with_suffix(''));reason=''
 if stem in keep:reason='Current figure panel or donor containing D0 panel'
 elif 'cdf' in str(rel).lower():reason='Recent CDF retained as requested'
 elif rel.parent==Path('figMaterials') and p.name in ('original_f1369_traversal_f514.png','contrast_f1369_traversal_f514.png'):reason='Source image for current methods overlay'
 elif 'tail_motion_example_stills' in str(rel):
  if p.name.startswith(('crop_traversal_','average9_center_','center_emphasized_50pct_','strong_center_emphasized_')):reason='Selected illustration or its original/composite source dependency'
 if reason:action='keep'
 else:action='archive';reason='Unselected exploratory plot, previous layout or preview'
 rows.append(dict(relative_path=str(rel),action=action,reason=reason,bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
# Verify retained SVG external raster/vector dependencies, expanding keep as needed.
import xml.etree.ElementTree as ET
by={r['relative_path']:r for r in rows}
for r in rows:
 if r['action']!='keep' or not r['relative_path'].endswith('.svg'):continue
 p=root/r['relative_path']
 for el in ET.parse(p).getroot().iter():
  for key,value in el.attrib.items():
   if not key.endswith('href') or value.startswith(('data:','#','http')):continue
   target=(p.parent/value).resolve()
   if target.exists() and target.is_relative_to(root):
    rr=by.get(str(target.relative_to(root)))
    if rr:rr.update(action='keep',reason='Linked dependency of retained SVG')
selected=[r for r in rows if r['action']=='archive'];print(json.dumps(dict(archive=str(archive),archiveFiles=len(selected),archiveMB=sum(r['bytes'] for r in selected)/1e6,keptFiles=len(rows)-len(selected)),indent=2))
manifest=root/'PLOT_CLEANUP_20261111.csv'
with manifest.open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
if '--apply' not in sys.argv:sys.exit(0)
assert Path('/Volumes/ShosaiData').is_mount(), 'External disk unavailable'
assert not archive.exists(), 'Do not overwrite existing archive'
archive.mkdir()
for r in selected:
 p=root/r['relative_path'];dest=archive/r['relative_path'];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
 assert hashlib.sha256(dest.read_bytes()).hexdigest()==r['sha256']
shutil.copy2(manifest,archive/manifest.name)
# Delete only verified duplicated plot files from repository; canonical data untouched.
for r in selected:
 p=root/r['relative_path'];dest=archive/r['relative_path'];assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']==hashlib.sha256(dest.read_bytes()).hexdigest();p.unlink()
assert all((root/r['relative_path']).exists() for r in rows if r['action']=='keep')
(archive/'README.txt').write_text('Archived plot variants from mousePerformanceAnalysis/BEAMCROSS/DRAFTFIGS on 2026-11-11. Relative layout preserved. SHA256 and keep/archive inventory in PLOT_CLEANUP_20261111.csv. All files copied and verified before removing repository copies. Data, scripts, statistical tables and source videos untouched. Restore individual files to original relative locations if needed.\n')
print('ARCHIVE VERIFIED; repository plot cleanup complete')
