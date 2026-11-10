"""Presentation triptychs from verified lossless crops; no legend occlusion."""
from pathlib import Path
import csv,json,hashlib,subprocess,math,shutil,sys
import argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--shared-scale',action='store_true',help='One green/red maximum per mouse across all valid full-trial frames; implies tracking-start trimming and final-frame holds.')
parser.add_argument('--shared-runner-scale',action='store_true',help='Legacy runner-only shared-scale option.')
parser.add_argument('--trim-hold',action='store_true')
parser.add_argument('--source-root',type=Path)
parser.add_argument('--output',type=Path,help='Fresh external output directory; never overwritten.')
args=parser.parse_args()
SHARED_RUNNER=args.shared_runner_scale
SHARED_SCALE=args.shared_scale or SHARED_RUNNER
TRIM_HOLD=args.trim_hold or SHARED_SCALE
import numpy as np
from PIL import Image,ImageDraw,ImageFont
SRC=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_selected_tail_movies_20261109')
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_triptychs_20261109')
FF='/opt/homebrew/bin/ffmpeg';PROBE='/opt/homebrew/bin/ffprobe'
if TRIM_HOLD: OUT=OUT.parent/'balance_beam_tail_triptychs_tracking_start_20261109'
if SHARED_RUNNER: OUT=OUT.parent/'balance_beam_runner_shared_scale_20261109'
if args.shared_scale: OUT=OUT.parent/'balance_beam_mouse_shared_scale_20261109'
if args.source_root: SRC=args.source_root
if args.output: OUT=args.output
assert not OUT.exists(),'Choose a fresh destination';OUT.mkdir()
def records(path):
    with path.open() as f:return list(csv.DictReader(f))
