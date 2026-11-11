"""Editable full-frame centroid overlay for the selected method illustration."""
from pathlib import Path
import csv,base64,math,json,hashlib
from xml.sax.saxutils import escape
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
SOURCE=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/trials/TMCS2_S18_T3_C05_BB_D00_20251022_THT_TRIAL2_gray.mp4.trace.csv')
rows=list(csv.DictReader(SOURCE.open()));index=513
assert int(rows[index]['OriginalFrame'])==1369 and int(rows[index]['TraversalFrame'])==514
# MATLAB integer pixel coordinates identify pixel centres: 1 maps to SVG 0.5.
points=[(float(r['CentroidX'])-.5,float(r['CentroidYOriginal'])-.5) for r in rows]
def path(points):
 commands=[];active=False
 for x,y in points:
  if not(math.isfinite(x) and math.isfinite(y)):active=False;continue
  commands.append(f'{"L" if active else "M"}{x:.6f},{y:.6f}');active=True
 return ' '.join(commands)
background=OUT/'contrast_f1369_traversal_f514.png'
encoded=base64.b64encode(background.read_bytes()).decode()
x,y=points[index];scale=700/1201;length=50/scale
metadata=dict(sourceTrace=str(SOURCE),sourceTraceSHA256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),originalFrame=1369,traversalFrame=514,centroidMatlabXY=[x+.5,y+.5],coordinateConversion='MATLAB pixel centre (1,1) -> SVG pixel centre (0.5,0.5)',trajectory='All 967 saved centroids, unsmoothed; solid through selected frame, dashed afterward; nonfinite samples break paths',millimetersPerPixel=scale,scaleBarMM=50,scaleBarPixels=length,calibrationCaveat='Approximate 700 mm / 1201 pixels from a different reference recording; not independently calibrated for this video',background='Global contrast-stretched source PNG, embedded; overlays remain vector objects')
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1280" height="356" viewBox="0 0 1280 356">
<title>TMCS2_S18 D0 trial 2: centroid at traversal frame 514 / original frame 1369</title>
<metadata>{escape(json.dumps(metadata))}</metadata>
<g id="background"><image id="full-frame-contrast-image" x="0" y="0" width="1280" height="356" xlink:href="data:image/png;base64,{encoded}"/></g>
<g id="centroid-trajectory" fill="none" stroke="black" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
<path id="trajectory-through-frame-514" d="{path(points[:index+1])}"/>
<path id="trajectory-after-frame-514" stroke-dasharray="10 7" d="{path(points[index:])}"/>
</g>
<g id="selected-centroid"><circle id="centroid-frame-514" cx="{x:.6f}" cy="{y:.6f}" r="3.5" fill="white" stroke="none"/></g>
<g id="scale-bar-50mm" fill="black" stroke="black">
<line id="scale-bar-line" x1="{1200-length:.6f}" y1="310" x2="1200" y2="310" stroke-width="3"/>
<text id="scale-bar-label" x="{1200-length/2:.6f}" y="300" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" stroke="none">50 mm</text>
</g>
</svg>'''
p=OUT/'TMCS2_S18_D0_T2_f514_centroid_trajectory.svg';assert not p.exists();p.write_text(svg)
p.with_suffix('.json').write_text(json.dumps(metadata,indent=2)+'\n')
print(p)
