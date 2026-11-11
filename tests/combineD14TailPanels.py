"""Compose existing editable D14 panels without changing measurements or scales."""
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import Image
R=Path(__file__).resolve().parents[1];out=R/'BEAMCROSS/DRAFTFIGS/tail-metrics'
names=['tail_score_D14_mouse_cage_comparison','tail_score_D14_minus_D0_mouse_cage_comparison','tail_height_D14_mouse_cage_comparison','tail_height_D14_minus_D0_mouse_cage_comparison']
ns='http://www.w3.org/2000/svg';ET.register_namespace('',ns)
w,h,gap=85.45,84.36,7
root=ET.Element('{'+ns+'}svg',{'viewBox':f'0 0 {2*w+gap} {2*h+gap}','width':str(2*w+gap),'height':str(2*h+gap)})
ET.SubElement(root,'{'+ns+'}title').text='Tail motion score and motion height: D14 and paired D14 minus D0'
ET.SubElement(root,'{'+ns+'}desc').text='Circles: mice; diamonds: cage means; bars: mouse means. Saved retained-crossing summaries. SED–RUN motion-score change: Holm-adjusted p=0.0238095; other pairs not significant. Original panel scales retained.'
canvas=Image.new('RGB',(round((2*w+gap)*10),round((2*h+gap)*10)),'white')
for i,name in enumerate(names):
 panel=ET.parse(out/(name+'.svg')).getroot();group=ET.SubElement(root,'{'+ns+'}g',{'id':name,'transform':f'translate({(i%2)*(w+gap)} {(i//2)*(h+gap)})'})
 for el in panel:
  for node in el.iter():
   if 'id' in node.attrib:node.set('id',name+'-'+node.get('id'))
  group.append(el)
 img=Image.open(out/(name+'.png')).convert('RGB');assert img.size==(round(w*10),round(h*10));canvas.paste(img,(round((i%2)*(w+gap)*10),round((i//2)*(h+gap)*10)))
stem=out/'tail_motion_height_D14_and_change_four_panels'
ET.ElementTree(root).write(stem.with_suffix('.svg'),encoding='utf-8',xml_declaration=True)
canvas.save(stem.with_suffix('.png'))
print(stem)
