"""Read-only audit of current selected figure package; no regeneration."""
from pathlib import Path
import csv,json,hashlib,math,xml.etree.ElementTree as E,runpy
R=Path(__file__).resolve().parents[1];D=R/'BEAMCROSS/DRAFTFIGS';C=D/'CURRENT'
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
def rows(p):return list(csv.DictReader(p.open()))
manifest=json.loads((C/'figure_package_manifest.json').read_text());errors=[]
for x in manifest:
 p=R/x['path']
 if not p.exists() or sha(p)!=x['sha256']:errors.append(x['path'])
assert not errors,errors
for p in D.rglob('*.svg'):E.parse(p)
pairs=rows(D/'within-session-diagnostics-20261112/mouse_first_last_changes.csv');pairs=[r for r in pairs if r['Metric']=='speed']
for day in ['0','14']:
 a=[r for r in pairs if r['Day']==day];assert len(a)==42 and len({r['CageID'] for r in a})==15
 for r in a:assert math.isclose(float(r['Last'])-float(r['First']),float(r['Delta']),abs_tol=1e-9)
assert len(rows(D/'D0-first-trial-panels/trial_values.csv'))==42
spatial=rows(D/'last-crossing-spatial/selected_crossings.csv');assert len(spatial)==84
for r in pairs:
 s=next(s for s in spatial if s['MouseID']==r['MouseID'] and s['Day']==r['Day']);assert s['File']==r['LastFile']
T=D/'tail-metrics/current-centroid3-height10';mv=rows(T/'mouse_values.csv');st=json.loads((T/'statistics.json').read_text());test=runpy.run_path(str(D/'tail-metrics/whole-motion-reweighted/cage_tests.py'))['test']
for sel,count in [('D0_first',87),('D14_last',66)]:
 ss=rows(T/(sel+'_summary.csv'));ee=rows(T/(sel+'_events.csv'));assert len(ss)==42
 assert sum(int(r['CountHeightFiltered']) for r in ss)==count
 for r in ss:
  es=[e for e in ee if e['File']==r['File'] and e['PassHeight']=='1'];assert len(es)==int(r['CountHeightFiltered']);assert all(float(e['HeightAtPeakMM'])<=10 for e in es)
  assert math.isclose(sum(float(e['EventScore']) for e in es),float(r['TotalScoreHeightFiltered']),abs_tol=1e-8)
 for metric in ['LocomotingMean','TotalScoreHeightFiltered']:
  rr=[dict(r,value=float(r['value'])) for r in mv if r['selection']==sel and r['metric']==metric];assert len(rr)==42
  p,_=test(rr);expected=next(r['omnibus_p'] for r in st if r['selection']==sel and r['metric']==metric);assert math.isclose(p,expected,abs_tol=1e-12)
movies=json.loads((C/'videos/manifest.json').read_text());assert len(movies)==2
assert {p.name for p in (R/'BEAMCROSS').rglob('*.mp4')}=={r['file'] for r in movies}
for r in movies:assert sha(C/'videos'/r['file'])==r['sha256']
print(json.dumps(dict(status='PASS',hashed_files=len(manifest),xml='all retained SVGs parse',selection='42 mice/15 cages/day; first/last mapping checked',tail='87 D0 /66 D14 events; scores and four omnibus p-values verified',movies='exactly two BB MP4s; canonical hashes match'),indent=2))
