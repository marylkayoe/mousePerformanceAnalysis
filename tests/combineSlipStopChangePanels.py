"""Compose existing editable D14 panels without changing measurements or scales."""
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/SLIPS&STOPS'
names=['slip_count_D14_minus_D0_mouse_cage_comparison','slip_magnitude_D14_minus_D0_mouse_cage_comparison','stop_time_percentage_D14_minus_D0_mouse_cage_comparison']
ns='http://www.w3.org/2000/svg';ET.register_namespace('',ns)
w,h,gap=85.45,84.36,7
root=ET.Element('{'+ns+'}svg',{'viewBox':f'0 0 {3*w+2*gap} {h}','width':str(3*w+2*gap),'height':str(h)})
ET.SubElement(root,'{'+ns+'}title').text='D14 minus D0 changes in slip count, total slip-event score, and percentage of time stopped'
ET.SubElement(root,'{'+ns+'}desc').text='Circles: mice; diamonds: cage means; bars: mouse means. Three crossings per mouse. No group pair significant after within-metric Holm adjustment. Time stopped in percentage points. Original panel scales retained.'
canvas=Image.new('RGB',(round((3*w+2*gap)*10),round(h*10)),'white')
for i,name in enumerate(names):
 panel=ET.parse(out/(name+'.svg')).getroot();group=ET.SubElement(root,'{'+ns+'}g',{'id':name,'transform':f'translate({i*(w+gap)} 0)'})
 for el in panel:
  for node in el.iter():
   if 'id' in node.attrib:node.set('id',name+'-'+node.get('id'))
  group.append(el)
 img=Image.open(out/(name+'.png')).convert('RGB');assert img.size==(round(w*10),round(h*10));canvas.paste(img,(round(i*(w+gap)*10),0))
stem=out/'D14_minus_D0_slip_count_score_time_stopped_three_panels'
ET.ElementTree(root).write(stem.with_suffix('.svg'),encoding='utf-8',xml_declaration=True)
canvas.save(stem.with_suffix('.png'))
print(stem)
