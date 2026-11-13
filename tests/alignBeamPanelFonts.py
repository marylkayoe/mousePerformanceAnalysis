from pathlib import Path
import re,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/font-alignment-20261112'
ns='http://www.w3.org/2000/svg';E.register_namespace('',ns);E.register_namespace('xlink','http://www.w3.org/1999/xlink')
r=E.parse(R/'supplied_assembly.svg').getroot();css=r.find('.//{'+ns+'}style').text
rules=[]
for sels,body in re.findall(r'([^{}]+)\{([^{}]+)\}',css):rules.append(([s.strip().lstrip('.') for s in sels.split(',')],dict((k.strip(),v.strip()) for k,v in re.findall(r'([\w-]+)\s*:\s*([^;]+)',body))))
# Resolve styles before removing collision-prone class names.
for e in r.iter():
 p={}
 for sels,vals in rules:
  if set(e.get('class','').split())&set(sels):p.update(vals)
 p.update(dict(re.findall(r'([\w-]+):([^;]+)',e.get('style',''))))
 for key in ['fill','stroke']:
  m=re.fullmatch(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([.\d]+)\)',p.get(key,''))
  if m:
   a,b,c,alpha=m.groups();p[key]='#%02x%02x%02x'%(int(a),int(b),int(c));p[key+'-opacity']=alpha
 if p:e.set('style',';'.join(k+':'+v for k,v in p.items()))
 e.attrib.pop('class',None)
for e in list(r.iter()):
 if not e.tag.endswith('text'):continue
 text=''.join(e.itertext()).replace(', D0','').replace('pooled D0','pooled')
 tr=e.get('transform','');nums=re.findall(r'[-+]?\d*\.?\d+',tr);x,y=map(float,nums[:2]);rot=re.search(r'rotate\(([^)]+)\)',tr)
 size=5
 if text.startswith('p =') or text in ['Detected stops','Detected events','Bar top','Stops','Slips','Start','Finish','9-frame averages']:size=4.5
 title=any(text.startswith(v) for v in ['Forward speed','Locomoting speed','Time stopped','Slip count','Total slip','Event positions','Tail-motion','Tail slips','Tail motion'])
 if title:size=6
 if text=='Time since traversal start (s)':
  x=145 if y<180 else 168;y=181 if y<180 else 308.82
 if title and y<10:y=8.58
 # Align scatter titles and units to their respective left axes.
 if title and x>395 and y<170:x+=2
 if title and y>190 and x>280:x+=2.37
 if text=='Detected stops':y=8.58
 e.clear();e.set('transform',f'translate({x} {y})'+(f' rotate({rot.group(1)})' if rot and abs(float(rot.group(1)))>1 else ''))
 e.set('style',f'font-family:Arial;font-size:{size}px;fill:#222;letter-spacing:0')
 if text=='Time since traversal start (s)':e.set('text-anchor','middle')
 e.text=text
# Match the lower example block's title baseline to the lower scatter row.
r[13].set('transform','translate(0 12.82)')
# Replace two outlined labels with editable text in the same annotation roles.
def label(parent,x,y,text,size):
 E.SubElement(parent,'{'+ns+'}text',{'x':str(x),'y':str(y),'style':f'font-family:Arial;font-size:{size}px;fill:#222'}).text=text
r[3].clear();label(r[3],26,116,'Under-bar movement during traverse',6)
r[11].clear();label(r[11],213.5,134,'shaded area:',4.5);label(r[11],213.5,141,'event magnitude',4.5)
for parent in r.iter():
 for child in list(parent):
  if child.tag.endswith('style'):parent.remove(child)
r.set('viewBox','0 0 552 326')
E.ElementTree(r).write(R/'panels_fonts_aligned.svg',encoding='utf-8',xml_declaration=True)
assert not any('D0' in ''.join(e.itertext()) for e in r.iter() if e.tag.endswith('text'))
print('Editable Arial hierarchy applied; D0 removed from panel labels; original shape colours embedded locally.')
