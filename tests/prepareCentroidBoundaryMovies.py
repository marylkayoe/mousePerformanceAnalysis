from pathlib import Path
import json,csv,shutil
import numpy as np
from scipy.io import loadmat
from tailMovieDisplay import prepare
B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS');O=B/'balance_beam_tail_centroid_boundary_20261113';OLD=B/'balance_beam_tail_minwidth15_smooth5_20261112';read=lambda p:list(csv.DictReader(p.open()))
manifest=json.loads((OLD/'presentations_height_trail_right_20261113/manifest.json').read_text());colors=[]
for factor in [2,3]:
 root=O/f'factor{factor}';movies=[];motion=[]
 for t in manifest:
  name=t['file'];tag=next(p.name for p in OLD.iterdir() if p.is_dir() and (p/'marked_inputs/metadata.json').exists() and json.loads((p/'marked_inputs/metadata.json').read_text())['sourceFilename']==name)
  p=OLD/tag;d=root/tag;work=d/'marked_inputs';work.mkdir(exist_ok=True)
  z=loadmat(root/'traces'/(name+'.mat'),simplify_cells=True);m=json.loads((p/'marked_inputs/metadata.json').read_text());m['invalid']=np.asarray(z['invalid'],bool).tolist()
  for f in ['rows','above','below']:
   target=work/(f+'.csv')
   if not target.exists():target.symlink_to(d/(f+'.csv'))
  masks=read(p/'marked_inputs/masks_height.csv');n=len(masks);valid=~np.asarray(z['invalid'],bool);height=np.asarray(z['motionHeight']);motionvec=1000*z['wholeUnweighted']/(m['height']*m['width']);keep=valid&~np.asarray(z['stoppingFrames'],bool)&np.isfinite(z['forwardSpeeds'])&(z['forwardSpeeds']>=40)
  for k,r in enumerate(masks):r['MotionHeightMM']=height[k];r['PeakJointValid']=int(valid[k])
  with (work/'masks_height.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=masks[0]);w.writeheader();w.writerows(masks)
  (work/'metadata.json').write_text(json.dumps(m));(d/'preparation_status.json').write_text(json.dumps(dict(status='complete',variant=factor,validation='original profile, whole motion, below motion and height reproduce; row-specific override is intentional')))
  for f in ['post_mouse_crop_lossless.mkv','frame_mapping.csv','source_columns_frame_by_column.csv','tail_slip_events.csv']:
   if not (d/f).exists():(d/f).symlink_to((p/f).resolve())
  es=read(root/('D0_first_events.csv' if '_D00_' in name else 'D14_last_events.csv'))
  for e in es:
   if e['File']!=name or e['PassHeight'] not in ['1','true']:continue
   k=int(e['PeakTraversalFrame'])-1
   movies.append(dict(e,TraversalFrame=e['PeakTraversalFrame'],OriginalFrame=e['PeakOriginalFrame'],HeightMM=e['HeightAtPeakMM'],RawAmplitude=float(z['smoothed'][k]),ProminenceMAD='nan',ThresholdMAD=3.5))
  for k,fr in enumerate(z['originalFrames']):motion.append(dict(File=name,OriginalFrame=int(fr),KeepLocomotion=int(keep[k]),UnscaledWholeMotionPerPixelTimes1000=float(motionvec[k])))
  sm,_=prepare(motionvec,keep,17,0);colors.extend(sm[np.isfinite(sm)])
 for f,rows in [('normalized_movie_events.csv',movies),('motion_colors.csv',motion)]:
  with (root/f).open('w') as h:w=csv.DictWriter(h,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
limits=np.percentile(colors,[5,95]);(O/'movie_color_limits.json').write_text(json.dumps(limits.tolist()));print('Shared color limits',limits)
