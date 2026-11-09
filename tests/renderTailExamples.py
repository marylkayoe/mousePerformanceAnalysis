"""Headless rendering of existing debug profiles plus explicit spatial weights."""
from pathlib import Path
import json,subprocess,csv,html
import numpy as np
from PIL import Image,ImageDraw,ImageFont
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_examples_L40_20261109')
FF='/opt/homebrew/bin/ffmpeg'
FONT=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',16)
SMALL=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',13)
def text(d,xy,s,fill='black',small=False):d.text(xy,s,fill=fill,font=SMALL if small else FONT)
def heat(a):
    a=np.clip(a,0,1);return Image.fromarray(np.uint8(np.stack([255*a,220*a,30*a],axis=2)))
for folder in sorted(OUT.glob('*.mp4')):
    if not folder.is_dir():continue
    D=json.loads((folder/'weights_and_mapping.json').read_text());w,h,n=D['width'],D['height'],D['nFrames'];bar,bw=D['barTop'],D['barWidth']
    prob=np.array(D['columnWeightSquared']);above=np.array(D['aboveContrib']);below=np.array(D['belowContrib']);rows=np.array(D['rowMotion'])
    totalw=np.array(D['totalRowWeight']);regionw=np.array(D['aboveRowWeight'])+np.array(D['belowRowWeight'])
    maximum=max(float(above.max()),float(below.max()),1e-12);rowmax=max(float(rows.max()),1e-12)
    tile=max(w,250);W=4*tile+40;W+=W%2;H=h+150;H+=H%2
    def render(frame,k):
        canvas=Image.new('RGB',(W,H),'white');draw=ImageDraw.Draw(canvas)
        bad=bool(D['badFrames'][k]);prevbad=bool(D['previousBadFrames'][k]);orig=D['originalFrames'][k]
        flag='BAD tail frame' if bad else ('Predecessor bad / unavailable' if prevbad else 'Tail mask valid for current + previous frames')
        text(draw,(10,5),D['group']+' | original frame %d | traversal/debug frame %d/%d'%(orig,k+1,n))
        text(draw,(10,27),flag,fill='red' if bad or prevbad else '#006600')
        titles=['Post-mouse crop','Total tail spatial weights','Above / below spatial weights','Existing debug motion profiles']
        images=[Image.fromarray(frame).convert('RGB'),heat(totalw[:,None]*prob[k][None,:]),heat(regionw[:,None]*prob[k][None,:]),Image.fromarray(frame).convert('RGB')]
        overlay=ImageDraw.Draw(images[3]);baseline=bar+(bw-1)/2
        def curve(xs,ys,color):
            pts=[(float(x),float(y)) for x,y in zip(xs,ys) if np.isfinite(y)]
            if len(pts)>1:overlay.line(pts,fill=color,width=2)
        a=above[k].copy();b=below[k].copy();a[prob[k]<=0]=np.nan;b[prob[k]<=0]=np.nan
        curve(np.arange(w),baseline-a/maximum*h/4,'lime');curve(np.arange(w),baseline+b/maximum*h/4,'red')
        curve(w-rows[k]/rowmax*w/2,np.arange(h),'magenta')
        for j,im in enumerate(images):
            x=10+j*tile;text(draw,(x,55),titles[j],small=True);canvas.paste(im,(x,78))
            if j in [1,2]:
                draw.line((x,78+bar-1,x+w-1,78+bar-1),fill='#00aaff');draw.line((x,78+bar+bw-1,x+w-1,78+bar+bw-1),fill='#00aaff')
        y=82+h
        text(draw,(10,y),'Weights: black=0, yellow=1; column probabilities squared at destination frame k.',small=True)
        text(draw,(10,y+18),'Green/red: above/below column motion; magenta: row motion (not mouse-weighted). All profiles pre-normalization.',small=True)
        text(draw,(10,y+36),'Motion uses crop k-1 -> k. Playback 30 fps; source time %.5f s. Bad flags preserved.'%D['encodedTimes'][k],small=True)
        return canvas
    decoder=subprocess.Popen([FF,'-v','error','-i',str(folder/'post_mouse_crop.mp4'),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
    encoder=subprocess.Popen([FF,'-v','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r','30','-i','-','-an','-c:v','libx264','-crf','18','-pix_fmt','yuv420p',str(folder/'tail_debug_weights.mp4')],stdin=subprocess.PIPE)
    padded=w+w%2
    for k in range(n):
        raw=decoder.stdout.read(h*padded);assert len(raw)==h*padded,(k,len(raw));frame=np.frombuffer(raw,np.uint8).reshape(h,padded)[:,:w]
        encoder.stdin.write(render(frame,k).tobytes())
    assert not decoder.stdout.read(1);decoder.stdout.close();assert decoder.wait()==0;encoder.stdin.close();assert encoder.wait()==0
    candidates=json.loads((OUT/(D['group']+'_preview_frames.json')).read_text())
    for original in candidates:
        k=D['originalFrames'].index(original);cur=np.array(Image.open(folder/f'crop_f{original}.png'));prev=np.array(Image.open(folder/f'crop_f{original}_previous.png'))
        render(cur,k).save(folder/f'debug_f{original}.png')
        pair=Image.new('RGB',(3*tile,h+60),'white');draw=ImageDraw.Draw(pair)
        difference=np.uint8(np.clip(abs(cur.astype(float)-prev.astype(float))*6,0,255))
        for j,(im,label) in enumerate([(prev,f'Original {original-1}'),(cur,f'Original {original}'),(difference,'Absolute crop difference x6')]):
            text(draw,(j*tile+4,6),label);pair.paste(Image.fromarray(im),(j*tile,30))
        text(draw,(4,h+35),'Both tail bad-frame flags false; difference includes movement of the crop itself.',small=True)
        pair.save(folder/f'motion_pair_f{original}.png')
    meta=json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe','-v','error','-show_entries','stream=nb_frames,width,height,r_frame_rate','-of','json',str(folder/'tail_debug_weights.mp4')]))
    assert int(meta['streams'][0]['nb_frames'])==n
    (folder/'render_validation.json').write_text(json.dumps({'frames':n,'movie':meta,'exactCropPNGFrames':candidates,'sourceFrameMappingContiguous':all(b-a==1 for a,b in zip(D['originalFrames'],D['originalFrames'][1:]))},indent=2))
    print('RENDERED',D['file'],n,flush=True)
