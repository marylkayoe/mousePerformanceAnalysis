"""Editable sample-size/color-key diagrams from retained-trial manifest."""
from pathlib import Path
import csv,collections
ROOT=Path(__file__).resolve().parents[1];P=ROOT/'BEAMCROSS/DRAFTFIGS/figMaterials'
rows=list(csv.DictReader((ROOT/'BEAMCROSS/DRAFTFIGS/analysis-data/trial_manifest.csv').open()))
for detailed in [False,True]:
 a=['<svg xmlns="http://www.w3.org/2000/svg" width="480" height="300" viewBox="0 0 480 300">','<title>Balance-beam groups and retained sample sizes</title>','<rect width="480" height="300" fill="white"/>']
 def text(x,y,s,size=14,color='#232323',anchor='middle'):
  a.append(f'<text x="{x}" y="{y}" font-family="Arial, Helvetica, sans-serif" font-size="{size}" text-anchor="{anchor}" fill="{color}">{s}</text>')
 for j,(day,label) in enumerate([(0,'D0 · pre'),(7,'D7'),(14,'D14 · post')]):
  text(170+j*112,29,label,18)
  if day==7:text(170+j*112,45,'also measured',10,'#666666')
 for i,(group,label,color,nc) in enumerate([('sedentary','SED','#000000',4),('walk','WALK','#00b226',4),('run','RUN','#002bff',7)]):
  y=58+i*59;text(15,y+23,label,17,color,'start');text(15,y+39,f'{nc} cages',11,'#555555','start')
  baseline=None
  for j,day in enumerate([0,7,14]):
   r=[x for x in rows if x['Group']==group and int(x['Day'])==day];ids={x['MouseID'] for x in r};assert len({x['CageID'] for x in r})==nc
   if baseline is None:baseline=ids
   else:assert ids==baseline
   x=121+j*112;fill='white' if day==7 else color;stroke=f' stroke="{color}" stroke-width="1.5" stroke-dasharray="5 3"' if day==7 else ''
   a.append(f'<rect id="{group}-D{day}" x="{x}" y="{y}" width="98" height="47" rx="10" fill="{fill}"{stroke}/>')
   ink=color if day==7 else ('black' if group=='walk' else 'white')
   text(x+49,y+(21 if detailed else 29),f'{len(ids)} mice',15,ink)
   if detailed:text(x+49,y+37,f'{len(r)} crossings',11,ink)
 text(15,251,'Same mice followed across days; 42 mice in 15 cages.',12,anchor='start')
 text(15,270,'3 retained crossings/mouse/day, except one runner at D0 (2).',12,anchor='start')
 text(15,289,'D7 retained for supplementary presentation.',11,'#555555',anchor='start')
 a.append('</svg>');name='sample_sizes_D0_D7_D14'+('_with_crossings' if detailed else '')+'.svg';p=P/name;assert not p.exists();p.write_text('\n'.join(a))
 print(p)
