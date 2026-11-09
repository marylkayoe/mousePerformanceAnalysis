"""Reproduce target band overlay and continuous source-frame context clip."""
from reviewBeamEntrance import *
name='TMCS3_S07_T1_C03_BB_D00_20260219_THT_TRIAL4_gray.mp4'
frames=[950,1500,1750,1765,1790,1885]
expr='+'.join('eq(n,%d)'%(f-1) for f in frames)
raw=run(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(SOURCE/name),'-vf',"select='%s',format=gray"%expr,'-fps_mode','passthrough','-f','rawvideo','-'])
images=np.frombuffer(raw,np.uint8).reshape(-1,356,1280)
canvas=Image.new('RGB',(1200,780),'white');draw=ImageDraw.Draw(canvas)
by={int(t['OriginalFrame']):t for t in trace(name)}
for i,(frame,im) in enumerate(zip(frames,images)):
    x=i%2*600;y=i//2*260
    crop=Image.fromarray(im).crop((980,170,1280,280)).convert('RGB').resize((600,220));d=ImageDraw.Draw(crop)
    d.line((0,(214-170)*2,599,(214-170)*2),fill='yellow',width=2)
    d.rectangle((0,(224-170)*2,599,(240-170)*2),outline='red',width=2)
    canvas.paste(crop,(x,y));draw.text((x+5,y+225),'frame %d | speed %.2f | movement %.2f'%(frame,float(by[frame]['ForwardSpeed']),float(by[frame]['MovementTrace'])),fill='black')
    draw.text((x+5,y+242),'yellow: detected bar top; red: slip detector rows 224-240',fill='black')
canvas.save(OUT/'target_detector_band.jpg',quality=94)
run(['/opt/homebrew/bin/ffmpeg','-v','error','-y','-i',str(SOURCE/name),'-vf','trim=start_frame=1068:end_frame=1935,setpts=4*(PTS-STARTPTS)','-r','40','-an','-c:v','libx264','-crf','20','-pix_fmt','yuv420p',str(OUT/'clips/TARGET_continuous_1069_1935.mp4')])
