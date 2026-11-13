"""Validated tail crops with persistent peak markers, paired and 3x2 movies."""
from pathlib import Path
import csv,json,hashlib,subprocess,argparse
import numpy as np
from PIL import Image,ImageDraw,ImageFont
parser=argparse.ArgumentParser();parser.add_argument("--align-tail-background",action="store_true");parser.add_argument("--bar-bottom-large-marker-minimal",action="store_true");parser.add_argument("--bar-top-rectangle-colorbar",action="store_true",help="Display-only bar-top below-trace baseline, colored height rectangle and motion colorbar");parser.add_argument("--color-limits",type=float,nargs=2);parser.add_argument("--scale-manifest",type=Path);parser.add_argument("--motion-csv",type=Path);parser.add_argument("--boundary-overlay",action="store_true");parser.add_argument("--height-trail",action="store_true");parser.add_argument("--trail-direction",choices=["left","right"],default="right");parser.add_argument('--display-smooth-columns',type=int,default=1);parser.add_argument('--score-markers',action='store_true');parser.add_argument('--log-below',action='store_true');parser.add_argument('--horizontal',action='store_true');parser.add_argument('--height-max-mm',type=float,default=None);parser.add_argument('--output-name',default=None);parser.add_argument('--event-table',type=Path);parser.add_argument('--green-gain',type=float,default=1);parser.add_argument('--base',type=Path,default=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_D14_examples_marked_20261112'));args=parser.parse_args()
assert args.display_smooth_columns>=1 and args.display_smooth_columns%2==1
B=args.base
FF='/opt/homebrew/bin/ffmpeg';FP='/opt/homebrew/bin/ffprobe'
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',18)
read=lambda p:list(csv.DictReader(p.open()))
trials=[]
for group in ['sedentary','walk','run']:
 for day in ['D0','D14']:
  p=B/(group+'_'+day);work=p/'marked_inputs';m=json.loads((work/'metadata.json').read_text())
  assert json.loads((p/'preparation_status.json').read_text())['status']=='complete'
  q,a,b=[np.loadtxt(work/f,delimiter=',') for f in ['rows.csv','above.csv','below.csv']]
  n,w=m['nFrames'],m['width'];h=m['height'];assert q.shape==(n,h) and a.shape==b.shape==(n,w)
  mapping=read(p/'frame_mapping.csv');masks=read(work/'masks_height.csv')
  assert len(mapping)==n and [int(r['OriginalFrame']) for r in mapping]==m['originalFrames']
  valid=~np.array(m['invalid'],bool)&np.isfinite(q).all(1)&np.isfinite(a).all(1)&np.isfinite(b).all(1)&(q>=0).all(1)&(a>=0).all(1)&(b>=0).all(1)&(q.sum(1)>0)
  med=np.full(n,np.nan);med[valid]=(m['barTop']-1-np.argmax(np.cumsum(q[valid],axis=1)>=q[valid].sum(1)[:,None]/2,axis=1))*m['mmPerPixel']
  smooth=np.full(n,np.nan)
  for k in np.flatnonzero(valid):
   lo=k;hi=k+1
   while lo>max(0,k-2) and valid[lo-1]:lo-=1
   while hi<min(n,k+3) and valid[hi]:hi+=1
   smooth[k]=med[lo:hi].mean()
  ref=np.array([float(r['MotionHeightMM']) for r in masks]);joint=np.isfinite(ref)&valid
  assert np.allclose(smooth[joint],ref[joint],atol=1e-8,rtol=1e-8)
  events=read(p/'tail_slip_events.csv')
  prominenceMAD=5
  if args.event_table:
   ee=[e for e in read(args.event_table) if e['File']==m['sourceFilename']]
   events=[dict(e,TraversalFrame=e['TraversalFrame'],OriginalFrame=e['OriginalFrame'],HeightMM=e['HeightMM'],RawAmplitude=e['RawAmplitude'],ProminenceMAD=e['ProminenceMAD']) for e in ee]
   prominenceMAD=float(read(args.event_table)[0]['ThresholdMAD'])
  if args.height_max_mm is not None:
   assert args.event_table or m['peakProminenceThreshold']==5*m['peakMADScale']
   events=[e for e in events if np.isfinite(float(e['HeightMM'])) and float(e['HeightMM'])<=args.height_max_mm]
  m['peakCount']=len(events)
  for e in events:
   k=int(e['TraversalFrame'])-1;assert int(e['OriginalFrame'])==m['originalFrames'][k] and valid[k] and float(masks[k]['PeakJointValid'])==1
  trials.append(dict(p=p,m=m,q=q,a=a,b=b,valid=valid,med=med,smooth=smooth,mapping=mapping,events=events,prominenceMAD=prominenceMAD,start=int(np.flatnonzero(valid)[0]),rowmax=float(q[valid].max())))
# Optional new visual representation. Source measurements and events are untouched.
if args.height_trail:
 from tailMovieDisplay import prepare,color
 motionfile=args.motion_csv or Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_no_vertical_weight_20261113/per_crop_pixel/locomotion_movie_traces/stops_excluded/six_whole_traces.csv')
 motionrows=read(motionfile)
 for t in trials:
  rows=[r for r in motionrows if r['File']==t['m']['sourceFilename']]
  assert [int(r['OriginalFrame']) for r in rows]==t['m']['originalFrames']
  keep=np.array([int(r['KeepLocomotion']) for r in rows],bool)&t['valid']
  activity=np.array([float(r['UnscaledWholeMotionPerPixelTimes1000']) for r in rows])
  t['activity'],_=prepare(activity,keep,17,0)
  if args.boundary_overlay:t['boundary']=np.loadtxt(t['p']/'boundary_rows.csv',delimiter=',')
  t['heightDisplay'],t['heightFilled']=prepare(t['smooth'],t['valid'],1,4)
  t['bDisplay'],t['filled']=prepare(t['b'],t['valid'],5,4)
  t['qDisplay'],_=prepare(t['q'],t['valid'],5,4)
  t['qDisplay']=np.array([np.convolve(np.pad(row,(2,2),mode='edge'),np.ones(5)/5,mode='valid') for row in t['qDisplay']])
 limits=np.percentile(np.concatenate([t['activity'][np.isfinite(t['activity'])] for t in trials]),[5,95])
 if args.color_limits:limits=np.array(args.color_limits)
 assert limits[1]>limits[0]

# A single marker-area mapping for all selected events, independent of group/day.
marker_max=max((float(e['EventScore']) for t in trials for e in t['events']),default=0) if args.score_markers else None
if args.score_markers:
 assert marker_max is not None and marker_max>0
 assert all(np.isfinite(float(e['EventScore'])) and float(e['EventScore'])>=0 for t in trials for e in t['events'])
def marker_radius(e):
 return float(np.sqrt(4**2+(12**2-4**2)*float(e['EventScore'])/marker_max)) if args.score_markers else 5.0
# Pairwise raw green/red maximum is computed before trimming. No MAD/log/smoothing.
for t in trials:
 t['max']=max(float(v[k][v['valid']].max()) for v in trials if v['m']['group']==t['m']['group'] for k in ['a','b'])
if args.scale_manifest:
 reference=json.loads(args.scale_manifest.read_text())
 for t in trials:t['max']=next(r['columnMaximum'] for r in reference if r['file']==t['m']['sourceFilename'])
scale=2;PW=max(t['m']['width']*scale for t in trials);PW+=PW%2
above=max((t['m']['barTop']-1)*scale for t in trials);under=max((t['m']['height']-t['m']['barTop']+1)*scale for t in trials)
PH=int(above+under+36);PH+=PH%2
O=B/(args.output_name or ('presentations_log_below_horizontal' if args.horizontal and args.log_below else 'presentations_log_below' if args.log_below else 'presentations'));O.mkdir(exist_ok=False)
def fraction(v,maximum,below=False):
 return np.log1p(v)/np.log1p(maximum) if below and args.log_below else v/maximum
def display_fraction(v,maximum,below=False):
 values=fraction(v,maximum,below)
 window=args.display_smooth_columns
 if window>1:values=np.convolve(np.pad(values,(window//2,window//2),mode='edge'),np.ones(window)/window,mode='valid')
 return values
def verify(path,n,width,height):
 s=json.loads(subprocess.check_output([FP,'-v','error','-count_frames','-show_streams','-of','json',str(path)]))['streams'][0]
 assert (int(s['nb_read_frames']),s['r_frame_rate'],s['width'],s['height'])==(n,'30/1',width,height)
 subprocess.run([FF,'-v','error','-i',str(path),'-f','null','-'],check=True)
for t in trials:
 m=t['m'];n=m['nFrames'];w=m['width'];h=m['height'];W=w*2;H=h*2;bar=(m['barTop']-1)*2;bottom=bar+m['barWidth']*2
 xpad=(PW-W)//2;ypad=int(36+above-bar)
 belowBase=bar if args.bar_top_rectangle_colorbar else bottom
 t['tailBackgroundOffsetPixels']=0.0
 if args.align_tail_background:
  assert args.height_trail
  # Fixed trial offset: median displayed motion in distal/rightmost crop quarter.
  background=np.array([display_fraction(row,t['max'],True)[3*w//4:] for row in t['bDisplay'][t['valid']]])
  usable=background[np.isfinite(background)&(background>0)]
  assert len(usable)>0
  t['tailBackgroundOffsetPixels']=float(150*np.median(usable))
  belowBase-=t['tailBackgroundOffsetPixels']
 marks=[]
 sourcecols=np.loadtxt(t['p']/'source_columns_frame_by_column.csv',delimiter=',')
 for e in t['events']:
  k=int(e['TraversalFrame'])-1;x=int(np.argmax(t['b'][k]));y=belowBase+150*fraction(t['b'][k,x],t['max'],True)
  marks.append(dict(**e,peakIndex=k,cropColumnZeroBased=x,sourceColumnOneBased=float(sourcecols[k,x]),displayX=xpad+x*2,displayY=ypad+y,displayRadius=marker_radius(e)))
 (O/(m['group']+'_'+m['day']+'_tail_slip_marker_positions.json')).write_text(json.dumps(marks,indent=2))
 out=O/(m['mouse']+'_'+m['group']+'_'+m['day']+'_tail_slips.mp4');t['movie']=out;t['frames']=n-t['start']
 dec=subprocess.Popen([FF,'-v','error','-i',str(t['p']/'post_mouse_crop_lossless.mkv'),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
 enc=subprocess.Popen([FF,'-v','error','-n','-f','rawvideo','-pix_fmt','rgb24','-s',f'{PW}x{PH}','-r','30','-i','-','-an','-c:v','libx264','-threads','3','-crf','17','-pix_fmt','yuv420p',str(out)],stdin=subprocess.PIPE)
 frame_rows=[]
 for k in range(n):
  buf=bytearray()
  while len(buf)<w*h:
   chunk=dec.stdout.read(w*h-len(buf))
   if not chunk:raise RuntimeError('short crop')
   buf.extend(chunk)
  assert hashlib.sha256(buf).hexdigest()==t['mapping'][k]['LosslessGrayFrameSHA256']
  frame_rows.append([k+1,m['originalFrames'][k],max(0,k-t['start']+1),int(not t['valid'][k])])
  if k<t['start']:continue
  im=Image.new('RGB',(PW,PH),'black');crop=Image.frombytes('L',(w,h),bytes(buf)).resize((W,H),Image.Resampling.NEAREST).convert('RGB');im.paste(crop,(xpad,ypad));d=ImageDraw.Draw(im)
  d.text((10,8),f"{m['mouse']} | {m['group']} | {m['day']}",fill='white',font=font)
  if t['valid'][k] or (args.height_trail and t['filled'][k]):
   for vector,col,base,direction in ([(t['bDisplay'][k],'#923eaa',belowBase,1)] if args.height_trail else [(t['a'][k],'#009b46',bar,-1),(t['b'][k],'#d2282d',bottom,1)]):
    d.line([(xpad+x*2,ypad+base+direction*150*(args.green_gain if direction==-1 else 1)*v) for x,v in enumerate(display_fraction(vector,t['max'],direction==1))],fill=col,width=3)
   d.line([(xpad+W-1-180*v/t['rowmax'],ypad+r*2) for r,v in enumerate(t['qDisplay'][k] if args.height_trail else t['q'][k])],fill=('black' if args.height_trail else '#a023be'),width=3)
   if not (args.height_trail and (args.bar_top_rectangle_colorbar or args.bar_bottom_large_marker_minimal)):
    yy=ypad+bar-2*(t['heightDisplay'][k] if args.height_trail else t['smooth'][k])/m['mmPerPixel'];d.line([(xpad+W/2-15,yy),(xpad+W/2+15,yy)],fill='white',width=7);d.line([(xpad+W/2-15,yy),(xpad+W/2+15,yy)],fill='black',width=3)
  if not t['valid'][k]:
   x=xpad+W-25;y=ypad+10;d.line([(x,y),(x+15,y+15)],fill='#d2282d',width=3);d.line([(x+15,y),(x,y+15)],fill='#d2282d',width=3)
  if args.height_trail and args.boundary_overlay and np.isfinite(t['boundary'][k]):
   yy=ypad+2*(t['boundary'][k]-1)
   for xx in range(xpad,xpad+W,16):d.line([(xx,yy),(min(xx+8,xpad+W),yy)],fill='#00b5c8',width=2)
  if args.height_trail:
   # 0.5 acquisition seconds (80 frames at 160 Hz); current point stays fixed.
   for j in range(max(t['start']+1,k-79),k+1):
    if not np.isfinite(t['heightDisplay'][j-1:j+1]).all():continue
    direction=1 if args.trail_direction=="right" else -1
    x1=xpad+W/2+direction*120*(k-j+1)/80;x2=xpad+W/2+direction*120*(k-j)/80
    y1=ypad+bar-2*t['heightDisplay'][j-1]/m['mmPerPixel'];y2=ypad+bar-2*t['heightDisplay'][j]/m['mmPerPixel']
    if (t['heightFilled'][j] or t['heightFilled'][j-1]) and j%2:continue
    d.line([(x1,y1),(x2,y2)],fill=color(t['activity'][j],limits),width=4)
   if np.isfinite(t['heightDisplay'][k]):
    yy=ypad+bar-2*t['heightDisplay'][k]/m['mmPerPixel'];xx=xpad+W/2
    if args.bar_bottom_large_marker_minimal:d.rectangle((xx-20,yy-6,xx+20,yy+6),fill=color(t['activity'][k],limits),outline='white',width=2)
    elif args.bar_top_rectangle_colorbar:d.rectangle((xx-15,yy-4,xx+15,yy+4),fill=color(t['activity'][k],limits),outline='white',width=2)
    else:d.ellipse((xx-5,yy-5,xx+5,yy+5),fill=color(t['activity'][k],limits),outline='white',width=1)
  for mark in marks:
   if mark['peakIndex']<=k:
    x,y=mark['displayX'],mark['displayY'];r=mark['displayRadius'];d.ellipse((x-r,y-r,x+r,y+r),fill=('#923eaa' if args.height_trail else '#ff8500'),outline='black',width=1)
  enc.stdin.write(im.tobytes())
 assert not dec.stdout.read(1);dec.stdout.close();assert dec.wait()==0;enc.stdin.close();assert enc.wait()==0
 verify(out,t['frames'],PW,PH)
 with (O/(m['group']+'_'+m['day']+'_frame_mapping.csv')).open('w') as f:
  wr=csv.writer(f);wr.writerow(['TraversalFrame','OriginalFrame','PresentationFrameZeroIfTrimmed','InvalidOrUnusable'])
  wr.writerows(r[:4] for r in frame_rows)
 print('Verified',out,flush=True)
# Footer shared once, calibrated in display pixels (all panels unresized).
footer=Image.new('RGB',(PW*2,100),'black');d=ImageDraw.Draw(footer)
for i,(label,col) in enumerate([('Above-bar','#009b46'),('Below-bar','#d2282d'),('Height profile','#a023be')]):
 x=10+i*int(PW*2/3);d.line([(x,18),(x+22,18)],fill=col,width=3);d.text((x+28,7),label,fill='white',font=font)
d.text((10,37),('Orange size: event score | Black: height | X: invalid' if args.score_markers else 'Black: motion height | Orange: detected tail slips | X: invalid'),fill='white',font=font)
d.text((10,70),f'Red: log1p | Green: linear x{args.green_gain:g} | Per-mouse scale'+(f' | Display: {args.display_smooth_columns}col mean' if args.display_smooth_columns>1 else '') if args.log_below else 'Raw traces; shared scale within mouse',fill='white',font=font)
sx=PW*2-130;d.line([(sx,82),(sx+40/(700/1201),82)],fill='white',width=4);d.text((sx,54),'20 mm',fill='white',font=font)
if args.height_trail:
 footer=Image.new('RGB',(PW*2,100),'black');d=ImageDraw.Draw(footer)
 d.text((10,3),'Purple: below-bar motion / swing score | Black: row profile',fill='white',font=font)
 d.text((10,27),'Height trail: whole motion (black to red); gray: stops',fill='white',font=font)
 if args.bar_top_rectangle_colorbar:
  for cx in range(201):d.line([(10+cx,52),(10+cx,64)],fill=color(limits[0]+cx/200*(limits[1]-limits[0]),limits),width=1)
  d.rectangle((9,51,211,65),outline='white',width=1)
  d.text((225,48),f'{limits[0]:.2f} (black) to {limits[1]:.2f} (red) x0.001 a.u./pixel',fill='white',font=font)
 else:
  d.text((10,51),f'Color {limits[0]:.2f} to {limits[1]:.2f} (x0.001 a.u./pixel)',fill='white',font=font)
 d.text((10,75),'X: invalid | Short display gaps interpolated',fill='white',font=font)
 sx=PW*2-125;d.line([(sx,82),(sx+40/(700/1201),82)],fill='white',width=4);d.text((sx,54),'20 mm',fill='white',font=font)
 if args.bar_bottom_large_marker_minimal:
  footer=Image.new('RGB',(PW*2,100),'black');d=ImageDraw.Draw(footer)
  d.text((10,8),'Tail motion (0.001 a.u./pixel)',fill='white',font=font)
  for cx in range(301):d.line([(10+cx,40),(10+cx,56)],fill=color(limits[0]+cx/300*(limits[1]-limits[0]),limits),width=1)
  d.rectangle((9,39,311,57),outline='white',width=1)
  d.text((10,65),f'{limits[0]:.2f}',fill='white',font=font);d.text((275,65),f'{limits[1]:.2f}',fill='white',font=font)
  sx=PW*2-125;d.line([(sx,56),(sx+40/(700/1201),56)],fill='white',width=4);d.text((sx,28),'20 mm',fill='white',font=font)
 (O/'display_settings.json').write_text(json.dumps(dict(colorLimits=limits.tolist(),belowBaseline=('bar_top' if args.bar_top_rectangle_colorbar else 'bar_bottom'),minimalLegend=args.bar_bottom_large_marker_minimal,heightMarker=('40x12px rectangle, white2px outline' if args.bar_bottom_large_marker_minimal else '30x8px rectangle, white2px outline' if args.bar_top_rectangle_colorbar else 'circle with short line'),colorbar=(args.bar_top_rectangle_colorbar or args.bar_bottom_large_marker_minimal),colorUnits='0.001 a.u./pixel',activitySmoothingFrames=17,columnTemporalSmoothingFrames=5,columnSpatialSmoothing=5,rowTemporalSmoothing=5,rowSpatialSmoothing=5,heightSmoothingFrames=5,maximumDisplayGapFrames=4,trailAcquisitionSeconds=.5,trailDirection=args.trail_direction,probabilityRule='existing minwidth15 inputs; body-connected exclusion preserved',greenHidden=True,profileColor='black',belowAndMarkersColor='purple',eventDetectionUnchanged=True),indent=2))
 for t in trials:
  with (O/(t['m']['group']+'_'+t['m']['day']+'_display_values.csv')).open('w') as f:
   wr=csv.writer(f);wr.writerow(['OriginalFrame','OriginalInvalid','DisplayGapFilled','HeightMM','SmoothedWholeMotionTimes1000'])
   wr.writerows(zip(t['m']['originalFrames'],(~t['valid']).astype(int),t['filled'].astype(int),t['heightDisplay'],t['activity']))
footer.save(O/'legend.png')
def combine(ts,name,layout):
 n=max(t['frames'] for t in ts);cmd=[FF,'-v','error','-n','-filter_complex_threads','2'];filters=[]
 for i,t in enumerate(ts):
  cmd+=['-i',str(t['movie'])];filters.append(f"[{i}:v]setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration={(n-t['frames'])/30}[p{i}]")
 cmd+=['-i',str(O/'legend.png')]
 width=PW*2
 if len(ts)==2:filters.append('[p0][p1]hstack=inputs=2[grid]');height=PH+100
 elif layout=='horizontal':
  gap=32;width=PW*6+gap*2;height=PH+100
  positions=[f'{i*PW+(i//2)*gap}_0' for i in range(6)]
  filters.append(''.join(f'[p{i}]' for i in range(6))+'xstack=inputs=6:layout='+'|'.join(positions)+':fill=black[grid]')
 else:
  for i in range(3):filters.append(f'[p{2*i}][p{2*i+1}]hstack=inputs=2[r{i}]')
  filters.append('[r0][r1][r2]vstack=inputs=3[grid]');height=PH*3+100
 filters.append(f'[grid]pad={width}:{height}:0:0:black[pad]');filters.append(f'[pad][{len(ts)}:v]overlay={(width-PW*2)//2}:{height-100}:eof_action=repeat[v]')
 out=O/name
 subprocess.run(cmd+['-filter_complex',';'.join(filters),'-map','[v]','-frames:v',str(n),'-r','30','-an','-c:v','libx264','-threads','3','-crf','17','-pix_fmt','yuv420p',str(out)],check=True);verify(out,n,width,height)
 subprocess.run([FF,'-v','error','-i',str(out),'-vf','select=eq(n\\,250)','-frames:v','1',str(out.with_suffix('.png'))],check=True)
 print('Verified composite',out,flush=True)
for g in ['sedentary','walk','run']:combine([t for t in trials if t['m']['group']==g],g+'_D0_D14_tail_slips.mp4','pair')
combine(trials,'SED_WALK_RUN_D0_D14_tail_slips.mp4','horizontal' if args.horizontal else 'grid')
manifest=[dict(file=t['m']['sourceFilename'],movie=t['movie'].name,frames=t['frames'],firstTraversalFrame=t['start']+1,firstOriginalFrame=t['m']['originalFrames'][t['start']],lastOriginalFrame=t['m']['originalFrames'][-1],validFrames=int(t['valid'].sum()),peakCount=t['m']['peakCount'],detector=('normalized_amplitude_morphology5' if args.event_table and 'normalized_movie_events' in args.event_table.name else 'peak_prominence'),displaySmoothingColumns=args.display_smooth_columns,displaySmoothingDomain=('temporal5 raw; spatial5 after log mapping; black row profile temporal5/spatial5' if args.height_trail else 'after linear/log1p mapping; edge-repeat; green/red only'),thresholdMAD=t['prominenceMAD'],markerScale=('area_offset_linear_score' if args.score_markers else 'fixed'),markerScoreMaximum=marker_max,markerRadiusMinimum=(4 if args.score_markers else 5),markerRadiusMaximum=(12 if args.score_markers else 5),greenDisplayGain=args.green_gain,heightMaximumMM=args.height_max_mm,tailBackgroundOffsetPixels=t['tailBackgroundOffsetPixels'],tailBackgroundReference=('fixed median of positive finite displayed contributions in rightmost25percent crop columns, all valid full-trial frames' if args.align_tail_background else None),columnMaximum=t['max'],rowMaximum=t['rowmax'],panelWidth=PW,panelHeight=PH,belowDisplay='log1p' if args.log_below else 'linear',aboveDisplay=('hidden' if args.height_trail else 'linear'),layout='horizontal' if args.horizontal else 'grid') for t in trials]
(O/'manifest.json').write_text(json.dumps(manifest,indent=2))
