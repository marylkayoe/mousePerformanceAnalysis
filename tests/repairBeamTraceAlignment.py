from pathlib import Path
import xml.etree.ElementTree as E
import re,runpy
root=Path(__file__).resolve().parents[1];runpy.run_path(str(root/'tests/alignBeamPanelFonts.py'))
R=root/'BEAMCROSS/DRAFTFIGS/font-alignment-20261112';ns='http://www.w3.org/2000/svg';E.register_namespace('',ns)
r=E.parse(R/'panels_fonts_aligned.svg').getroot()
for name,ident,y0,y1 in [('under_bar_motion_slips_downward_areas','saved-normalized-under-bar-motion',90.43,166.99),('forward_speed_stops','raw-saved-speed-mm-per-second',13.41,90.12)]:
 s=E.parse(root/f'BEAMCROSS/DRAFTFIGS/figMaterials/TMCS2_S18_D0_T2_{name}.svg').getroot();source=next(e for e in s.iter() if e.get('id')==ident);target=next(e for e in r.iter() if e.get('id')==ident)
 d=source.get('d');pairs=re.findall(r'([ML])\s*([-\d.]+),([-\d.]+)',d);assert len(pairs)>900
 target.set('d',' '.join(f'{cmd}{22.09+(float(x)-90)*244.99/800:.7f},{y0+(float(y)-55)*(y1-y0)/250:.7f}' for cmd,x,y in pairs))
# Align top grid and stop bands to the lower axis; preserve their temporal locations.
for e in r[1].iter():
 if e.get('id')=='raw-saved-speed-mm-per-second':continue
 for a in ['x','x1','x2']:
  if a in e.attrib:e.set(a,str(22.09+(float(e.get(a))-22.1)*244.99/245.46))
 if e.tag.endswith('rect') and 'width' in e.attrib:e.set('width',str(float(e.get('width'))*244.99/245.46))
# Check each event marker against recovered absolute trace vertices.
p=next(e for e in r.iter() if e.get('id')=='saved-normalized-under-bar-motion');pts=[tuple(map(float,v)) for v in re.findall(r'[ML]([-\d.]+),([-\d.]+)',p.get('d'))]
for e in r.iter():
 if e.get('id','').startswith('slip-peak-'):
  x,y=float(e.get('cx')),float(e.get('cy'));xx,yy=min(pts,key=lambda p:abs(p[0]-x));assert abs(xx-x)<.02 and abs(yy-y)<.02,(e.get('id'),xx-x,yy-y)
E.ElementTree(r).write(R/'panels_fonts_aligned.svg',encoding='utf-8',xml_declaration=True)
print('All eight event peaks match restored trace within0.02 SVG units; both left axes share x22.09..267.08.')
