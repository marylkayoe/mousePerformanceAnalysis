"""Validated stopped-frame percentage; standard daily/change cage comparisons."""
import csv,json,math,statistics,sys
from pathlib import Path
from collections import defaultdict
out=Path(__file__).resolve().parent;draft=out.parent.parent
sys.path.insert(0,str(draft/'tail-metrics/whole-motion-reweighted'))
from cage_tests import test
read=lambda p:list(csv.DictReader(p.open()))
def write(name,rows):
 with (out/name).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
trials=read(draft/'analysis-data/trial_manifest.csv');events=read(draft/'analysis-data/events.csv');stopframes=defaultdict(int)
for e in events:
 if e['Type']=='stop':stopframes[e['File']]+=int(e['DurationFrames'])
by=defaultdict(list)
for t in trials:
 assert t['Status']=='complete' and t['CorrectStopTotalMatch']=='1'
 assert int(t['CorrectStoppedFrames'])==stopframes[t['File']]
 assert int(t['Frames'])==int(t['LastOriginalFrame'])-int(t['FirstOriginalFrame'])+1
 by[t['MouseID'],int(t['Day'])].append(t)
mouse=[];excluded=[]
for (m,day),ts in sorted(by.items()):
 if len(ts)!=3:
  excluded.append(dict(mouseID=m,day=day,nTrials=len(ts),reason='Fewer than three retained crossings; consistent with count figures'));continue
 first=ts[0];duration=sum(int(t['Frames'])/float(t['AnalysisFrameRate']) for t in ts);stopped=sum(int(t['CorrectStoppedFrames'])/float(t['AnalysisFrameRate']) for t in ts)
 mouse.append(dict(mouseID=m,cohort=first['Cohort'],cageID=first['CageID'],group=first['Group'],day=f'D{day:02d}',nTrials=len(ts),traversalSeconds=duration,stoppedSeconds=stopped,value=100*stopped/duration,sourceFiles=' | '.join(t['File'] for t in ts)))
write('mouse-day-values.csv',mouse);write('excluded-mouse-days.csv',excluded)
lookup={(r['mouseID'],r['day']):r for r in mouse};panels={};comparisons=[];desc=[]
for period in ('D00','D07','D14','D14-D00'):
 ds=[r for r in mouse if r['day']==period] if '-' not in period else [{**r,'value':r['value']-lookup[r['mouseID'],'D00']['value']} for r in mouse if r['day']=='D14' and (r['mouseID'],'D00') in lookup]
 panels[period]=ds;p,pairs=test(ds)
 for r in pairs:comparisons.append(dict(period=period,nMice=len(ds),overallP=p,**r))
 for g in ('sedentary','walk','run'):
  rr=[r for r in ds if r['group']==g];v=[r['value'] for r in rr];desc.append(dict(period=period,group=g,nMice=len(v),nCages=len({(r['cohort'],r['cageID']) for r in rr}),mean=statistics.mean(v),median=statistics.median(v),SEM=statistics.stdev(v)/math.sqrt(len(v))))
write('group-comparisons.csv',comparisons);write('descriptive.csv',desc)
from PIL import Image,ImageDraw,ImageFont
W,H=1560,590;im=Image.new('RGB',(W,H),'white');d=ImageDraw.Draw(im);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>'];font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=13,anchor='start'):
 from xml.sax.saxutils import escape
 svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}">{escape(s)}</text>');f=ImageFont.truetype(font,size);w=d.textlength(s,font=f);d.text((x-(w/2 if anchor=='middle' else w if anchor=='end' else 0),y-size),s,font=f,fill='black')
def line(x,y,xx,yy,c='#333333',width=1):
 svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{c}" stroke-width="{width}"/>');d.line((x,y,xx,yy),fill=c,width=width)
