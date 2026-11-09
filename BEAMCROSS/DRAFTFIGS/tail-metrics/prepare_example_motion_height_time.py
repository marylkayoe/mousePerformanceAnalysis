"""Keep all traversal frames (including invalid heights) for example traces."""
import csv,io,zipfile
from pathlib import Path
folder=Path(__file__).resolve().parent
archive=folder.parent/'analysis-data'/'tail-and-behavior-frame-traces.zip'
examples=[('sedentary','TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4'),('run','TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4')]
rows=[]
with zipfile.ZipFile(archive) as z:
 for group,name in examples:
  entry='balance_beam_events_traces_L40_20261106/trials/'+name+'.trace.csv'
  with z.open(entry) as raw, io.TextIOWrapper(raw,encoding='utf-8',newline='') as f:
   data=list(csv.DictReader(f));t0=float(data[0]['TimeSeconds'])
   for r in data:
    rows.append(dict(File=name,Group=group,TraversalFrame=r['TraversalFrame'],OriginalFrame=r['OriginalFrame'],ElapsedSeconds=float(r['TimeSeconds'])-t0,MotionHeightMM=float(r['MotionHeightWeighted'])*700/1201,InvalidPair=r['RowProfileInvalidPair'],StopMask=r['StopMask']))
with (folder/'example-motion-height-time-frames.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
for group,name in examples:print(group,sum(r['Group']==group for r in rows),'frames')
