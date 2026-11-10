from pathlib import Path
import json,csv,subprocess
import numpy as np
from PIL import Image,ImageDraw
SRC=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109')
OUT=SRC.parent/'balance_beam_runner_column_scale_review_20261109';OUT.mkdir(exist_ok=True)
for day,trial in [(7,2),(14,1)]:
 p=SRC/f'run_D{day:02d}_trial{trial}';m=json.loads((p/'render_inputs/metadata.json').read_text())
 rows=list(csv.DictReader((p/'render_inputs/motion_height.csv').open()));valid=np.array([r['InvalidOrUnusable']=='0' for r in rows]);a=np.loadtxt(p/'render_inputs/above.csv',delimiter=',');b=np.loadtxt(p/'render_inputs/below.csv',delimiter=',')
 mx=max(a[valid].max(),b[valid].max());print('DAY',day,'max',repr(mx),'above',a[valid].max(),'below',b[valid].max(),'pixels/raw',150/mx,flush=True)
 ks=np.linspace(np.flatnonzero(valid)[0]+30,len(rows)-30,8).astype(int)
 d=subprocess.Popen(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(p/'post_mouse_crop_lossless.mkv'),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
 canvas=Image.new('RGB',(4*m['width'],2*(m['height']+25)),'white');draw=ImageDraw.Draw(canvas)
 for k in range(len(rows)):
  raw=d.stdout.read(m['width']*m['height'])
  if k in ks:
   im=Image.frombytes('L',(m['width'],m['height']),raw).convert('RGB');im.save(OUT/f'D{day}_f{rows[k]["OriginalFrame"]}.png')
   j=list(ks).index(k);x=(j%4)*m['width'];y=(j//4)*(m['height']+25);canvas.paste(im,(x,y+25));draw.text((x+3,y+4),f'D{day} f{rows[k]["OriginalFrame"]}',fill='black')
   draw.line((x,y+25+m['barTop']-1,x+m['width']-1,y+25+m['barTop']-1),fill='red')
 assert d.wait()==0
 canvas.save(OUT/f'D{day}_contact.png')
summary=[];stats=[]
for day,trial,frames in [(7,2,[1558,1787,2017]),(14,1,[921,1151,1209])]:
 p=SRC/f'run_D{day:02d}_trial{trial}';m=json.loads((p/'render_inputs/metadata.json').read_text());rows=list(csv.DictReader((p/'render_inputs/motion_height.csv').open()))
 valid=np.array([r['InvalidOrUnusable']=='0' for r in rows]);a=np.loadtxt(p/'render_inputs/above.csv',delimiter=',');b=np.loadtxt(p/'render_inputs/below.csv',delimiter=',');mx=max(a[valid].max(),b[valid].max())
 for name,arr in [('above',a),('below',b)]:
  masked=np.where(valid[:,None],arr,-np.inf);k,x=np.unravel_index(np.argmax(masked),masked.shape)
  summary.append(dict(day=day,trace=name,maximum=float(masked[k,x]),originalFrame=rows[k]['OriginalFrame'],cropColumnOneBased=int(x+1),sharedMaximum=float(mx),displayPixelsPerRawUnit=150/mx))
 wanted={i for i,r in enumerate(rows) if int(r['OriginalFrame']) in frames};d=subprocess.Popen(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(p/'post_mouse_crop_lossless.mkv'),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE);prev=None
 for k in range(len(rows)):
  raw=d.stdout.read(m['width']*m['height'])
  if k in wanted:
   canvas=Image.new('RGB',(m['width']*2,m['height']+25),'white');draw=ImageDraw.Draw(canvas)
   for j,v in enumerate([prev,raw]):
    canvas.paste(Image.frombytes('L',(m['width'],m['height']),v),(j*m['width'],25))
    draw.text((j*m['width']+2,3),f'D{day} original {int(rows[k]["OriginalFrame"])-1+j}',fill='black')
    draw.rectangle((j*m['width']+159,25+m['barTop']-1+m['barWidth'],j*m['width']+199,25+m['height']-1),outline='cyan')
   canvas.save(OUT/f'D{day}_pair_f{rows[k]["OriginalFrame"]}.png')
   vals=b[k,159:200]
   entry=dict(day=day,originalFrame=int(rows[k]['OriginalFrame']),valid=bool(valid[k]),columnFirst=160,columnLast=200,rawMedian=float(np.median(vals)),rawP95=float(np.percentile(vals,95)),rawMax=float(vals.max()),rawMin=float(vals.min()))
   for key in ['Median','P95','Max','Min']:entry['displayPixels'+key]=entry['raw'+key]*150/mx
   stats.append(entry)
  prev=raw
 assert d.wait()==0
(OUT/'maxima.json').write_text(json.dumps(summary,indent=2));(OUT/'sample_stats.json').write_text(json.dumps(stats,indent=2))
with (OUT/'sample_stats.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(stats[0]));w.writeheader();w.writerows(stats)
print(json.dumps(summary,indent=2));print(json.dumps(stats,indent=2))
