#!/usr/bin/env python3
"""Serial MATLAB batches, per-video timing preparation, resumable without overwrite."""
import argparse, json, shutil, subprocess, time
from pathlib import Path
from prepareTaraBeamRerun import timing
ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);ap.add_argument('--batch-size',type=int,default=12);a=ap.parse_args()
out=a.output.resolve();m=json.loads((out/'run_manifest.json').read_text());rows=m['files']
budget=json.loads((out/'storage_approval.json').read_text())['maxNewBytes']
for start in range(0,len(rows),a.batch_size):
 batch=rows[start:start+a.batch_size]
 pending=[r for r in batch if not (out/'trials'/f"{r['file']}.status.json").exists()]
 if not pending:continue
 used=sum(p.stat().st_size for p in out.rglob('*') if p.is_file())
 assert used<budget-200_000_000, 'Stop: approaching approved output size; no data deleted'
 assert shutil.disk_usage('/System/Volumes/Data').free>=20*1024**3, 'Stop: internal free space below 20 GiB'
 for row in pending:
  print('TIMING',row['index'],row['file'],flush=True)
  try: timing(out,row)
  except Exception as e:
   (out/'metadata'/f"{row['file']}.json").write_text(json.dumps({'file':row['file'],'error':str(e)}))
 indices=' '.join(str(r['index']) for r in pending)
 command=f"addpath('{out}/code_snapshot'); rerunTaraBeamDataset('{out}',[{indices}])"
 log=out/'logs'/f'batch_{start+1:03d}_{start+len(batch):03d}.log'
 print('BATCH',indices,'bytes',used,flush=True)
 result=subprocess.run(['/Applications/MATLAB_R2024b.app/bin/matlab','-nodisplay','-logfile',str(log),'-batch',command])
 if result.returncode:
  raise SystemExit(f'MATLAB batch failed with status {result.returncode}; inspect {log}; safe to resume')
 statuses=[json.loads(p.read_text()) for p in (out/'trials').glob('*.status.json')]
 progress={'finished':len(statuses),'total':len(rows),'complete':sum(s['status']=='complete' for s in statuses),'partial':sum(s['status']=='partial' for s in statuses),'failed':sum(s['status']=='failed' for s in statuses),'updatedUnixTime':time.time()}
 (out/'progress.json').write_text(json.dumps(progress,indent=2));print('PROGRESS',json.dumps(progress),flush=True)
print('ALL_TRIALS_ATTEMPTED',flush=True)