text(W/2,26,'Percentage of traversal time spent stopped',22,'middle');text(W/2,49,'Three crossings per mouse/day · circles: mice · diamonds: cage means · bars: mouse group means',14,'middle');text(W/2,69,'Cage-level permutations within cohort; pairwise Holm correction within each panel',13,'middle')
maxday=max(r['value'] for r in mouse);upper=math.ceil(maxday/10)*10+20
changes=[r['value'] for r in panels['D14-D00']];lo=math.floor(min(changes)/10)*10;hi=math.ceil(max(changes)/10)*10+20
for j,(period,ds) in enumerate(panels.items()):
 left=55+j*390;right=left+320;top=112;bottom=515;low,high=(0,upper) if j<3 else (lo,hi)
 Y=lambda v:bottom-(v-low)/(high-low)*(bottom-top)
 text((left+right)/2,97,{'D00':'D0','D07':'D7','D14':'D14','D14-D00':'D14 − D0 (percentage points)'}[period],16,'middle')
 for tick in range(int(low),int(high)+1,10):
  y=Y(tick);line(left,y,right,y,'#E5E5E5');text(left-6,y+4,str(tick),11,'end')
 for g,col,idx in [('sedentary','#000000',0),('walk','#008d3f',1),('run','#0864cf',2)]:
  rr=sorted([r for r in ds if r['group']==g],key=lambda r:r['mouseID']);center=left+65+idx*98;cages=defaultdict(list)
  for i,r in enumerate(rr):
   x=center-14+28*i/(len(rr)-1);y=Y(r['value']);svg.append(f'<circle cx="{x}" cy="{y}" r="3.5" fill="{col}" fill-opacity="0.4"/>');rgb=tuple(int(col[k:k+2],16) for k in (1,3,5));fill=tuple(round(v*.4+255*.6) for v in rgb);d.ellipse((x-3.5,y-3.5,x+3.5,y+3.5),fill=fill);cages[r['cohort'],r['cageID']].append(r['value'])
  for vs in cages.values():
   x=center-28;y=Y(statistics.mean(vs));pts=[(x-4,y),(x,y-6),(x+4,y),(x,y+6)];svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in pts)+f'" fill="{col}" stroke="#222222" stroke-width=".5"/>');d.polygon(pts,fill=col,outline='black')
  mu=Y(statistics.mean(r['value'] for r in rr));line(center-17,mu,center+17,mu,col,3);text(center,540,{'sedentary':'SED','walk':'WALK','run':'RUN'}[g],13,'middle')
 line(left,top,left,bottom);qs=[r for r in comparisons if r['period']==period];text(left+9,131,f"Overall p = {qs[0]['overallP']:.3f}",12)
 text(left+9,150,'Pairs: S–W / S–R / W–R',11);text(left+9,168,'Raw: '+ ' / '.join(f"{r['p_raw']:.3f}" for r in qs),11);text(left+9,186,'Holm: '+ ' / '.join(f"{r['p_holm_3_pairs']:.3f}" for r in qs),11)
text(W/2,575,'Daily values: stopped time / tracked traversal time × 100; change calculated within mouse',13,'middle')
svg.append('</svg>');stem=out/'stop-time-percentage-days-and-change';stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
(out/'README.md').write_text('''# Stop-time percentage

Per mouse/day: 100 × sum(validated stopped frames / analysis fps) / sum(traversal frames / analysis fps), across three retained crossings. This is a duration-weighted percentage, not mean event duration or an unweighted mean of trial percentages. Uses CorrectStoppedFrames, not the inconsistent legacy total-stop-duration field. All 377 trial stop totals match summed saved event durations; traversal lengths match original-frame endpoints. No tape-position exclusions. Traversal means the tracked interval, not the full source video.

For consistency with count figures, TMCS2_S10 D0 (two crossings) is excluded, as is its paired D14−D0 change. D0/change: 41 mice; D7/D14: 42. Within-mouse changes are percentage points. Nonfinite values are not replaced with zero.

Statistics reuse ../.. /tail-metrics/whole-motion-reweighted/cage_tests.py (path without space): cage means, exact label permutations within cohort; three pairwise tests Holm-adjusted per panel. No correction across days/outcomes. Cohort-stratified permutation assumption follows existing analyses; confirm allocation stratification. Exploratory analysis. Mouse group mean bars are not cage-balanced estimates.

Reproduce with analyze.py using Python + NumPy + Pillow. CSV tables, editable SVG and PNG are generated here. Original scientific data and analysis pipeline unchanged.
''')
print(json.dumps(desc,indent=2));print(json.dumps(comparisons,indent=2))
