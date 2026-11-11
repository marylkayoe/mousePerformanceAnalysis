"""Join contiguous profile segments without changing vertices or bridging gaps."""
from pathlib import Path
import re,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1];ns='http://www.w3.org/2000/svg';E.register_namespace('',ns)
pattern=re.compile(r'^M([\d.eE+\-]+),([\d.eE+\-]+)L([\d.eE+\-]+),([\d.eE+\-]+)$')
def fix(path):
 tree=E.parse(path);joined=0
 for parent in tree.getroot().iter():
  prev=None;last=None
  for el in list(parent):
   m=pattern.match(el.get('d',''));eligible=el.tag.endswith('path') and el.get('stroke-width')=='2' and m
   if not eligible:prev=None;last=None;continue
   start=m.group(1,2);end=m.group(3,4)
   if prev is not None and last==start and el.get('stroke')==prev.get('stroke'):
    prev.set('d',prev.get('d')+' L'+','.join(end));parent.remove(el);joined+=1
   else:prev=el
   prev.set('stroke-linejoin','round');prev.set('stroke-linecap','round');last=end
 tree.write(path,encoding='utf-8',xml_declaration=True);return joined
for p in (R/'BEAMCROSS/DRAFTFIGS/posture-presentation').glob('posture_D14_minus_D0*.svg'):
 print(p.name,fix(p))
# Keep future regeneration continuous too.
for name in ['plotPostureChangeProfileAndScatter.py','plotPostureChangeScaleBars.py','plotPostureChangeClean.py','plotSpeedChangeByPosition.py']:
 p=R/'tests'/name;s=p.read_text();old='  for a,b in zip(ii,ii[1:]):line(X(dist[a]),Y(mu[a]),X(dist[b]),Y(mu[b]),c,2)'
 new='''  vertices=[(X(dist[i]),Y(mu[i])) for i in ii]
  svg.append('<path d="M'+' L'.join(f'{x},{y}' for x,y in vertices)+f'" fill="none" stroke="{c}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>')
  d.line([(x*Z,y*Z) for x,y in vertices],fill=c,width=2*Z,joint='curve')'''
 if old in s:p.write_text(s.replace(old,new))
