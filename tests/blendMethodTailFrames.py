"""Blend central tail crops with existing nine-frame averages for illustration."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import base64,json
root=Path(__file__).resolve().parents[1]
p=root/'BEAMCROSS/DRAFTFIGS/figMaterials/tail_motion_example_stills';out=p/'nine_frame_averages';font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',12)
im=Image.new('RGB',(900,410),'white');d=ImageDraw.Draw(im);svg=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="900" height="410" viewBox="0 0 900 410">'];records=[]
for j,(k,orig,label) in enumerate([(331,1186,'Raised'),(784,1639,'Lowered')]):
 frames=[np.asarray(Image.open(out/f'crop_traversal_{t:04d}_original_{t+855:04d}.png'),dtype=float) for t in range(k-4,k+5)]
 avg=np.mean(frames,axis=0);blend=.5*frames[4]+.5*avg
 bfile=out/f'center_emphasized_50pct_original_{orig:04d}.png';Image.fromarray(np.rint(blend).astype('uint8')).save(bfile)
 for i,(file,title) in enumerate([(out/f'average9_center_original_{orig:04d}.png',label+': uniform average'),(bfile,label+': centre emphasized')]):
  x=10+(j*2+i)*225;a=Image.open(file);im.paste(a,(x,30));d.text((x,5),title,font=font,fill='black');svg.extend([f'<text x="{x}" y="18" font-family="Arial" font-size="12">{title}</text>',f'<image x="{x}" y="30" width="208" height="356" xlink:href="data:image/png;base64,{base64.b64encode(file.read_bytes()).decode()}"/>'])
 records.append(dict(originalFrame=orig,output=str(bfile),centerWeight=5/9,eachOtherFrameWeight=1/18))
svg.append('</svg>');stem=out/'uniform_vs_center_emphasized';stem.with_suffix('.png').parent.mkdir(exist_ok=True);im.save(stem.with_suffix('.png'));stem.with_suffix('.svg').write_text('\n'.join(svg));stem.with_suffix('.json').write_text(json.dumps(dict(formula='0.5*centre + 0.5*mean(nine original crops); average recomputed before rounding',interpretation='Illustrative composite, not a single video frame; no change to measured traces',records=records),indent=2))
with (out/'README.md').open('a') as f:f.write('\n## Centre-emphasized illustration\n\n`center_emphasized_50pct_original_*.png` uses 50% centre frame plus 50% nine-frame mean. Effective weights: centre 5/9, each of the eight other frames 1/18. Mean recomputed from the original crops before final uint8 rounding. Identical weights and intensity settings for both examples. These are illustrative temporal composites, not single source frames; measurements unchanged. Reproduce with tests/blendMethodTailFrames.py.\n')
