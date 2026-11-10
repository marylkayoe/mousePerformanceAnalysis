"""Internal renderer for createTailMetricsDebugVideo; inputs are prevalidated."""
import csv, hashlib, json, math, subprocess, sys
from pathlib import Path

work, crop, mapping_path, label_source, output = map(Path, sys.argv[1:])
meta = json.loads((work / 'metadata.json').read_text())
def read_matrix(name):
    with (work / name).open(newline='') as f:
        return [[float(x) for x in row] for row in csv.reader(f)]
q, above, below = (read_matrix(name) for name in ('rows.csv','above.csv','below.csv'))
with mapping_path.open(newline='') as f:
    mapping = list(csv.DictReader(f))
n, w, h, scale = (meta[k] for k in ('nFrames','width','height','displayScale'))
assert len(q) == len(above) == len(below) == len(mapping) == n
assert all(len(row) == h for row in q)
assert all(len(row) == w for a in (above, below) for row in a)
assert all(int(m['OriginalFrame']) == meta['originalFrames'][k] for k,m in enumerate(mapping))
valid, medians = [], [math.nan]*n
for k in range(n):
    if meta['invalid'][k]:
        continue
    row=q[k]; a=above[k]; b=below[k]
    if not all(math.isfinite(x) and x>=0 for x in row+a+b) or sum(row)<=0:
        continue
    valid.append(k)
    total=sum(row); running=0
    for r,weight in enumerate(row):
        running+=weight
        if running>=total/2:
            medians[k]=(meta['barTop']-1-r)*meta['mmPerPixel']
            break
if not valid:
    raise ValueError('No valid finite, nonzero motion profiles')
smoothed=[math.nan]*n
for k in valid:
    lo=k
    while lo>max(0,k-2) and math.isfinite(medians[lo-1]): lo-=1
    hi=k+1
    while hi<min(n,k+3) and math.isfinite(medians[hi]): hi+=1
    smoothed[k]=sum(medians[lo:hi])/(hi-lo)
# Retain inspectable full-profile median values; no near-bar row exclusion.
with (work/'motion_height.csv').open('w', newline='') as f:
    writer=csv.writer(f,lineterminator='\n')
    writer.writerow(['ExportFrame','OriginalFrame','InvalidOrUnusable','WeightedMedianMM','WeightedMedianSmoothed5MM'])
    valid_indices=set(valid)
    writer.writerows((k+1,meta['originalFrames'][k],int(k not in valid_indices),medians[k],smoothed[k]) for k in range(n))
colmax=max(max(max(above[k]),max(below[k])) for k in valid)
rowmax=max(max(q[k]) for k in valid)
if not colmax or not rowmax: raise ValueError('Cannot plot a zero motion scale')
window=meta.get('displaySpatialWindow',1)
if not isinstance(window,int) or window<1 or window%2!=1:
    raise ValueError('displaySpatialWindow must be a positive odd number')
def display_spatial(values):
    # Display-only smoothing along source-image columns; no temporal mixing.
    # Keep the unsmoothed colmax, so this doesn't rescale either trace.
    if window==1: return values
    radius=window//2
    return [sum(values[max(0,i-radius):min(len(values),i+radius+1)]) /
            (min(len(values),i+radius+1)-max(0,i-radius)) for i in range(len(values))]
W,H=w*scale,h*scale
if W%2 or H%2: raise ValueError('Scaled output dimensions must both be even')
bar=scale*(meta['barTop']-1); bar_bottom=scale*(meta['barTop']-1+meta['barWidth'])
bar_y=bar_bottom+12; bar_end=bar_y+round(scale*meta['scaleBarMM']/meta['mmPerPixel'])
if bar_end+4>=H or W<100: raise ValueError('Scale bar does not fit within crop; use a smaller ScaleBarMM')
# The existing macOS Core Text helper creates a white RGB label using Arial.
subprocess.run(['clang','-x','objective-c','-fobjc-arc','-framework','Foundation','-framework','CoreText','-framework','CoreGraphics',str(label_source),'-o',str(work/'label')],check=True)
labelstr=f"{meta['scaleBarMM']:g} mm"
legend_labels = [('above','Above-bar motion'),('below','Below-bar motion'),
                 ('height','Motion by height'),('median','Median motion height')]
requests=[f'{work}/label.rgb\t{labelstr}']
requests.extend(f'{work}/{key}.rgb\t{text}' for key,text in legend_labels)
(work/'labels.tsv').write_text('\n'.join(requests)+'\n')
subprocess.run([str(work/'label'),str(work/'labels.tsv')],check=True)
label=(work/'label.rgb').read_bytes()
legend=[(work/f'{key}.rgb').read_bytes() for key,_ in legend_labels]
assert len(label)==430*32*3
assert all(len(item)==430*32*3 for item in legend)

def pixel(buf,x,y,color):
    if 0<=x<W and 0<=y<H:
        i=(y*W+x)*3;buf[i:i+3]=color

