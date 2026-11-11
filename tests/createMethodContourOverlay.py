"""Add editable, validated weighting contours to the method frame SVG."""
from pathlib import Path
import json,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
D=json.loads((OUT/'TMCS2_S18_D0_T2_f514_weights.json').read_text())
ns='http://www.w3.org/2000/svg';E.register_namespace('',ns);E.register_namespace('xlink','http://www.w3.org/1999/xlink')
root=E.parse(OUT/'TMCS2_S18_D0_T2_f514_centroid_trajectory.svg').getroot()
root.set('height','408');root.set('viewBox','0 0 1280 408')
def el(tag,attrs,parent=root):return E.SubElement(parent,'{'+ns+'}'+tag,{k:str(v) for k,v in attrs.items()})
el('rect',dict(x=0,y=356,width=1280,height=52,fill='white'))
for field,color in [('slip','#D55E00'),('tail','#0072B2')]:
 g=el('g',{'id':field+'-effective-weight-contours','fill':'none','stroke':color,'stroke-linejoin':'round'})
 paths=D[field+'Contours'];paths=[paths] if isinstance(paths,dict) else paths
 for i,p in enumerate(paths):
  lev=p['level'];xy=p['xy'];d=' '.join(('M' if j==0 else 'L')+f'{x-.5:.4f},{y-.5:.4f}' for j,(x,y) in enumerate(xy))
  el('path',{'id':f'{field}-relative-weight-{int(lev*100)}-segment-{i}','d':d,'stroke-width':{.25:1,.5:1.5,.75:2}[lev],'stroke-dasharray':{.25:'3 3',.5:'7 3',.75:'none'}[lev]},g)
# Exact post-mouse support boundary, independent of probability contours.
g=el('g',{'id':'post-mouse-crop-boundary','fill':'none','stroke':'#0072B2','stroke-width':'.75','stroke-dasharray':'2 5'})
cols=D['tailColumns'];el('rect',{'x':min(cols)-1,'y':0,'width':max(cols)-min(cols)+1,'height':356},g)
# Keep white centroid visible above all contours.
marker=next(x for x in root if x.get('id')=='selected-centroid');root.remove(marker);root.append(marker)
for x,y,text,color in [(20,377,'Orange: slip-motion weights','#D55E00'),(300,377,'Blue: corrected tail-motion weights','#0072B2'),(20,398,'Contours: 25%, 50%, 75% of each field maximum (dotted, dashed, solid); not event thresholds.','#222222'),(670,377,'Fine blue boundary: full post-mouse crop','#0072B2')]:
 el('text',{'x':x,'y':y,'font-family':'Arial, Helvetica, sans-serif','font-size':13,'fill':color}).text=text
p=OUT/'TMCS2_S18_D0_T2_f514_weight_contours.svg';assert not p.exists();E.ElementTree(root).write(p,encoding='utf-8',xml_declaration=True)
notes='''Frame 514/original frame 1369, TMCS2_S18 D0 trial 2. All contour paths are editable SVG objects. Orange: actual spatial slip field p(column)^2 multiplied by the detector's sigmoid row weight, restricted to its under-bar crop. Blue: actual corrected tail spatial field, destination-frame (1-p)^2 after the 0.85 cutoff, with original above-bar cubic weights and corrected below-bar ramp (1 to 2 at half-depth, then 2). Fine blue rectangle is the exact post-mouse crop. Probability is a column occupancy fraction repeated vertically, not an anatomical probability map. These contours show spatial weights, not event thresholds or motion magnitude; slip speed adjustment and temporal/robust normalization are not depicted. Levels are 25/50/75% of each separate field maximum, so colors do not have a shared quantitative scale. Zero padding closes contours at the crop boundary by half-pixel interpolation. Image, centroid and trajectory retain the prior SVG content. Background subtraction/ratio enhancement used upstream in slip measurement is not shown in this raw-image illustration. Full mean background and mask column fractions reconstructed by streaming source video, no retracking. Current-frame centroid and saved probability-weighted motion row profile independently checked. Calibration remains approximate 700/1201 mm per pixel.\n'''
(OUT/'TMCS2_S18_D0_T2_f514_weight_contours_notes.txt').write_text(notes+json.dumps({k:D[k] for k in ['rowProfileMaxError','slipRows','tailBadFrame','slipPeakWeight','tailPeakWeight']},indent=2))
print(p)
