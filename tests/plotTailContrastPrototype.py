"""Exploratory layout: baseline, paired changes, biologically motivated contrasts.
Descriptive percentile cage-bootstrap intervals, not multiplicity-adjusted.
"""
from pathlib import Path
import csv,json,xml.etree.ElementTree as ET
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];base=R/'BEAMCROSS/DRAFTFIGS/tail-metrics';out=base/'contrast-layout-example';out.mkdir(exist_ok=True)
rows=list(csv.DictReader((base/'whole-motion-reweighted/mouse-day-values.csv').open()));lookup={(r['mouseID'],r['day']):r for r in rows};cells={}
for r in rows:
 if r['day']!='D14':continue
 val=float(r['meanLegacy'])-float(lookup[r['mouseID'],'D00']['meanLegacy']);cells.setdefault((r['cohort'],r['cageID'],r['group']),[]).append(val)
cages={k:np.mean(v) for k,v in cells.items()};rng=np.random.default_rng(20261111);N=100000;results=[]
stats=[r for r in csv.DictReader((base/'whole-motion-reweighted/group-comparisons.csv').open()) if r['metric']=='Legacy' and r['period']=='D14-D00']
for A,B in [('run','walk'),('run','sedentary')]:
 boot=np.zeros(N);estimate=0;counts={}
 for co in ('TMCS2','TMCS3'):
  for g,sign in [(A,1),(B,-1)]:
   v=np.array([val for (c,ca,gg),val in cages.items() if c==co and gg==g]);counts[co+'_'+g]=len(v);estimate+=sign*.5*v.mean();boot+=sign*.5*rng.choice(v,size=(N,len(v)),replace=True).mean(axis=1)
 low,high=np.quantile(boot,[.025,.975]);st=next(r for r in stats if r['pair']==A+' minus '+B)
 assert np.isclose(estimate,float(st['difference_cage_cohort_balanced']))
 results.append(dict(pair=A+' minus '+B,estimate=estimate,lower=float(low),upper=float(high),p_holm=float(st['p_holm_3_pairs']),cages=counts))
# Original two scatter panels stay editable; remove significance marks to avoid
# implying that the hypothesis hierarchy has changed the established tests.
ns='http://www.w3.org/2000/svg';ET.register_namespace('',ns)
W,H=326,106;root=ET.Element('{'+ns+'}svg',{'viewBox':f'0 0 {W} {H}'})
for i,name in enumerate(['tail_score_D0_mouse_cage_comparison','tail_score_D14_minus_D0_mouse_cage_comparison']):
 panel=ET.parse(base/(name+'.svg')).getroot();g=ET.SubElement(root,'{'+ns+'}g',{'transform':f'translate({i*95} 8)'})
 for el in panel:
  # Existing change bracket consists of four appended nodes after data groups.
  if i==1 and (el.tag.endswith('text') and ''.join(el.itertext())=='*'):continue
  if i==1 and el.tag.endswith('line') and float(el.get('y1','999'))<20 and float(el.get('x1','0'))>20:continue
  g.append(el)
def text(x,y,t,size=3.4,anchor='start',fill='#232323'):
 e=ET.SubElement(root,'{'+ns+'}text',{'x':str(x),'y':str(y),'font-family':'Arial','font-size':str(size),'text-anchor':anchor,'fill':fill});e.text=t

def line(x,y,xx,yy,color='#232323',width=.4,dash=None):
 a={'x1':str(x),'x2':str(xx),'y1':str(y),'y2':str(yy),'stroke':color,'stroke-width':str(width)}
 if dash:a['stroke-dasharray']=dash
 ET.SubElement(root,'{'+ns+'}line',a)
text(190,15,'Comparisons of D14−D0 changes',5.5)
text(190,22,'Cage/cohort-balanced differences',3.2)
L,RR=250,321;lo,hi=-.3,.15;X=lambda v:L+(v-lo)/(hi-lo)*(RR-L)
line(X(0),29,X(0),76,'#aaaaaa',.35,'1.3 1')
for i,r in enumerate(results):
 y=40+i*26;text(190,y-2,'RUN − WALK' if i==0 else 'RUN − SED',4)
 text(190,y+4,'Beyond shared routine' if i==0 else 'Overall procedure',2.9)
 line(X(r['lower']),y,X(r['upper']),y,'#002bff',.8)
 ET.SubElement(root,'{'+ns+'}circle',{'cx':str(X(r['estimate'])),'cy':str(y),'r':'1.4','fill':'#002bff'})
 text((L+RR)/2,y+9,f"Holm p = {r['p_holm']:.3f}",2.8,'middle')
line(L,81,RR,81)
for v in [-.3,-.15,0,.15]:line(X(v),81,X(v),82.5);text(X(v),87,f'{v:g}',3,'middle')
text((L+RR)/2,93,'Difference in change (a.u.)',3.2,'middle')
text(4,101,'Prototype: intervals are 95% cage-bootstrap estimates; p-values retain the original three-pair Holm correction.',3)
text(4,105,'Sparse cage replication limits interval reliability; these intervals are not simultaneous confidence intervals.',2.8)
stem=out/'tail_score_baseline_changes_and_contrasts';ET.ElementTree(root).write(stem.with_suffix('.svg'),encoding='utf-8',xml_declaration=True)
# Lightweight preview rasterization of composed vector primitives.
# Render original scatter PNGs, then draw the effect panel from its coordinates.
Z=6;im=Image.new('RGB',(W*Z,H*Z),'white');d=ImageDraw.Draw(im);font='/System/Library/Fonts/Supplemental/Arial.ttf'
for i,name in enumerate(['tail_score_D0_mouse_cage_comparison','tail_score_D14_minus_D0_mouse_cage_comparison']):
 pic=Image.open(base/(name+'.png')).convert('RGB').resize((round(85.45*Z),round(84.36*Z)))
 if i==1:
  pd=ImageDraw.Draw(pic);pd.rectangle((29*Z,8*Z,79*Z,20*Z),fill='white')
 im.paste(pic,(i*95*Z,8*Z))
for e in root:
 tag=e.tag.split('}')[-1]
 if tag=='text':d.text((float(e.get('x'))*Z,float(e.get('y'))*Z),e.text,font=ImageFont.truetype(font,round(float(e.get('font-size'))*Z)),fill=e.get('fill'),anchor='ms' if e.get('text-anchor')=='middle' else 'ls')
 elif tag=='line':d.line(tuple(float(e.get(k))*Z for k in ('x1','y1','x2','y2')),fill=e.get('stroke'),width=max(1,round(float(e.get('stroke-width'))*Z)))
 elif tag=='circle':
  x,y,r=map(float,[e.get('cx'),e.get('cy'),e.get('r')]);d.ellipse(((x-r)*Z,(y-r)*Z,(x+r)*Z,(y+r)*Z),fill=e.get('fill'))
im.save(stem.with_suffix('.png'))
stem.with_suffix('.json').write_text(json.dumps(dict(results=results,bootstrapReplicates=N,seed=20261111,definition='Legacy mean normalized corrected whole-range tail score; unchanged from existing scatters.',method='Within-mouse change then cage mean. Equal cohort weight for contrasts. Resample cages with replacement separately within each cohort/group; keep whole-cage changes intact. Percentile95% intervals.',caution='One WALK cage in TMCS3 cannot contribute estimated within-cell bootstrap variation; intervals may underrepresent uncertainty. Layout/estimation prototype only. Original exact-permutation Holm p-values retained; no new testing hierarchy. Bootstrap intervals are unadjusted and need not agree with adjusted p-values.'),indent=2));print(results)