def line(buf,x0,y0,x1,y1,color,thick=1):
    x0,y0,x1,y1=map(round,(x0,y0,x1,y1));dx=abs(x1-x0);sx=1 if x0<x1 else -1;dy=-abs(y1-y0);sy=1 if y0<y1 else -1;err=dx+dy
    while True:
        for a in range(1-thick,thick):
            for b in range(1-thick,thick): pixel(buf,x0+a,y0+b,color)
        if x0==x1 and y0==y1: break
        e=2*err
        if e>=dy:err+=dy;x0+=sx
        if e<=dx:err+=dx;y0+=sy
white=bytes((255,255,255));black=bytes((0,0,0));green=bytes((0,155,70));red=bytes((210,40,45));purple=bytes((160,35,190))
decoder=subprocess.Popen(['ffmpeg','-loglevel','error','-i',str(crop),'-f','rawvideo','-pix_fmt','gray','-'],stdout=subprocess.PIPE)
encoder=subprocess.Popen(['ffmpeg','-loglevel','error','-y','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate',str(meta['fps']),'-i','-','-an','-c:v','libx264','-crf','17','-pix_fmt','yuv420p',str(output)],stdin=subprocess.PIPE)
validset=set(valid)
(work/'render_progress.json').write_text(json.dumps({'status':'rendering','framesWritten':0,'totalFrames':n}))
try:
    for k,m in enumerate(mapping):
        parts=[]; received=0; needed=w*h
        while received<needed:
            part=decoder.stdout.read(needed-received)
            if not part: raise ValueError(f'Crop ended early at export frame {k+1}')
            parts.append(part);received+=len(part)
        gray=b''.join(parts)
        expected=m['LosslessGrayFrameSHA256'].strip().lower()
        if not expected or hashlib.sha256(gray).hexdigest()!=expected:
            raise ValueError(f'Crop SHA-256 mismatch at export frame {k+1}')
        frame=bytearray()
        for y in range(h):
            row=b''.join(bytes((v,v,v))*scale for v in gray[y*w:(y+1)*w])
            frame.extend(row*scale)
        if k in validset:
            for vector,color,base,direction in ((above[k],green,bar,-1),(below[k],red,bar_bottom,1)):
                last=None
                for x,v in enumerate(display_spatial(vector)):
                    pt=(x*scale,base+direction*scale*75*v/colmax)
                    if last is not None:line(frame,*last,*pt,color,2)
                    last=pt
            last=None
            for r,v in enumerate(q[k]):
                pt=(W-1-scale*90*v/rowmax,scale*r)
                if last is not None:line(frame,*last,*pt,purple,2)
                last=pt
            yy=bar-scale*smoothed[k]/meta['mmPerPixel']
            line(frame,W/2-15,yy,W/2+15,yy,white,4)
            line(frame,W/2-15,yy,W/2+15,yy,black,2)
        # Compact legend stays inside the crop. White panels preserve text
        # readability across changing backgrounds; colored swatches are drawn
        # separately so their colors match the corresponding traces.
        for i,(legend_image,color) in enumerate(zip(legend,(green,red,purple,black))):
            top=8+i*24; left=8
            for y in range(24):
                if top+y>=H: continue
                # Leave room for the colored swatch on the left.
                panel_width=min(205,W-left)
                dst=((top+y)*W+left)*3
                frame[dst:dst+panel_width*3]=white*panel_width
                text_width=min(170,W-left-28)
                if text_width>0:
                    dst=((top+y)*W+left+28)*3;src=(y+4)*430*3
                    frame[dst:dst+text_width*3]=legend_image[src:src+text_width*3]
            line(frame,left+6,top+12,left+22,top+12,color,2)
        if k not in validset:
            line(frame,W-25,10,W-10,25,red,2);line(frame,W-10,10,W-25,25,red,2)
        x=11
        line(frame,x,bar_y,x,bar_end,white,4);line(frame,x,bar_y,x,bar_end,black,2)
        line(frame,x-4,bar_y,x+4,bar_y,black);line(frame,x-4,bar_end,x+4,bar_end,black)
        label_width=min(65,W-x-8); y0=bar_y+round((bar_end-bar_y-32)/2)
        for y in range(32):
            if 0<=y0+y<H:
                dst=((y0+y)*W+x+8)*3;src=y*430*3
                frame[dst:dst+label_width*3]=label[src:src+label_width*3]
        encoder.stdin.write(frame)
        if (k+1)%100==0:
            (work/'render_progress.json').write_text(json.dumps({'status':'rendering','framesWritten':k+1,'totalFrames':n}))
    if decoder.stdout.read(1):raise ValueError('Crop contains more frames than the traces')
    decoder.stdout.close()
    if decoder.wait()!=0:raise RuntimeError('Crop decoder failed')
    encoder.stdin.close()
    if encoder.wait()!=0:raise RuntimeError('Video encoder failed')
except BaseException:
    decoder.kill(); encoder.kill(); decoder.wait(); encoder.wait()
    raise
(work/'render_progress.json').write_text(json.dumps({'status':'complete','framesWritten':n,'totalFrames':n}))
print(f'Rendered {n} frames; {len(valid)} valid; {n-len(valid)} flagged or nonfinite/no-motion; per-frame crop hashes verified; display-only spatial window: {window} columns.')
