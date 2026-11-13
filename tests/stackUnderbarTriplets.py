"""Rearrange existing paired movies as SED/WALK/RUN rows and D0/D14 columns."""
from pathlib import Path
import json,subprocess,hashlib
B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_D0_slip_example_review_20261112/group_presentations')
O=B/'three_rows_two_days';O.mkdir(exist_ok=False)
FF='/opt/homebrew/bin/ffmpeg';FP='/opt/homebrew/bin/ffprobe'
records=[]
for tag,folder in [('existing_examples','log1p_smoothed_existing_pairs'),('change_examples','log1p_smoothed_change_pairs')]:
 p=B/folder;manifest=json.loads((p/'manifest.json').read_text())
 rows=[next(r for r in manifest if r['group']==g) for g in ['sedentary','walk','run']]
 n=max(max(r['frames']) for r in rows)
 cmd=[FF,'-v','error','-n','-filter_complex_threads','2']
 for r in rows:cmd+=['-i',str(p/r['output'])]
 cmd+=['-i',str(p/'legend.png')]
 filters=[]
 for i,r in enumerate(rows):
  hold=(n-max(r['frames']))/60
  filters += [f'[{i}:v]setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration={hold},split=2[a{i}][b{i}]',
              f'[a{i}]crop=1280:388:0:0[l{i}]',f'[b{i}]crop=1280:388:0:388[r{i}]',
              f'[l{i}][r{i}]hstack=inputs=2[row{i}]']
 filters+=['[row0][row1][row2]vstack=inputs=3,pad=2560:1224:0:0:black[grid]',
           '[grid][3:v]overlay=640:1164:eof_action=repeat[v]']
 out=O/(tag+'_SED_WALK_RUN_D0_D14_log_smoothed_60fps.mp4')
 subprocess.run(cmd+['-filter_complex',';'.join(filters),'-map','[v]','-frames:v',str(n),'-r','60','-an','-c:v','libx264','-threads','4','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',str(out)],check=True)
 probe=json.loads(subprocess.check_output([FP,'-v','error','-count_frames','-show_streams','-of','json',str(out)]))['streams'][0]
 assert (probe['width'],probe['height'],probe['r_frame_rate'],int(probe['nb_read_frames']))==(2560,1224,'60/1',n)
 subprocess.run([FF,'-v','error','-i',str(out),'-f','null','-'],check=True)
 subprocess.run([FF,'-v','error','-i',str(out),'-vf','select=eq(n\\,300)','-frames:v','1',str(O/(tag+'_preview.png'))],check=True)
 records.append(dict(output=out.name,inputs=rows,frames=n,fps=60,width=2560,height=1224,layout='rows SED/WALK/RUN; columns D0/D14',scaling='no pixel resizing, no trace rescaling; existing per-mouse motion scale preserved',shortPanels='hold last frame',sha256=hashlib.sha256(out.read_bytes()).hexdigest()))
 print('Verified',out,flush=True)
(O/'manifest.json').write_text(json.dumps(records,indent=2))
