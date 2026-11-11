"""Motion height geometry with linear motion-score colour encoding."""
from pathlib import Path
import csv,math,json
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/figMaterials';src=out/'TMCS2_S18_D0_T2_tail_example_traces.csv';rows=list(csv.DictReader(src.open()));pairs=[(float(r['MedianMotionHeight5FrameMM']),float(r['TailMotionScore'])) for r in rows];valid=[all(math.isfinite(v) for v in p) for p in pairs];scores=[p[1] for p,ok in zip(pairs,valid) if ok];smin,smax=min(scores),max(scores)
W,H,Z=320,130,4;L,RR,T,B=30,278,20,103;X=lambda i:L+i/967*(RR-L);Y=lambda v:B-(v+40)/120*(B-T)
im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=6,anchor='start',c='#222222'):
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{c}">{s}</text>');f=ImageFont.truetype(font,round(size*Z));ww=d.textlength(s,font=f);d.text((x*Z-(ww/2 if anchor=='middle' else ww if anchor=='end' else 0),(y-size)*Z),s,font=f,fill=c)
def line(x,y,xx,yy,c='#222222',w=.35):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>');d.line((x*Z,y*Z,xx*Z,yy*Z),fill=c,width=max(1,round(w*Z)))
def color(v):
 f=(v-smin)/(smax-smin);a=(0,0,0);b=(235,30,25);rgb=tuple(round(x+(y-x)*f) for x,y in zip(a,b));return '#%02x%02x%02x'%rgb
text(L,9,'Tail motion during traverse',8);text(L,16,'Height: median motion location (mm) · colour: motion score',6)
for v in (-40,0,40,80):
 y=Y(v);line(L,y,RR,y,'#e7e7e7');text(L-3,y+2,str(v),6,'end')
line(L,Y(0),RR,Y(0),'#777777',.5);text(L+2,Y(0)-2,'Bar level',5,c='#666666')
# Draw outline first, then individually editable colour segments.
for i in range(len(rows)-1):
 if valid[i] and valid[i+1]:line(X(i),Y(pairs[i][0]),X(i+1),Y(pairs[i+1][0]),'#333333',1.05)
for i in range(len(rows)-1):
 if valid[i] and valid[i+1]:line(X(i),Y(pairs[i][0]),X(i+1),Y(pairs[i+1][0]),color((pairs[i][1]+pairs[i+1][1])/2),.8)
line(L,T,L,B);line(L,B,RR,B)
for t in range(7):
 x=L+t/(967/160)*(RR-L);line(x,B,x,B+1.5);text(x,B+7,str(t),6,'middle')
text((L+RR)/2,123,'Time since traversal start (s)',7,'middle')
# Linear key uses full observed jointly-valid score range, including negative scores.
text(293,29,'Score',6,'middle');text(293,36,'(a.u.)',5,'middle')
for j in range(180):
 y=43+j/180*48;v=smax-(j+.5)/180*(smax-smin);c=color(v);svg.append(f'<rect x="289" y="{y}" width="5" height="{48/180+.01}" fill="{c}"/>');d.rectangle((289*Z,y*Z,294*Z,(y+48/180)*Z),fill=c)
for v in (smin,0,4,smax):
 y=43+(smax-v)/(smax-smin)*48;line(294,y,296,y);text(298,y+2,f'{v:.1f}',5)
svg.append('</svg>');stem=out/'TMCS2_S18_D0_T2_tail_height_black_to_red';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'));stem.with_suffix('.json').write_text(json.dumps(dict(source=str(src),geometry='Full-profile weighted-median motion height, five-frame smoothing inherited; mm positive above bar',colour='Linear black to red, full jointly valid score range. Each segment uses mean score of its two endpoints. No clipping, extra smoothing or normalization.',colourLimits=[smin,smax],jointlyValidFrames=sum(valid),missing='No segment across invalid endpoints. Slip markers and stop shading omitted.',interpretation='Motion location, not anatomical stationary tail position; negative score values are retained from baseline normalization.'),indent=2));print(smin,smax,sum(valid))
