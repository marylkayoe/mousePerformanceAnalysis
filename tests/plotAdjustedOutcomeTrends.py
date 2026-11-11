"""Seven unconstrained cage-ANCOVA adjusted-mean panels, editable SVG + PNG."""
from pathlib import Path
import ast,csv,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont

REPO=Path(__file__).resolve().parents[1];ROOT=REPO/'BEAMCROSS/DRAFTFIGS/outcome-specific-contrasts/ANCOVA'
OUT=ROOT/'ordered-trend';OUT.mkdir(exist_ok=True)
tree=ast.parse((REPO/'tests/analyzeCageANCOVA.py').read_text())
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)],type_ignores=[]),'ancova_functions','exec'))
rows=list(csv.DictReader((ROOT/'cage_inputs.csv').open()))
tests={r['metric']:r for r in json.loads((OUT/'results.json').read_text())}
configs=[('speed','Locomoting speed','mm/s',1),('time_stopped','Time stopped','%',1),('posture','Posture height','mm',1),
         ('slip_count','Slip count','count',1),('slip_score','Total slip score','10³ a.u. × frames',.001),
         ('motion_height','Motion height','mm relative to bar',1),('tail_score','Tail-motion score','a.u.',1)]
W,H,S=1280,810,2
im=Image.new('RGB',(W*S,H*S),'white');draw=ImageDraw.Draw(im)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">','<rect width="100%" height="100%" fill="white"/>']
font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,t,size=14,anchor='start',color='#232323'):
    from xml.sax.saxutils import escape
    svg.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}">{escape(t)}</text>')
    draw.text((x*S,y*S),t,font=ImageFont.truetype(font,size*S),fill=color,anchor={'start':'ls','middle':'ms','end':'rs'}[anchor])
def line(x,y,xx,yy,color='#232323',width=1):
    svg.append(f'<path d="M{x},{y}L{xx},{yy}" fill="none" stroke="{color}" stroke-width="{width}"/>')
    draw.line((x*S,y*S,xx*S,yy*S),fill=color,width=max(1,round(width*S)))
def circle(x,y,color,r=5):
    svg.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>')
    draw.ellipse(((x-r)*S,(y-r)*S,(x+r)*S,(y+r)*S),fill=color)
text(35,30,'D14 outcomes adjusted for D0',24)
text(35,53,'Unconstrained cage-level ANCOVA estimates · equal cohort averaging · pointwise 95% confidence intervals',14)
table=[]
for i,(key,title,unit,scale) in enumerate(configs):
    rs=[r for r in rows if r['metric']==key];x=np.array([float(r['D0']) for r in rs]);y=np.array([float(r['D14']) for r in rs])
    X=np.column_stack([np.ones(len(rs)),[r['group']=='walk' for r in rs],[r['group']=='run' for r in rs],
                       [r['cohort']=='TMCS3' for r in rs],(x-x.mean())/x.std()])
    m=fit(X,y);crit=tcrit(m['df']);est=[]
    for j,g in enumerate(['SED','WALK','RUN']):
        c=np.array([1,j==1,j==2,.5,0.]);value=float(c@m['b']);se=math.sqrt(c@m['cov']@c)
        est.append(np.array([value,value-crit*se,value+crit*se])*scale)
        table.append(dict(metric=key,group=g,adjusted_mean=value,ci95_lower=value-crit*se,ci95_upper=value+crit*se,
                          baseline_reference=float(x.mean()),TMCS3_reference=.5,n_cages=len(rs),residual_df=m['df']))
    col=i%4;row=i//4;left=55+col*315;top=145+row*320;bottom=top+205;right=left+230
    text(left,top-56,title,19);text(left,top-35,unit,12)
    if key in tests:text(left,top-15,f"Ordered-pattern p = {tests[key]['gaussian_either_direction_p']:.3f}",13)
    else:text(left,top-15,'Order not tested',13,color='#777777')
    low=min(a[1] for a in est);high=max(a[2] for a in est);span=high-low
    step0=span/4;power=10**math.floor(math.log10(step0));step=min([1,2,2.5,5,10],key=lambda v:abs(v-step0/power))*power
    lo=math.floor((low-.08*span)/step)*step;hi=math.ceil((high+.08*span)/step)*step
    Y=lambda v:bottom-(v-lo)/(hi-lo)*(bottom-top)
    line(left,top,left,bottom)
    for v in np.arange(lo,hi+step*.01,step):
        line(left,Y(v),left+4,Y(v));text(left-7,Y(v)+4,f'{v:g}',12,'end')
    xx=[left+45+j*77 for j in range(3)]
    for j in range(2):line(xx[j],Y(est[j][0]),xx[j+1],Y(est[j+1][0]),'#999999',1.3)
    for j,(g,color,a) in enumerate(zip(['SED','WALK','RUN'],['#232323','#00b226','#002bff'],est)):
        mid,l,h=a;line(xx[j],Y(l),xx[j],Y(h),color,2)
        for v in (l,h):line(xx[j]-6,Y(v),xx[j]+6,Y(v),color,2)
        circle(xx[j],Y(mid),color);text(xx[j],bottom+24,g,14,'middle')
text(1000,480,'How to read',18)
for j,t in enumerate(['Lines connect group estimates;','they do not imply equal doses.','Means are not forced to be ordered.','','p tests the whole ordered pattern,','not RUN versus WALK.']):text(1000,507+j*22,t,13)
text(35,737,'Exploratory tests: p-values allow either increasing or decreasing order; no across-outcome adjustment.',14)
text(35,761,'Only speed, stopping, slip count and tail score were tested for order. Outcome selection was informed by the data.',13)
text(35,785,'Intervals assume constant error variance; few cages and influential observations limit precision. See methods and sensitivity results.',13)
svg.append('</svg>');stem=OUT/'seven_metrics_adjusted_D14_ordered_patterns'
stem.with_suffix('.svg').write_text('\n'.join(svg));im.save(stem.with_suffix('.png'))
with stem.with_suffix('.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(table[0]));w.writeheader();w.writerows(table)
(OUT/'FIGURE_NOTES.md').write_text('''# Seven-metric adjusted-D14 figure

Reproduce: tests/plotAdjustedOutcomeTrends.py. SVG is editable; PNG is preview. All seven outcomes use unconstrained cage ANCOVA from ../REPORT.md. Points are model-adjusted group means, not mice or cage observations; bars are pointwise standard homoscedastic 95% t confidence intervals (10 df). Each metric uses its own all-cage mean D0 as the common baseline reference, and cohort coding 0.5 to average the two cohorts equally. These are raw-unit adjusted predictions, not changes or differences relative to SED. Prediction covariates and unscaled estimates are in the companion CSV. Slip score is displayed in thousands only.

Connecting lines describe group ordering, not equal exercise doses. The means have NOT been constrained to follow a trend. Either-direction Gaussian Monte Carlo p-values are displayed for the four previously tested outcomes. Posture, slip score and motion height are marked Order not tested; no hypothesis was invented to fill a panel. A trend p-value is not a test of the RUN–WALK contrast. The four selected outcomes and directions were data-informed; either-direction calibration does not account for selection among outcomes or earlier analyses. No across-outcome correction is claimed.

Intervals and ordered-test p-values address different questions, and intervals are not simultaneous. They share the constant-variance Gaussian model, whose limitations include influential cages and common baseline slopes. Wild-bootstrap sensitivities and methods are in REPORT.md/results.csv. Preserve those with any presentation of this exploratory figure. No significance stars or pairwise brackets are added. Original figures preserved.
''')
print(stem)
