"""Recover frame-level motion-weighted heights for the two example trials."""
import csv, io, math, zipfile
from collections import defaultdict
from pathlib import Path
p=Path(__file__).resolve().parent; archive=p.parent/'analysis-data'/'tail-and-behavior-frame-traces.zip'
files=[('sedentary','TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4'),('run','TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4')]
rows=[]
with zipfile.ZipFile(archive) as z:
 for group,name in files:
  with z.open('balance_beam_events_traces_L40_20261106/trials/'+name+'.trace.csv') as f:
   for r in csv.DictReader(io.TextIOWrapper(f,encoding='utf-8',newline='')):
    try:x=float(r['XEntryRightFraction']);h=float(r['MotionHeightWeighted'])
    except ValueError:continue
    if not math.isfinite(x) or not math.isfinite(h):continue
    mm=(x*1279-42)*700/1201
    if not 0<=mm<=700:continue
    rows.append(dict(File=name,Group=group,TraversalFrame=r['TraversalFrame'],OriginalFrame=r['OriginalFrame'],PositionMM=mm,MotionHeightMM=h*700/1201,StopMask=r['StopMask']))
with (p/'example-motion-height-frames.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
for g,_ in files: print(g,sum(r['Group']==g for r in rows),'valid in-beam frames')
