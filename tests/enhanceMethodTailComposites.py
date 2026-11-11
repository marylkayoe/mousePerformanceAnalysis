"""Deterministic global grayscale contrast variants; no background removal."""
from pathlib import Path
import json,base64
import numpy as np
from PIL import Image,ImageDraw,ImageFont
p=Path(__file__).resolve().parents[1]/'BEAMCROSS/DRAFTFIGS/figMaterials/tail_motion_example_stills/nine_frame_averages';out=p/'contrast_variants';out.mkdir(exist_ok=True)
variants=[('original',0,255),('moderate',70,235),('strong',110,225)];W,H=680,820;im=Image.new('RGB',(W,H),'white');d=ImageDraw.Draw(im);font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',13);svg=[f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'];records=[]
for j,n in enumerate([1186,1639]):
 src=p/f'center_emphasized_50pct_original_{n:04d}.png';a=np.asarray(Image.open(src),dtype=float)
 for i,(label,black,white) in enumerate(variants):
  b=np.rint(np.clip((a-black)/(white-black),0,1)*255).astype('uint8');f=out/f'{label}_center_emphasized_f{n}.png';Image.fromarray(b).save(f);x=10+225*i;y=30+410*j;im.paste(Image.fromarray(b),(x,y));title=f'{label.capitalize()} · frame {n}';d.text((x,y-23),title,font=font,fill='black');svg.extend([f'<text x="{x}" y="{y-7}" font-family="Arial" font-size="13">{title}</text>',f'<image x="{x}" y="{y}" width="208" height="356" xlink:href="data:image/png;base64,{base64.b64encode(f.read_bytes()).decode()}"/>']);records.append(dict(frame=n,variant=label,inputBlack=black,inputWhite=white,percentBelowBlack=float(100*np.mean(a<black)),percentAboveWhite=float(100*np.mean(a>white))))
svg.append('</svg>');im.save(out/'contrast_comparison.png');(out/'contrast_comparison.svg').write_text('\n'.join(svg));(out/'contrast_settings.json').write_text(json.dumps(dict(method='output=round(255*clip((input-black)/(white-black),0,1)); identical mapping across both examples for each variant. Applied after temporal compositing. No local adjustment, background removal, sharpening or generative processing.',records=records),indent=2));(out/'README.md').write_text('''# Contrast-enhanced illustrative temporal composites

Original composites preserved in the parent folder. Moderate: input 70–235 mapped linearly to 0–255. Strong: input 110–225 mapped linearly to 0–255. Values outside the interval saturate; the same mapping is applied to both example images. Enhancement follows the 50% centre-frame / 50% nine-frame-mean blend. No spatial processing, background removal, sharpening or generation. These are presentation images only, not inputs to scientific measurements. Both temporal compositing and contrast enhancement should be disclosed in the figure caption. Exact saturation fractions are in contrast_settings.json. Reproduction: tests/enhanceMethodTailComposites.py.
''')
