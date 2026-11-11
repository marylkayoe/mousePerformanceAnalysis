"""Editable tail panels matching the supplied Illustrator speed-panel geometry."""
from pathlib import Path
import csv,json,math
from PIL import Image,ImageDraw,ImageFont
from xml.sax.saxutils import escape
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/figMaterials';name='TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4'
read=lambda p:list(csv.DictReader(p.open()))
scorepath=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_whole_tail_reweight_L40_halfdepth_20261110/trials')/(name+'.csv');score=read(scorepath);height=read(out/'TMCS2_S18_D0_T2_tail_median_source.csv');base=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials');trace=read(base/(name+'.trace.csv'));events=read(base/(name+'.events.csv'))
assert len(score)==len(height)==len(trace)==967
rows=[]
for i,(s,h,t) in enumerate(zip(score,height,trace)):
 assert int(s['OriginalFrame'])==int(h['OriginalFrame'])==int(t['OriginalFrame'])==856+i
 assert abs(float(s['EncodedTimeSeconds'])-float(h['TimeSeconds']))<1e-9
 assert int(s['TailBadFrame'])==int(h['TailBadFrame'])
 rows.append(dict(TraversalFrame=i+1,OriginalFrame=856+i,TimeSinceTraversalStartSeconds=i/160,TailMotionScore=float(s['NewWholeNormalized']),MedianMotionHeightMM=float(h['MedianHeightMM']),MedianMotionHeight5FrameMM=float(h['MedianHeight5FrameMM']),TailBadFrame=int(s['TailBadFrame']),InvalidFramePair=int(s['InvalidFramePair']),HeightInvalid=int(h['HeightInvalid']),StopMask=int(t['StopMask'])))
font='/System/Library/Fonts/Supplemental/Arial.ttf';W,H,Z=267.56,112,4;L,RX,T,B=22.1,267.56,13.41,90.12;X=lambda v:L+v/(967/160)*(RX-L)
for key,title,unit,suffix in [('TailMotionScore','Tail-motion score during traverse','a.u.','tail_motion_score'),('MedianMotionHeight5FrameMM','Median motion height during traverse','mm relative to bar','tail_motion_height')]:
 vals=[r[key] for r in rows if math.isfinite(r[key])];lo=math.floor(min(0,min(vals))/5)*5;hi=math.ceil(max(vals)/5)*5
 if key=='TailMotionScore':lo=-4;hi=8
 else:lo=-40;hi=80
 Y=lambda v:B-(v-lo)/(hi-lo)*(B-T)
 svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];im=Image.new('RGB',(round(W*Z),round(H*Z)),'white');d=ImageDraw.Draw(im)
 def text(x,y,s,size=6,anchor='start'):
  svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="#222222">{escape(s)}</text>');f=ImageFont.truetype(font,round(size*Z));w=d.textlength(s,font=f);d.text((x*Z-(w/2 if anchor=='middle' else w if anchor=='end' else 0),(y-size)*Z),s,font=f,fill='#222222')
 def line(x,y,xx,yy,c='#222222',width=.35):
  svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{width}"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(width*Z)))
 text(22.55,8.58,title,8)
 for e in events:
  if e['Type']!='stop':continue
  x=X((int(e['StartTraversalFrame'])-1)/160);xx=X(int(e['EndTraversalFrame'])/160)
  svg.append(f'<rect x="{x}" y="{T}" width="{xx-x}" height="{B-T}" fill="#dbe7f0"/>');d.rectangle((x*Z,T*Z,xx*Z,B*Z),fill='#dbe7f0')
 for v in (range(-4,9,2) if key=='TailMotionScore' else range(-40,81,20)):
  y=Y(v);line(L,y,RX,y,'#e7e7e7');text(L-3,y+2,f'{v:g}',6,'end')
 for t in range(7):
  x=X(t);line(x,B,x,B+1.5);text(x,B+7,str(t),6,'middle')
 line(L,T,L,B);line(L,B,RX,B)
 if lo<0<hi:line(L,Y(0),RX,Y(0),'#999999',.3)
 path=[];seg=[]
 for r in rows:
  v=r[key]
  if math.isfinite(v):
   x,y=X(r['TimeSinceTraversalStartSeconds']),Y(v);path.append(('L' if seg else 'M')+f'{x:.5f},{y:.5f}');seg.append((x*Z,y*Z))
  else:
   if len(seg)>1:d.line(seg,fill='black',width=2)
   seg=[]
 if len(seg)>1:d.line(seg,fill='black',width=2)
 svg.append('<path d="'+' '.join(path)+'" fill="none" stroke="black" stroke-width=".5" stroke-linejoin="round"/>')
 text((L+RX)/2,108,'Time since traversal start (s)',6,'middle')
 svg.append(f'<text transform="translate(6.87 55) rotate(-90)" text-anchor="middle" font-family="Arial" font-size="6">{unit}</text>')
 label=Image.new('RGBA',(260,40));ld=ImageDraw.Draw(label);ld.text((130,20),unit,font=ImageFont.truetype(font,24),fill='black',anchor='mm');label=label.rotate(90,expand=True);im.paste(label,(0,90),label)
 svg.append('</svg>');stem=out/('TMCS2_S18_D0_T2_'+suffix);stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'));print(suffix,'range',min(vals),max(vals),'finite',len(vals))
with (out/'TMCS2_S18_D0_T2_tail_example_traces.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
(out/'TMCS2_S18_D0_T2_tail_example_traces.json').write_text(json.dumps(dict(file=name,originalFrames=[856,1822],frames=967,fps=160,scoreSource=str(scorepath),score='NewWholeNormalized, unchanged; corrected below-bar weights 1 at first below-bar row, 2 at half depth, then plateau; above weights unchanged; no additional smoothing',height='Full probability-weighted row-profile median, no vertical distance ramp, positive above bar; contiguous-valid centered five-frame mean, truncated at invalid gaps and edges; no near-bar blanking',calibrationMMPerPixel=700/1201,validHeightFrames=sum(not r['HeightInvalid'] for r in rows),limitations='Motion location, not stationary anatomical tail position. Reconstructed from saved float32 row profiles; no per-column rerender validation for this trial. Invalid pairs and tail bad flags retained; plot paths break at missing values.',style='Supplied speed SVG geometry x22.1..267.56 y13.41..90.12; added time labels below; blue bands are saved stops'),indent=2))
