"""Display active tail-weight support and corrected whole-motion row ramp."""
from pathlib import Path
import json,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1];P=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials';D=json.loads((P/'TMCS2_S18_D0_T2_f514_weights.json').read_text())
ns='http://www.w3.org/2000/svg';E.register_namespace('',ns);E.register_namespace('xlink','http://www.w3.org/1999/xlink')
r=E.parse(P/'TMCS2_S18_D0_T2_f514_schematic_slip_depth.svg').getroot()
for g in list(r):
 if g.get('id') in ['tail-effective-weight-contours','post-mouse-crop-boundary']:r.remove(g)
def el(tag,a,parent=r):return E.SubElement(parent,'{'+ns+'}'+tag,{k:str(v) for k,v in a.items()})
active=[c for c,p in zip(D['tailColumns'],D['tailNoMouseProbability']) if p>0]
assert active==list(range(min(active),max(active)+1))
x=min(active)-1;right=max(active);h=356;top=D['barTop'];firstBelow=top+D['barThickness']
g=el('g',{'id':'nonzero-tail-measurement-support','fill':'none','stroke':'#0072B2','stroke-width':'1.5'})
el('rect',{'id':'active-tail-columns-551-through-682','x':x,'y':.5,'width':right-x,'height':355},g)
weights=[]
for row in range(1,h+1):
 if row<=top:w=((row-1)/(top-1))**3
 elif row<firstBelow:w=1.
 else:w=1+min(2*(row-firstBelow)/(h-firstBelow),1)
 weights.append(w)
bar=el('g',{'id':'whole-motion-vertical-weight-colorbar','stroke':'none'})
for j,w in enumerate(weights):
 t=w/2;rgb=tuple(round(a+(b-a)*t) for a,b in zip((245,250,255),(0,75,145)))
 el('rect',{'id':f'vertical-weight-row-{j+1}','x':right+4,'y':j,'width':9,'height':1,'fill':'#%02x%02x%02x'%rgb},bar)
for value,y in [('0',12),('1',top),('2',(firstBelow+h)/2)]:
 el('text',{'x':right+18,'y':y,'font-family':'Arial, Helvetica, sans-serif','font-size':12,'fill':'#005080'}).text=value
for t in r.iter('{'+ns+'}text'):
 if t.text=='Blue: corrected tail-motion weights':t.text='Blue: active tail-motion measurement region'
 elif t.text=='Fine blue boundary: full post-mouse crop':t.text='Outer color bar: whole-motion vertical weight (0–2)'
 elif t.text and t.text.startswith('Orange depth is schematic'):t.text='Orange depth is schematic. Blue excludes zero-weight body columns; image differences here can include non-tail motion.'
meta={'originalFrame':1369,'traversalFrame':514,'activeColumnsMatlabInclusive':[min(active),max(active)],'originalPostMouseCropColumns':[min(D['tailColumns']),max(D['tailColumns'])],'supportDefinition':'Destination-frame noMouseProbability >=0.85; no threshold on observed motion magnitude','columnWeightSquaredRange':[min(v*v for v in D['tailNoMouseProbability'] if v>0),max(v*v for v in D['tailNoMouseProbability'])],'verticalWeight':'Above-bar cubic to 1 at barTop; 1 through beam; below-bar linear to 2 at half-depth then constant 2','firstBelowRow':firstBelow,'halfDepthOriginalRow':(firstBelow+h)/2,'colorbarDefinition':'Vertical factor only; final pixel weight also multiplies column probability squared','interpretation':'Measurement support, not anatomical tail segmentation or a contour of detected movement','priorOverlaysPreserved':True}
el('metadata',{'id':'active-tail-region-provenance'}).text=json.dumps(meta)
out=P/'TMCS2_S18_D0_T2_f514_tail_region_weightbar.svg';assert not out.exists();E.ElementTree(r).write(out,encoding='utf-8',xml_declaration=True)
out.with_suffix('.json').write_text(json.dumps(meta,indent=2))
assert weights[top-1]==1 and weights[firstBelow-1]==1 and weights[-1]==2
print(out)
