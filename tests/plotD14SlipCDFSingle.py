"""Compact D14 mouse-weighted slip-score CDF, three groups together."""
from pathlib import Path
import csv,math,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS';ns='http://www.w3.org/2000/svg';ET.register_namespace('',ns)
root=ET.Element('{'+ns+'}svg',{'viewBox':'0 0 95.04 85.54'})
def text(x,y,t,size=3,anchor='start',color='#232323'):
 e=ET.SubElement(root,'{'+ns+'}text',{'x':str(x),'y':str(y),'font-family':'Arial','font-size':str(size),'text-anchor':anchor,'fill':color});e.text=t;return e
def path(d,c='#333333',w=.25):return ET.SubElement(root,'{'+ns+'}path',{'d':d,'stroke':c,'stroke-width':str(w),'fill':'none'})
L,RR,T,B=15.11,83.27,11.51,73
X=lambda a:L+(math.log10(a)+1)/5*(RR-L);Y=lambda a:B-a*(B-T)
text(L,3.4,'Slip-event score distribution, D14',3.3);text(L,7.4,'Cumulative fraction · equal weight per mouse',2.3)
for a in [0,.25,.5,.75,1]:
 y=Y(a);path(f'M{L},{y}H{RR}','#e6e6e6',.17);text(L-2,y+1.2,f'{a:g}',3.5,'end')
for a in range(-1,5):
 x=X(10**a);path(f'M{x},{B}v1');text(x,B+5,str(a).replace('-','−'),3.5,'middle')
rows=list(csv.DictReader((out/'slip_score_CDF_D0_D14_by_group.csv').open()));export=[]
for i,(g,c,label) in enumerate([('sedentary','#232323','SED'),('walk','#00b226','WALK'),('run','#002bff','RUN')]):
 rs=[r for r in rows if r['Group']==g and r['Day']=='D14'];assert rs;pts=[(X(.1),Y(0))];prev=0
 for r in rs:
  a=float(r['Score']);b=float(r['MeanMouseCumulativeFraction']);pts.extend([(X(a),Y(prev)),(X(a),Y(b))]);prev=b;export.append(r)
 assert prev==1;pts.append((X(10000),Y(1)));path('M'+' L'.join(f'{x:.5f},{y:.5f}' for x,y in pts),c,.4)
 ly=56+i*5;path(f'M58,{ly}h6',c,.4);text(66,ly+1,label,3,color=c)
path(f'M{L},{T}V{B}H{RR}');text((L+RR)/2,84,'log10(slip-event score)',3.3,'middle')
stem=out/'D14_slip_score_CDF_three_groups';ET.ElementTree(root).write(stem.with_suffix('.svg'),encoding='utf-8',xml_declaration=True)
with stem.with_suffix('.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(export[0]));w.writeheader();w.writerows(export)
print(stem.with_suffix('.svg'))