selected=[r for r in json.loads((SRC/'review_validation.json').read_text()) if r['role']=='requested']
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',22)
metas=[json.loads((SRC/r['folder']/'render_inputs/metadata.json').read_text()) for r in selected]
assert all(m['displayScale']==2 and m['fps']==30 and m['scaleBarMM']==20 for m in metas)
assert len({m['mmPerPixel'] for m in metas})==1
PW=max(m['width']*2 for m in metas);ANCHOR=max(2*(m['barTop']-1) for m in metas)
PH=max(ANCHOR-2*(m['barTop']-1)+2*m['height'] for m in metas)
HEADER=56;GAP=16;CW=PW*3+GAP*2;CH=HEADER+PH
assert CW%2==CH%2==0
WHITE=bytes((255,255,255));BLACK=bytes((0,0,0));GREEN=bytes((0,155,70));RED=bytes((210,40,45));PURPLE=bytes((160,35,190))
class Panel:
    def __init__(self,r):
        self.r=r;self.path=SRC/r['folder'];work=self.path/'render_inputs';self.m=json.loads((work/'metadata.json').read_text())
        self.n=self.m['nFrames'];self.w=self.m['width'];self.h=self.m['height'];self.scale=2;self.W=self.w*2;self.H=self.h*2
        self.offsetY=ANCHOR-2*(self.m['barTop']-1)
        self.mapping=records(self.path/'frame_mapping.csv');heights=records(work/'motion_height.csv')
        self.q=np.loadtxt(work/'rows.csv',delimiter=',');self.above=np.loadtxt(work/'above.csv',delimiter=',');self.below=np.loadtxt(work/'below.csv',delimiter=',')
        self.valid=np.array([r['InvalidOrUnusable']=='0' for r in heights]);self.sm=np.array([float(r['WeightedMedianSmoothed5MM']) for r in heights])
        self.start=int(np.flatnonzero(self.valid)[0]) if TRIM_HOLD else 0
        self.length=self.n-self.start
        assert [r['OriginalFrame'] for r in self.mapping]==[r['OriginalFrame'] for r in heights]
        self.colmax=max(self.above[self.valid].max(),self.below[self.valid].max());self.rowmax=self.q[self.valid].max()
        self.label=(work/'label.rgb').read_bytes();assert len(self.label)==430*32*3
        self.decoder=subprocess.Popen([FF,'-v','error','-i',str(self.path/'post_mouse_crop_lossless.mkv'),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
    def pixel(self,buf,x,y,color):
        if 0<=x<self.W and 0<=y<self.H:
            i=(y*self.W+x)*3;buf[i:i+3]=color
    def line(self,buf,x0,y0,x1,y1,color,thick=1):
        x0,y0,x1,y1=map(round,(x0,y0,x1,y1));dx=abs(x1-x0);sx=1 if x0<x1 else -1;dy=-abs(y1-y0);sy=1 if y0<y1 else -1;err=dx+dy
        while True:
            for a in range(1-thick,thick):
                for b in range(1-thick,thick):self.pixel(buf,x0+a,y0+b,color)
            if x0==x1 and y0==y1:break
            e=2*err
            if e>=dy:err+=dy;x0+=sx
            if e<=dx:err+=dx;y0+=sy
    def frame(self,k,scale_bar):
        raw=self.decoder.stdout.read(self.w*self.h);assert len(raw)==self.w*self.h
        assert hashlib.sha256(raw).hexdigest()==self.mapping[k]['LosslessGrayFrameSHA256']
        gray=np.frombuffer(raw,np.uint8).reshape(self.h,self.w)
        enlarged=np.repeat(np.repeat(gray,2,axis=0),2,axis=1)
        frame=bytearray(np.repeat(enlarged[:,:,None],3,axis=2).tobytes())
        bar=2*(self.m['barTop']-1);bottom=bar+2*self.m['barWidth']
        if self.valid[k]:
            for vector,color,base,direction in ((self.above[k],GREEN,bar,-1),(self.below[k],RED,bottom,1)):
                last=None
                for x,v in enumerate(vector):
                    pt=(x*2,base+direction*2*75*v/self.colmax)
                    if last is not None:self.line(frame,*last,*pt,color,2)
                    last=pt
            last=None
            for r,v in enumerate(self.q[k]):
                pt=(self.W-1-2*90*v/self.rowmax,2*r)
                if last is not None:self.line(frame,*last,*pt,PURPLE,2)
                last=pt
            yy=bar-2*self.sm[k]/self.m['mmPerPixel']
            self.line(frame,self.W/2-15,yy,self.W/2+15,yy,WHITE,4);self.line(frame,self.W/2-15,yy,self.W/2+15,yy,BLACK,2)
        else:
            self.line(frame,self.W-25,10,self.W-10,25,RED,2);self.line(frame,self.W-10,10,self.W-25,25,RED,2)
        if scale_bar:
            y=bottom+12;end=y+round(2*20/self.m['mmPerPixel']);x=11
            self.line(frame,x,y,x,end,WHITE,4);self.line(frame,x,y,x,end,BLACK,2)
            self.line(frame,x-4,y,x+4,y,BLACK);self.line(frame,x-4,end,x+4,end,BLACK)
            width=min(65,self.W-x-8);top=y+round((end-y-32)/2)
            for yy in range(32):
                dst=((top+yy)*self.W+x+8)*3;src=yy*430*3;frame[dst:dst+width*3]=self.label[src:src+width*3]
        return np.frombuffer(frame,np.uint8).reshape(self.H,self.W,3)
    def close(self):
        assert not self.decoder.stdout.read(1),'Extra crop frames';self.decoder.stdout.close();assert self.decoder.wait()==0

reports=[]
for group in (['run'] if SHARED_RUNNER else ['sedentary','walk','run']):
    rs=sorted([r for r in selected if r['group']==group],key=lambda r:r['day']);assert [r['day'] for r in rs]==[0,7,14]
    assert len({'_'.join(r['file'].split('_')[:2]) for r in rs})==1,'Panels must belong to one mouse'
    panels=[Panel(r) for r in rs];n=max(p.length for p in panels);mouse='_'.join(rs[0]['file'].split('_')[:2])
    trial_maxima=[float(p.colmax) for p in panels]
    if SHARED_SCALE:
        for p in panels:p.colmax=max(trial_maxima)
    filename=f'{mouse}_{group}_D0-T{rs[0]["trial"]}_D7-T{rs[1]["trial"]}_D14-T{rs[2]["trial"]}.mp4'
    if SHARED_SCALE: filename=filename.replace('.mp4','_shared_green_red_scale.mp4')
    path=OUT/filename;partial=OUT/(path.stem+'.partial.mp4')
    canvas=Image.new('RGB',(CW,CH),'white');draw=ImageDraw.Draw(canvas)
    for j,r in enumerate(rs):
        label=f'{mouse}  |  D{r["day"]}  |  {group}';box=draw.textbbox((0,0),label,font=font);tw=box[2]-box[0]
        assert tw<PW-16;draw.text((j*(PW+GAP)+(PW-tw)/2,15),label,font=font,fill='black')
    background=np.array(canvas)
    for j in range(3):background[HEADER:,j*(PW+GAP):j*(PW+GAP)+PW]=0
    encoder=subprocess.Popen([FF,'-v','error','-f','rawvideo','-pix_fmt','rgb24','-s',f'{CW}x{CH}','-r','30','-i','-','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p','-threads','4',str(partial)],stdin=subprocess.PIPE)
    if TRIM_HOLD:
        for p in panels:
            for skipped in range(p.start):
                raw=p.decoder.stdout.read(p.w*p.h)
                assert hashlib.sha256(raw).hexdigest()==p.mapping[skipped]['LosslessGrayFrameSHA256']
    lastframes=[None]*3
    maprows=[];checks=[];checkframes={0,n-1,*[p.length for p in panels if p.length<n],*[p.length-1 for p in panels]}
    # A middle-frame preview shows the moving crops after their entry-invalid intervals.
    preview=min(p.length for p in panels)//2;checkframes.add(preview)
    try:
        for k in range(n):
            frame=background.copy();row={'PresentationFrame':k+1,'PresentationTimeSeconds':k/30}
            for j,p in enumerate(panels):
                x=j*(PW+GAP);active=k<p.length;idx=min(k+p.start,p.n-1);day=rs[j]['day'];row[f'D{day}Active']=active
                row[f'D{day}HeldFinalFrame']=not active if TRIM_HOLD else False
                row[f'D{day}OriginalFrame']=p.mapping[idx]['OriginalFrame'] if active or TRIM_HOLD else ''
                row[f'D{day}EncodedTimeSeconds']=p.mapping[idx]['EncodedTimeSeconds'] if active or TRIM_HOLD else ''
                row[f'D{day}InvalidOrUnusable']=bool(not p.valid[idx]) if active or TRIM_HOLD else ''
                if active:lastframes[j]=p.frame(idx,j==0)
                if active or TRIM_HOLD:frame[HEADER+p.offsetY:HEADER+p.offsetY+p.H,x:x+p.W]=lastframes[j]
                else:assert not frame[HEADER:,x:x+PW].any()
            maprows.append(row);encoder.stdin.write(frame.tobytes())
            if k in checkframes:
                Image.fromarray(frame).save(OUT/f'{group}_reference_frame{k+1}.png');checks.append(k)
            if (k+1)%100==0:
                (OUT/'progress.json').write_text(json.dumps({'group':group,'framesWritten':k+1,'totalFrames':n}));print(group,k+1,'/',n,flush=True)
        for p in panels:p.close()
        encoder.stdin.close();assert encoder.wait()==0
    except BaseException:
        encoder.kill();encoder.wait()
        for p in panels:p.decoder.kill();p.decoder.wait()
        raise
    partial.rename(path)
    with (OUT/f'{group}_frame_mapping.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(maprows[0]),lineterminator='\n');writer.writeheader();writer.writerows(maprows)
    report={'group':group,'mouseID':mouse,'movie':filename,'frames':n,'fps':30,'durationSeconds':n/30,'width':CW,'height':CH,
      'greenRedScaleMode':'shared_per_mouse_across_full_trials' if SHARED_SCALE else 'per_trial','originalTrialGreenRedMaxima':trial_maxima,'greenRedDisplayMaxima':[float(p.colmax) for p in panels],
      'panelWidth':PW,'panelImageHeight':PH,'headingHeight':HEADER,'gutter':GAP,'beamTopOutputRowZeroBased':HEADER+ANCHOR,
      'scaleBarPanel':'D0 only','legendsInsideImages':False,'startTogether':True,'retimed':False,'trimToFirstValid':TRIM_HOLD,'holdLastFrame':TRIM_HOLD,'no5mmBlanking':True,
      'panels':[{'day':r['day'],'sourceFile':r['file'],'sourceFolder':r['folder'],'frames':p.length,'trimmedLeadingFrames':p.start,'firstOriginalFrame':p.mapping[p.start]['OriginalFrame'],'holdFromPresentationFrame':p.length+1 if TRIM_HOLD and p.length<n else None,'blankFromPresentationFrame':p.length+1 if not TRIM_HOLD and p.length<n else None,
        'durationSeconds':p.length/30,'cropWidth':p.w,'cropHeight':p.h,'integerDisplayScale':2,'imageOffsetX':0,'imageOffsetY':p.offsetY} for r,p in zip(rs,panels)],
      'checkFrameIndicesZeroBased':sorted(checks),'movieSHA256':hashlib.sha256(path.read_bytes()).hexdigest()}
    reports.append(report);(OUT/'presentation_manifest.json').write_text(json.dumps(reports,indent=2))
shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'progress.json').write_text(json.dumps({'status':'rendering_complete','movies':len(reports)}))
print('Rendered',len(reports),'triptychs',flush=True)
