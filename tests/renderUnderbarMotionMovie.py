"""Render full-frame traversal with validated mouse-weighted underbar columns."""
from pathlib import Path
import argparse,csv,json,subprocess,hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont
p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--centroid-trail',action='store_true',help='Optional fixed-size centroid and preceding0.3s trail; no speed encoding.');p.add_argument('--trail-length-pixels',type=float,help='Trail arc length in source pixels; overrides 0.3s history.');p.add_argument('--playback-fps',type=int,default=30);p.add_argument('--trail-width',type=int,default=2);p.add_argument('--speed-trail',action='store_true');p.add_argument('--motion-smooth-sigma',type=float,default=0);p.add_argument('--motion-transform',choices=['linear','log1p'],default='linear');p.add_argument('--shared-column-max',type=float);p.add_argument('--shared-slip-score-max',type=float);p.add_argument('--slip-size-compressed',action='store_true');p.add_argument('--slip-magnitude-size',action='store_true');p.add_argument('--slip-markers',action='store_true');p.add_argument('--centroid-palette',choices=['blue-cyan-yellow','black-red','black-red-yellow'],default='blue-cyan-yellow');p.add_argument('--black-stops',action='store_true');p.add_argument('--centroid-speed',action='store_true');p.add_argument('--centroid-radius',type=int,default=3);p.add_argument('--speed-color-max',type=float,default=300);p.add_argument('--speed-adjusted',action='store_true');p.add_argument('--output',type=Path);p.add_argument('--display-depth',type=float,default=80);args=p.parse_args();I=args.folder;O=args.output or I;O.mkdir(exist_ok=True)
m=json.loads((I/'metadata.json').read_text());v=json.loads((I/'validation.json').read_text());assert v['allFramesMatch'];columns=np.loadtxt(I/'raw_columns.csv',delimiter=',');prob=np.loadtxt(I/'mouse_column_probability.csv',delimiter=',');mapping=list(csv.DictReader((I/'frame_mapping.csv').open()));n,w=columns.shape;h=m['height'];assert n==m['nFrames']==len(mapping) and w==m['width'];assert prob.shape==columns.shape
stage='raw';numeric_valid=np.isfinite(columns).all(axis=1);scale_report={}
if args.speed_adjusted:
 trace=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')/(m['file']+'.trace.csv');tr=list(csv.DictReader(trace.open()));assert [r['OriginalFrame'] for r in tr]==[r['OriginalFrame'] for r in mapping]
 speeds=np.array([float(r['ForwardSpeed']) for r in tr]);logs=np.log1p(speeds);logs[logs<0]=np.finfo(float).eps
 with np.errstate(divide='ignore',invalid='ignore'):multipliers=160/logs;scalar_adjusted=columns.sum(axis=1)*multipliers;columns=columns*multipliers[:,None]
 predicted=columns.sum(axis=1);reference=np.array([float(r['SpeedAdjusted']) for r in mapping]);assert np.allclose(scalar_adjusted,reference,atol=1e-6,rtol=1e-6,equal_nan=True)
 finite_column_rows=np.isfinite(columns).all(axis=1);assert np.allclose(predicted[finite_column_rows],reference[finite_column_rows],atol=1e-6,rtol=1e-6,equal_nan=True)
 numeric_valid=np.isfinite(columns).all(axis=1);stage='speed-adjusted';scale_report=dict(sumMatchesSavedSpeedAdjusted=True,invalidFrames=int((~numeric_valid).sum()),formula='160/log1p(forwardSpeed), negative logarithms replaced by eps; stops retained')
 with (O/'speed_adjustment.csv').open('w',newline='') as f:
  writer=csv.writer(f);writer.writerow(['OriginalFrame','ForwardSpeed','SpeedMultiplier','ColumnSum','SavedSpeedAdjusted','FiniteColumns'])
  writer.writerows((r['OriginalFrame'],speeds[k],multipliers[k],predicted[k],reference[k],bool(numeric_valid[k])) for k,r in enumerate(mapping))
