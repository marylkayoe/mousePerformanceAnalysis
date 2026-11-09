#!/usr/bin/env python3
"""Package a completed canonical rerun without source videos or deleting originals."""
import argparse, hashlib, json, zipfile
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);a=ap.parse_args();root=a.output.resolve()
archive=root/'Tara_balance_beam_L40_events_traces_row_profiles_20261106.zip'
assert (root/'VALIDATION_REPORT.txt').is_file(), 'Finalize and report before packaging'
statuses=[json.loads(p.read_text()) for p in (root/'trials').glob('*.status.json')]
expected=len(json.loads((root/'run_manifest.json').read_text())['files'])
assert len(statuses)==expected, 'Every retained trial must have an explicit outcome'
files=sorted(p for p in root.rglob('*') if p.is_file() and p!=archive and p.suffix not in {'.zip','.sha256'} and not p.name.startswith('taildrop_') and p.name not in {'archive_verification.json','TARA_NOTIFICATION_TEST.txt','Tara_analysis_finished.txt','delivery_plan.json','delivery_result.json'})
video_suffixes={'.mp4','.avi','.mov','.mkv','.m4v','.webm'}
assert not any(p.suffix.lower() in video_suffixes for p in files), 'Source video detected in package'
size=sum(p.stat().st_size for p in files)
budget=json.loads((root/'storage_approval.json').read_text())['maxNewBytes']
assert size*2.01+2_000_000 < budget, 'Canonical set plus ZIP could exceed approved storage allowance'
manifest={'canonicalRoot':str(root),'archiveName':archive.name,'sourceVideosIncluded':False,'files':[{'path':str(p.relative_to(root)),'bytes':p.stat().st_size} for p in files]}
(root/'archive_contents.json').write_text(json.dumps(manifest,indent=2))
files.append(root/'archive_contents.json') if root/'archive_contents.json' not in files else None
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
    for p in files:z.write(p,arcname=str(Path(root.name)/p.relative_to(root)))
with zipfile.ZipFile(archive) as z:
    corrupt=z.testzip(); assert corrupt is None, f'ZIP CRC verification failed: {corrupt}'
h=hashlib.sha256()
with archive.open('rb') as f:
    for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
verification={'archive':str(archive),'bytes':archive.stat().st_size,'sha256':h.hexdigest(),'crcAllEntriesPassed':True,'entries':len(files),'sourceVideosIncluded':False}
(root/'archive_verification.json').write_text(json.dumps(verification,indent=2))
Path(str(archive)+'.sha256').write_text(f'{h.hexdigest()}  {archive.name}\n')
print(json.dumps(verification),flush=True)
