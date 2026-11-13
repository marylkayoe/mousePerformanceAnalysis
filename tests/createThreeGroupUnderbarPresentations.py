"""Three illustrative D0/D14 pairs, common scales across all six crossings."""
from pathlib import Path
import csv,json,subprocess,sys,argparse
import numpy as np
from PIL import Image,ImageDraw,ImageFont
parser=argparse.ArgumentParser();parser.add_argument('--motion-scale',choices=['all','mouse'],default='all');parser.add_argument('--motion-transform',choices=['linear','log1p'],default='linear');parser.add_argument('--group',choices=['all','sedentary','walk','run'],default='all');parser.add_argument('--motion-smooth-sigma',type=float,default=0);parser.add_argument('--selection',type=Path);parser.add_argument('--shared-slip-score-max',type=float);parser.add_argument('--output',type=Path);args=parser.parse_args()
R=Path(__file__).resolve().parents[1];B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_D0_slip_example_review_20261112');O=B/'group_presentations';sel=json.loads((R/'BEAMCROSS/DRAFTFIGS/slip-movie-example-review/selected_group_movies.json').read_text());pairs={g:[O/(g+'_'+day+'_inputs') for day in ['D0','D14']] for g in ['sedentary','run']};pairs['walk']=[B/'S20_underbar_centroid',B/'S20_D14_T2_underbar'];events=list(csv.DictReader((R/'BEAMCROSS/DRAFTFIGS/analysis-data/events.csv').open()));maxima=[];scores=[];group_maxima={};original_output=O
if args.selection:
 selection=json.loads(args.selection.read_text());pairs={g:[Path(next(r['inputFolder'] for r in selection if r['group']==g and r['day']==day)) for day in ['D0','D14']] for g in ['sedentary','walk','run']}
