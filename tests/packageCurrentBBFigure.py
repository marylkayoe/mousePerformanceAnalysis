"""Archive working state before selected-figure cleanup; no canonical results deleted."""
from pathlib import Path
import subprocess,tarfile,hashlib,json,csv
R=Path(__file__).resolve().parents[1];A=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_repo_cleanup_20261113');C=R/'BEAMCROSS/DRAFTFIGS/CURRENT';A.mkdir(exist_ok=True)
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
if __name__=='__main__':
 files={Path(x) for x in subprocess.check_output(['git','ls-files','-co','--exclude-standard','-z'],cwd=R).decode().split('\0') if x and (R/x).is_file()}
 files|={p.relative_to(R) for p in (R/'BEAMCROSS/DRAFTFIGS').rglob('*') if p.is_file() and not p.name.startswith('~ai-') and '__pycache__' not in str(p)}
 archive=A/'precleanup_working_state.tar.gz';assert not archive.exists()
 hashes={str(p):sha(R/p) for p in sorted(files)}
 with tarfile.open(archive,'w:gz') as t:
  for p in sorted(files):t.add(R/p,arcname=str(p),recursive=False)
 with tarfile.open(archive,'r:gz') as t:
  for p,h in hashes.items():assert hashlib.sha256(t.extractfile(p).read()).hexdigest()==h,p
 (A/'snapshot_sha256.json').write_text(json.dumps(hashes,indent=2))
 (C/'archive_20261113.json').write_text(json.dumps(dict(archive=str(archive),sha256=sha(archive),files=len(hashes),verified=True),indent=2))
 print('ARCHIVE VERIFIED',len(hashes),archive,flush=True)