if args.centroid_speed:
 assert args.centroid_trail and args.speed_color_max>0
 tr=list(csv.DictReader((Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')/(m['file']+'.trace.csv')).open()))
 assert [r['OriginalFrame'] for r in tr]==[r['OriginalFrame'] for r in mapping]
 speed_mm=np.array([float(r['ForwardSpeed']) for r in tr])*700/1201
 stop_mask=np.array([float(r['StopMask'])!=0 for r in mapping])
 def speed_color(value):
  if not np.isfinite(value):return (160,160,160)
  t=np.clip(value/args.speed_color_max,0,1)
  if args.centroid_palette=='black-red':return (int(round(255*t)),0,0)
  anchors=np.array([[0,0,0],[255,0,0],[255,240,0]]) if args.centroid_palette=='black-red-yellow' else np.array([[30,80,255],[0,210,210],[255,230,30]])
  segment=min(int(t*2),1);u=t*2-segment
  return tuple(np.rint(anchors[segment]*(1-u)+anchors[segment+1]*u).astype(int))
first=int(mapping[0]['OriginalFrame']);last=int(mapping[-1]['OriginalFrame']);assert last-first+1==n
name=Path(m['file']).stem+('_speed_adjusted' if args.speed_adjusted else '')+('_underbar_columns_centroid.mp4' if args.centroid_trail else '_underbar_columns.mp4');name=name.replace('.mp4','_speed_color.mp4') if args.centroid_speed else name;out=O/name;assert not out.exists();FF='/opt/homebrew/bin/ffmpeg';HEADER=56 if args.centroid_speed else 32;H=h+HEADER;assert w%2==0 and H%2==0
base=m['barTopOriginal']+m['barThickness']-1;amplitude=min(args.display_depth,h-1-base-8);maximum=float(np.max(columns[numeric_valid & (np.arange(n)>0)]));maximum=args.shared_column_max if args.shared_column_max is not None else maximum;assert maximum>0
def display_fraction(value):
 return np.log1p(value)/np.log1p(maximum) if args.motion_transform=='log1p' else value/maximum
assert args.motion_smooth_sigma>=0
display_columns=display_fraction(columns)
if args.motion_smooth_sigma>0:
 radius=int(np.ceil(3*args.motion_smooth_sigma));xx=np.arange(-radius,radius+1);kernel=np.exp(-.5*(xx/args.motion_smooth_sigma)**2);kernel/=kernel.sum()
 for k in np.flatnonzero(numeric_valid):
  active=prob[k]>0;starts=np.flatnonzero(np.diff(np.r_[False,active,False].astype(int))==1);ends=np.flatnonzero(np.diff(np.r_[False,active,False].astype(int))==-1)
  for a,b in zip(starts,ends):
   display_columns[k,a:b]=np.convolve(np.pad(display_columns[k,a:b],radius,mode='edge'),kernel,mode='valid')
slip_marks=[]
if args.slip_markers:
 events=list(csv.DictReader((Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/analysis-data/events.csv').open()))
 for event in events:
  if event['File']!=m['file'] or event['Type']!='slip':continue
  a=int(event['StartTraversalFrame'])-1;b=int(event['EndTraversalFrame']);values=np.array([float(r['SavedMovementTrace']) for r in mapping[a:b]])
  if not np.isfinite(values).any():raise ValueError('Slip has no finite detector samples')
  peak=a+int(np.nanargmax(values))
  if not numeric_valid[peak]:raise ValueError('Slip peak has undefined columns')
  x=int(np.argmax(columns[peak]));y=float(base+amplitude*display_columns[peak,x])
  slip_marks.append(dict(event=int(event['EventNumber']),peakIndex=peak,originalFrame=int(mapping[peak]['OriginalFrame']),eventMagnitude=float(np.maximum(values-m['parameters']['SLIPTHRESHOLD'],0).sum()),detectorPeak=float(values[peak-a]),sourceXZeroBased=x,sourceYZeroBased=y))
 if args.slip_magnitude_size:
  largest=args.shared_slip_score_max if args.shared_slip_score_max is not None else max(mark['eventMagnitude'] for mark in slip_marks)
  assert largest>0 and all(np.isfinite(mark['eventMagnitude']) for mark in slip_marks)
  for mark in slip_marks:mark['radiusPixels']=(4+8*(mark['eventMagnitude']/largest)**0.25) if args.slip_size_compressed else 12*np.sqrt(mark['eventMagnitude']/largest)
 (O/'slip_markers.json').write_text(json.dumps(slip_marks,indent=2))
src=subprocess.Popen([FF,'-v','error','-i',m['sourceVideo'],'-vf',f'trim=start_frame={first-1}:end_frame={last},format=gray','-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
enc=subprocess.Popen([FF,'-v','error','-f','rawvideo','-pix_fmt','rgb24','-s',f'{w}x{H}','-r',str(args.playback_fps),'-i','-','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-threads','4',str(out)],stdin=subprocess.PIPE)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16);checks=[0,n//2,n-1];samples={};maxk=int(np.unravel_index(np.argmax(np.where(np.isfinite(columns),columns,-np.inf)),columns.shape)[0]);checks.append(maxk)
if args.centroid_speed and args.black_stops and stop_mask.any():checks.append(int(np.flatnonzero(stop_mask)[len(np.flatnonzero(stop_mask))//2]))
try:
 for k in range(n):
  raw=src.stdout.read(w*h);assert len(raw)==w*h
  im=Image.new('RGB',(w,H),'black');im.paste(Image.frombytes('L',(w,h),raw).convert('RGB'),(0,HEADER));d=ImageDraw.Draw(im)
  d.text((10,7),f"{'_'.join(m['file'].split('_')[:2])} | {m['file'].split('_BB_')[1].split('_')[0]} {m['file'].split('_')[-2]} | frame {mapping[k]['OriginalFrame']} | {stage} under-bar motion",font=font,fill='white')
  if args.centroid_speed:
   d.text((10,32),'Centroid speed (mm/s)',font=font,fill='white')
   for xx in range(180):d.line([(205+xx,35),(205+xx,47)],fill=speed_color(xx/179*args.speed_color_max))
   d.text((190,31),'0',font=font,fill='white');d.text((395,31),f'{args.speed_color_max:g} | {speed_mm[k]:.0f} mm/s'+(' | STOP (black)' if args.black_stops and stop_mask[k] else ''),font=font,fill='white')
  if k==0:d.text((w-215,7),'No preceding frame',font=font,fill='#ffb060')
  elif not numeric_valid[k]:d.text((w-275,7),'Speed adjustment undefined',font=font,fill='#ffb060')
  else:
   active=prob[k]>0;starts=np.flatnonzero(np.diff(np.r_[False,active,False].astype(int))==1);ends=np.flatnonzero(np.diff(np.r_[False,active,False].astype(int))==-1)-1
   for a,b in zip(starts,ends):
    points=[(x,HEADER+base+amplitude*display_columns[k,x]) for x in range(a,b+1)]
    if len(points)>1:d.line(points,fill='white',width=4);d.line(points,fill='#ed681a',width=2)
  if args.centroid_trail:
   pts=[]
   start=max(0,k-round(.3*m['analysisFrameRate']))
   if args.trail_length_pixels is not None:
    assert args.trail_length_pixels>0
    start=k;distance=0.0
    while start>0:
     current=np.array([float(mapping[start][key]) for key in ['CentroidX','CentroidYOriginal']]);previous=np.array([float(mapping[start-1][key]) for key in ['CentroidX','CentroidYOriginal']])
     if not np.isfinite([current,previous]).all():break
     step=float(np.linalg.norm(current-previous))
     if distance+step>args.trail_length_pixels:break
     distance+=step;start-=1
   for q in range(start,k+1):
    x=float(mapping[q]['CentroidX']);y=float(mapping[q]['CentroidYOriginal'])
    if not np.isfinite([x,y]).all():
     if len(pts)>1:d.line(pts,fill='white',width=3);d.line(pts,fill='black',width=1)
     pts=[];continue
    pts.append((x-1,y-1+HEADER))
   if len(pts)>1:d.line(pts,fill='white',width=3);d.line(pts,fill='black',width=1)
   x=float(mapping[k]['CentroidX'])-1;y=float(mapping[k]['CentroidYOriginal'])-1+HEADER
   if np.isfinite([x,y]).all():d.ellipse((x-args.centroid_radius,y-args.centroid_radius,x+args.centroid_radius,y+args.centroid_radius),fill=((0,0,0) if args.black_stops and stop_mask[k] else speed_color(speed_mm[k])) if args.centroid_speed else 'white',outline='white' if args.centroid_speed else 'black',width=2 if args.centroid_speed else 1)
  if args.centroid_trail and args.speed_trail:
   assert args.centroid_speed
   outline=[]
   for q in range(start,k+1):
    xy0=(float(mapping[q]['CentroidX'])-1,float(mapping[q]['CentroidYOriginal'])-1+HEADER)
    if np.isfinite(xy0).all():outline.append(xy0)
   if len(outline)>1:d.line(outline,fill='white',width=args.trail_width+2,joint='curve')
   for q in range(start+1,k+1):
    xy=[(float(mapping[j]['CentroidX'])-1,float(mapping[j]['CentroidYOriginal'])-1+HEADER) for j in [q-1,q]]
    if np.isfinite(xy).all():d.line(xy,fill=(0,0,0) if args.black_stops and stop_mask[q] else speed_color(speed_mm[q]),width=args.trail_width)
   if np.isfinite([x,y]).all():d.ellipse((x-args.centroid_radius,y-args.centroid_radius,x+args.centroid_radius,y+args.centroid_radius),fill=(0,0,0) if args.black_stops and stop_mask[k] else speed_color(speed_mm[k]),outline='white',width=2)
  for mark in slip_marks:
   if k>=mark['peakIndex']:
    mx=mark['sourceXZeroBased'];my=HEADER+mark['sourceYZeroBased'];radius=mark.get('radiusPixels',4);d.ellipse((mx-radius,my-radius,mx+radius,my+radius),fill='#ff7900',outline='black',width=1)
  if args.slip_markers:d.text((650,32),'Slip peaks | score-scaled size (compressed)' if args.slip_size_compressed else ('Slip peaks | area = event score' if args.slip_magnitude_size else 'Orange dots: detected slip peaks'),font=font,fill='#ff9a40')
  enc.stdin.write(im.tobytes())
  if k in checks:im.save(O/f'preview_frame{k+1}.png');samples[str(k+1)]=hashlib.sha256(raw).hexdigest()
 assert not src.stdout.read(1);src.stdout.close();assert src.wait()==0;enc.stdin.close();assert enc.wait()==0
except BaseException:
 src.kill();enc.kill();src.wait();enc.wait();raise
probe=json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe','-v','error','-count_frames','-show_streams','-of','json',str(out)]))['streams'][0];assert int(probe['nb_read_frames'])==n and probe['r_frame_rate']==f'{args.playback_fps}/1';subprocess.run([FF,'-v','error','-i',str(out),'-f','null','-'],check=True)
report=dict(movie=name,frames=n,fps=args.playback_fps,trailWidthPixels=args.trail_width,speedColoredTrail=args.speed_trail,slipSizeMapping='radius=4+8*(score/maxScore)^0.25' if args.slip_size_compressed else 'area proportional to score' if args.slip_magnitude_size else 'fixed radius',slipMarkers=slip_marks,width=w,height=H,sourceFrameRange=[first,last],columnDisplayMaximum=maximum,motionDisplayTransform=args.motion_transform,motionSpatialGaussianSigmaPixels=args.motion_smooth_sigma,stage=stage,speedAdjustmentValidation=scale_report,maximumDisplayDepthPixels=amplitude,display='Weighted columns, '+stage+'; fixed finite whole-trial max; no per-frame rescaling; destination mouse-column probability>0',centroidPalette=args.centroid_palette,blackDuringSavedStops=args.black_stops,stoppingFrames=int(stop_mask.sum()) if args.centroid_speed else None,centroidRadiusPixels=args.centroid_radius,centroidSpeedColor=args.centroid_speed,speedColorRangeMMPerSecond=[0,args.speed_color_max] if args.centroid_speed else None,speedCalibrationMMPerPixel=700/1201,centroidTrail=args.centroid_trail,centroidTrailSeconds=.3 if args.centroid_trail and args.trail_length_pixels is None else None,centroidTrailLengthPixels=args.trail_length_pixels,sampleSourceSHA256=samples,movieSHA256=hashlib.sha256(out.read_bytes()).hexdigest())
(O/'movie_validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