for group,folders in pairs.items():
 group_maxima[group]=[]
 for folder in folders:
  m=json.loads((folder/'metadata.json').read_text());rows=list(csv.DictReader((folder/'frame_mapping.csv').open()));tr=list(csv.DictReader((Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials')/(m['file']+'.trace.csv')).open()));raw=np.loadtxt(folder/'raw_columns.csv',delimiter=',');logs=np.log1p([float(r['ForwardSpeed']) for r in tr]);logs[logs<0]=np.finfo(float).eps
  with np.errstate(invalid='ignore',divide='ignore'): a=raw*(160/logs)[:,None]
  valid=np.isfinite(a).all(axis=1);valid[0]=False;maxima.append(float(a[valid].max()));group_maxima[group].append(maxima[-1])
  for e in events:
   if e['File']==m['file'] and e['Type']=='slip':scores.append(sum(max(float(r['SavedMovementTrace'])-2.5,0) for r in rows[int(e['StartTraversalFrame'])-1:int(e['EndTraversalFrame'])]))
cm=max(maxima);sm=args.shared_slip_score_max if args.shared_slip_score_max is not None else max(scores);print('Shared scales',cm,sm,flush=True)
if args.output:
 O=args.output;O.mkdir(exist_ok=False)
elif args.motion_transform!='linear':
 O=O/(args.group+'_'+args.motion_scale+'_log1p_motion_scale');O.mkdir(exist_ok=False)
elif args.motion_scale=='mouse':O=O/'per_mouse_motion_scale';O.mkdir(exist_ok=False)
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16);footer=Image.new('RGB',(1280,60),'black');d=ImageDraw.Draw(footer);d.text((10,9),'Centroid / trail speed (mm/s)',font=font,fill='white');d.text((226,9),'0',font=font,fill='white')
for x in range(180):d.line([(245+x,10),(245+x,24)],fill=(min(255,round(510*x/179)),max(0,round(480*(x/179-.5))),0))
d.text((435,9),'300 | Stops: black',font=font,fill='white');d.ellipse((663,11,675,23),fill='#ff7900');d.text((685,9),'Detected slips | size: event score (compressed)',font=font,fill='#ff9a40');d.line([(10,45),(42,45)],fill='#ed681a',width=2);d.text((52,35),'Under-bar motion: analysis weighting + speed adjustment | scale shared within mouse' if args.motion_scale=='mouse' else 'Under-bar motion: analysis weighting and speed adjustment',font=font,fill='white');
if args.motion_transform=='log1p':
 d.rectangle((0,30,1279,59),fill='black');d.text((10,35),'Under-bar motion: log1p display | analysis weighting + speed adjustment | scale shared within mouse',font=font,fill='white')
if args.motion_smooth_sigma:
 d.rectangle((0,30,1279,59),fill='black');d.text((10,35),f'Under-bar motion: log1p display | spatial smoothing {args.motion_smooth_sigma:g} px | scale shared within mouse',font=font,fill='white')
footer.save(O/'legend.png')
manifest=[]
for group,folders in pairs.items():
 if args.group!='all' and group!=args.group:continue
 cm=max(group_maxima[group]) if args.motion_scale=='mouse' else max(maxima)
 movies=[];counts=[];titles=[];names=[]
 for day,folder in zip(['D0','D14'],folders):
  m=json.loads((folder/'metadata.json').read_text());names.append(m['file']);mouse='_'.join(m['file'].split('_')[:2]);counts.append(m['nFrames']);out=O/(group+'_'+day+'_render_v2');assert not out.exists()
  reuse=original_output/(group+'_'+day+'_render_v2')
  can_reuse=not args.motion_smooth_sigma and args.motion_transform=='linear' and args.motion_scale=='mouse' and (reuse/'movie_validation.json').exists() and json.loads((reuse/'movie_validation.json').read_text())['columnDisplayMaximum']==cm
  if can_reuse:out=reuse
  else:subprocess.run([sys.executable,str(R/'tests/renderUnderbarMotionMovie.py'),str(folder),'--motion-smooth-sigma',str(args.motion_smooth_sigma),'--motion-transform',args.motion_transform,'--speed-adjusted','--display-depth','120','--centroid-trail','--trail-length-pixels','150','--centroid-speed','--centroid-radius','7','--centroid-palette','black-red-yellow','--black-stops','--speed-trail','--trail-width','6','--slip-markers','--slip-magnitude-size','--slip-size-compressed','--playback-fps','60','--shared-column-max',str(cm),'--shared-slip-score-max',str(sm),'--output',str(out)],check=True,stdout=subprocess.DEVNULL)
  movies.append(next(out.glob('*.mp4')));im=Image.new('RGB',(1280,32),'black');ImageDraw.Draw(im).text((10,6),f'{mouse} | {group} | {day}',font=font,fill='white');path=O/(group+'_'+day+'_title.png');im.save(path);titles.append(path)
 n=max(counts);holds=[(n-c)/60 for c in counts];out=O/f'{mouse}_{group}_D0_D14_underbar_presentation_60fps.mp4'
 filt=f'[0:v]crop=1280:356:0:56,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration={holds[0]},pad=1280:388:0:32:black[a];[1:v]crop=1280:356:0:56,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration={holds[1]},pad=1280:388:0:32:black[b];[a][b]vstack=inputs=2,pad=1280:836:0:0:black[c];[c][2:v]overlay=0:776:eof_action=repeat[d];[d][3:v]overlay=0:0:eof_action=repeat[e];[e][4:v]overlay=0:388:eof_action=repeat[v]'
 cmd=['/opt/homebrew/bin/ffmpeg','-v','error','-n']
 for p in [*movies,O/'legend.png',*titles]:cmd+=['-i',str(p)]
 subprocess.run(cmd+['-filter_complex',filt,'-map','[v]','-frames:v',str(n),'-r','60','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',str(out)],check=True)
 probe=json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe','-v','error','-count_frames','-show_streams','-of','json',str(out)]))['streams'][0];assert int(probe['nb_read_frames'])==n and probe['r_frame_rate']=='60/1';subprocess.run(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(out),'-f','null','-'],check=True);subprocess.run(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(out),'-vf','select=eq(n\\,300)','-frames:v','1',str(O/(group+'_preview.png'))],check=True)
 manifest.append(dict(group=group,mouse=mouse,sourceFiles=names,frames=counts,output=out.name,motionScaleScope=args.motion_scale,motionDisplayTransform=args.motion_transform,motionSpatialGaussianSigmaPixels=args.motion_smooth_sigma,sharedColumnMax=cm,sharedSlipScoreMax=sm,playbackFPS=60));print('Completed',out,flush=True)
(O/'manifest.json').write_text(json.dumps(manifest,indent=2))
