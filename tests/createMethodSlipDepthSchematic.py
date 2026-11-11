"""Display slip column weights as schematic depth; does not change analysis."""
from pathlib import Path
import json,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1];P=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
d=json.loads((P/'TMCS2_S18_D0_T2_f514_weights.json').read_text())
ns='http://www.w3.org/2000/svg';E.register_namespace('',ns);E.register_namespace('xlink','http://www.w3.org/1999/xlink')
r=E.parse(P/'TMCS2_S18_D0_T2_f514_weight_contours.svg').getroot()
old=next(g for g in r if g.get('id')=='slip-effective-weight-contours');i=list(r).index(old);r.remove(old)
weights=[float(p)**2 for p in d['mouseProbability']];peak=max(weights)
# Approximate visible body height, excluding the raised tail: ~55 original pixels.
height=55.;baseline=d['barTop']+d['barThickness']-1
segments=[];segment=[]
for col,v in enumerate(weights):
 if v>0:segment.append((col+.5,baseline+height*v/peak))
 elif segment:segments.append(segment);segment=[]
if segment:segments.append(segment)
g=E.Element('{'+ns+'}g',{'id':'schematic-slip-weight-depth','fill':'#D55E00','fill-opacity':'0.12','stroke':'#D55E00','stroke-width':'1.5','stroke-linejoin':'round'})
for j,pts in enumerate(segments):
 path=f'M{pts[0][0]:.4f},{baseline:.4f} '+' '.join(f'L{x:.4f},{y:.4f}' for x,y in pts)+f' L{pts[-1][0]:.4f},{baseline:.4f} Z'
 E.SubElement(g,'{'+ns+'}path',{'id':f'relative-slip-weight-depth-{j}','d':path})
r.insert(i,g)
for t in r.iter('{'+ns+'}text'):
 if t.text=='Orange: slip-motion weights':t.text='Orange: relative slip weighting'
 if t.text and t.text.startswith('Contours:'):t.text='Orange depth is schematic (maximum ~mouse body height); blue contours: 25%, 50%, 75% of tail-weight maximum.'
meta={'interpretation':'Schematic encoding of squared mouse-column probability; not an actual vertical sampling boundary','depthFormula':'55 * p(x)^2 / max(p(x)^2) pixels','maximumDepthPixels':height,'heightBasis':'Approximate visible mouse body height above beam, visually estimated; excludes tail','baselineSvgY':baseline,'sourceProbability':'TMCS2_S18_D0_T2_f514_weights.json','noAnalysisChanges':True}
E.SubElement(r,'{'+ns+'}metadata',{'id':'slip-depth-schematic-provenance'}).text=json.dumps(meta)
out=P/'TMCS2_S18_D0_T2_f514_schematic_slip_depth.svg';assert not out.exists();E.ElementTree(r).write(out,encoding='utf-8',xml_declaration=True)
out.with_suffix('.json').write_text(json.dumps(meta,indent=2))
assert abs(max(y-baseline for pts in segments for x,y in pts)-55)<1e-8
print(out)
