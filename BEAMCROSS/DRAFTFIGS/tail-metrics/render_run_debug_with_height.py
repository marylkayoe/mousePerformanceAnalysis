"""Add synchronized 5-frame motion-height plot to the run debug movie."""
import csv,math,subprocess
from pathlib import Path
p=Path(__file__).resolve().parent; source=p.parent.parent/'example-videos/debug/TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray_tail_debug_weights.mp4'
with (p/'example-motion-height-time-frames.csv').open(newline='') as f:
 a=[r for r in csv.DictReader(f) if r['Group']=='run']
assert len(a)==678 and all(int(r['OriginalFrame'])==685+i for i,r in enumerate(a))
meta=subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-count_frames','-show_entries','stream=width,height,nb_read_frames,r_frame_rate','-of','csv=p=0',str(source)],text=True).strip()
assert meta=='1040,506,30/1,678',meta
v=[float(r['MotionHeightMM']) for r in a];z=[float('nan')]*len(v);i=0
while i<len(v):
 if not math.isfinite(v[i]):i+=1;continue
 j=i
 while j<len(v) and math.isfinite(v[j]):j+=1
 for k in range(i,j):
  window=v[max(i,k-2):min(j,k+3)];z[k]=sum(window)/len(window)
 i=j
panel=p/'run-motion-height-video-panel.png'
raw=subprocess.check_output(['ffmpeg','-loglevel','error','-i',str(panel),'-vf','scale=1040:280','-frames:v','1','-f','rawvideo','-pix_fmt','rgb24','-'])
assert len(raw)==1040*280*3
intermediate=Path('/private/tmp/tara-run-height-panel-30fps.mp4')
encoder=subprocess.Popen(['ffmpeg','-loglevel','error','-y','-f','rawvideo','-pixel_format','rgb24','-video_size','1040x280','-framerate','30','-i','-','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p',str(intermediate)],stdin=subprocess.PIPE)
W,H=1040,280
for r,height in zip(a,z):
 frame=bytearray(raw);time=float(r['ElapsedSeconds']);x=round(90+900*time/4.25)
 x=max(90,min(990,x))
 for yy in range(53,229):
  off=(yy*W+x)*3;frame[off:off+3]=bytes((198,45,38))
 if math.isfinite(height):
  y=round(228-175*(height+20)/85)
  for dy in range(-5,6):
   for dx in range(-5,6):
    xx=x+dx;yy=y+dy
    if dx*dx+dy*dy<=25 and 0<=xx<W and 0<=yy<H:
     off=(yy*W+xx)*3;frame[off:off+3]=bytes((198,45,38))
 encoder.stdin.write(frame)
encoder.stdin.close();assert encoder.wait()==0
out=p/'TMCS2_S18-D14-trial2-tail-debug-with-motion-height.mp4'
subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(source),'-i',str(intermediate),'-filter_complex','[0:v][1:v]vstack=inputs=2[v]','-map','[v]','-an','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-shortest',str(out)],check=True)
print('Saved',out,'with',len(a),'synchronized frames')
