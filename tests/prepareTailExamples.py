"""Freeze the validated capture code and add a tail-view export before return."""
from pathlib import Path
import json,hashlib,shutil
root=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106')
out=root.parent/'balance_beam_tail_examples_L40_20261109'
dest=out/'instrumentation';dest.mkdir(exist_ok=True)
for group, frames in {'sedentary':[937,1026,1101,1170,1254,1325], 'run':[854,967,1033,1103,1216]}.items():
    (out/(group+'_preview_frames.json')).write_text(json.dumps(frames))
s=(root/'code_snapshot/capturedTaraBeam.m').read_text().replace('function R = capturedTaraBeam','function R = captureTailExample',1)
mark='%% 6 --- Store Results in Output Structure ---';assert s.count(mark)==1
s=s.replace(mark,'exportTailExampleData(T,C);\nreturn; % Stop after exact original tail calculation and additive debug export.\n'+mark,1)
(dest/'captureTailExample.m').write_text(s)
shutil.copy2('tests/exportTailExampleData.m',dest/'exportTailExampleData.m')
(out/'provenance.json').write_text(json.dumps({'validatedSource':str(root/'code_snapshot'),'validatedSourceCommit':'f7d85f52b946a295c035f1ba32a3e1468151b1fd','instrumentation':'Frozen capturedTaraBeam renamed; insert additive export after getTailMotionMetrics, then return. Original code unchanged.','debugFormulaSource':'visualization/displayTailMotionWeightDebug.m','files':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [root/'code_snapshot/capturedTaraBeam.m',dest/'captureTailExample.m',dest/'exportTailExampleData.m',Path('visualization/displayTailMotionWeightDebug.m')]}},indent=2))
