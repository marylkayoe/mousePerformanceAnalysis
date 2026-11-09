"""Serial small MATLAB batches, with observable logs and storage guard."""
import subprocess,shutil
from pathlib import Path
out=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_entry_review_20261107')
(out/'logs').mkdir(exist_ok=True)
for first in range(1,22,4):
    if shutil.disk_usage('/System/Volumes/Data').free<20*1024**3:raise RuntimeError('Internal free space below 20 GiB')
    log=out/'logs'/f'detector_batch_{first}.log'
    print('BATCH',first,flush=True)
    cmd="addpath('/Users/yoe/Documents/REPOS/PROJECTS/mousePerformanceAnalysis/tests'); runEntranceDetectorAudit(%d,%d)"%(first,first+3)
    with log.open('w') as f:
        subprocess.run(['/Applications/MATLAB_R2024b.app/bin/matlab','-nodisplay','-batch',cmd],stdout=f,stderr=subprocess.STDOUT,check=True)
print('ALL AUDITS ATTEMPTED',flush=True)
