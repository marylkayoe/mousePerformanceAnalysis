"""Preserve supplied Illustrator geometry; relabel CDF axes only.
Usage: python3 tests/restyleD0SlipCDFReference.py path/to/reference.svg
"""
from pathlib import Path
import sys,re,xml.etree.ElementTree as ET
src=Path(sys.argv[1]);ns='http://www.w3.org/2000/svg';ET.register_namespace('',ns)
tree=ET.parse(src);root=tree.getroot();before=[e.get('d') for e in root.iter() if e.tag.endswith('path')]
xs=iter(zip([15.11,28.74,42.37,56.01,69.64,83.27],[-1,0,1,2,3,4]))
for e in root.iter('{'+ns+'}text'):
 t=''.join(e.itertext())
 if t.endswith('%'):
  y=float(re.search(r'translate\([^ ]+ ([^)]+)',e.get('transform')).group(1))
  for c in list(e):e.remove(c)
  e.text=f'{float(t[:-1])/100:g}';e.set('transform',f'translate(13 {y+1})');e.set('text-anchor','end');e.set('style','font-size:4px')
 elif t in ['0.1','1','10','100','1000','10000']:
  x,power=next(xs)
  for c in list(e):e.remove(c)
  e.text='10';e.set('transform',f'translate({x} 83.59)');e.set('text-anchor','middle');e.set('style','font-size:4px')
  span=ET.SubElement(e,'{'+ns+'}tspan',{'baseline-shift':'super','font-size':'2.8px'});span.text=str(power).replace('-','−')
 elif t.startswith('Cumulative percentage'):
  for c in list(e):e.remove(c)
  e.text='Cumulative fraction · equal weight per mouse'
assert before==[e.get('d') for e in root.iter() if e.tag.endswith('path')]
out=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/figMaterials/D0_slip_score_CDF_reference_fraction_log10.svg'
tree.write(out,encoding='utf-8',xml_declaration=True);print(out)
