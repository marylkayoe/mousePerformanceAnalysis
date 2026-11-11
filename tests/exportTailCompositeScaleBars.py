"""Standalone strong temporal composites, embedded raster plus editable scale bar."""
from pathlib import Path
import base64,json
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1];p=root/'BEAMCROSS/DRAFTFIGS/figMaterials/tail_motion_example_stills/nine_frame_averages/contrast_variants'
mm_per_pixel=700/1201;bar=20/mm_per_pixel
for frame in (1186,1639):
 src=p/f'strong_center_emphasized_f{frame}.png';im=Image.open(src).convert('RGB');w,h=im.size;x=16;y=h-20
 svg=f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
<title>Frame {frame}: strong-contrast temporal composite with approximate 20 mm scale bar</title>
<image id="temporal-composite" width="{w}" height="{h}" xlink:href="data:image/png;base64,{base64.b64encode(src.read_bytes()).decode()}"/>
<g id="scale-bar-20mm" fill="#000000">
<rect id="scale-bar" x="{x}" y="{y}" width="{bar:.9f}" height="3"/>
<text id="scale-label" x="{x+bar/2:.9f}" y="{y-6}" text-anchor="middle" font-family="Arial" font-size="11">20 mm</text>
</g></svg>'''
 stem=p/f'strong_center_emphasized_f{frame}_20mm';stem.with_suffix('.svg').write_text(svg)
 # Higher-resolution preview; SVG retains native image and independently editable geometry.
 im=im.resize((w*3,h*3),Image.Resampling.NEAREST);d=ImageDraw.Draw(im);d.rectangle((x*3,y*3,(x+bar)*3,(y+3)*3),fill='black');d.text(((x+bar/2)*3,(y-6)*3),'20 mm',font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',33),anchor='ms',fill='black');im.save(stem.with_suffix('.png'))
(p/'scale_bar_provenance.json').write_text(json.dumps(dict(frames=[1186,1639],scaleBarMM=20,scaleBarPixels=bar,mmPerPixel=mm_per_pixel,calibration='Inherited approximate 700 mm / 1201 pixels from reference recording; not independently calibrated for this trial',images='Existing strong-contrast center-emphasized nine-frame temporal composites embedded unchanged; editable SVG scale bar and text',generator='tests/exportTailCompositeScaleBars.py'),indent=2))
