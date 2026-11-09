"""Create non-invasive instrumented frozen copies for detector-stage diagnostics."""
from pathlib import Path
import hashlib,json
root=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106/code_snapshot')
out=root.parents[1]/'balance_beam_entry_review_20261107'/'detector_instrumentation'
out.mkdir(exist_ok=True)
s=(root/'computeWeightedMovementTrace.m').read_text()
s=s.replace('forwardSpeeds = forwardSpeeds(:);','global ENTRANCE_DETECTOR_AUDIT;\nforwardSpeeds = forwardSpeeds(:);',1)
s=s.replace('videoDiff = abs(diff(videoDouble, 1, 3));',"videoDiff = abs(diff(videoDouble, 1, 3));\nif normalizeSpeed, ENTRANCE_DETECTOR_AUDIT=struct(); ENTRANCE_DETECTOR_AUDIT.rawUnweighted=[0; squeeze(sum(sum(videoDiff,1),2))]; end",1)
s=s.replace('movementTrace = [0; movementTrace];','movementTrace = [0; movementTrace];\nif normalizeSpeed, ENTRANCE_DETECTOR_AUDIT.rawWeighted=movementTrace; end',1)
s=s.replace('movementTrace = smooth(movementTrace, smoothFactor);',"if normalizeSpeed, ENTRANCE_DETECTOR_AUDIT.speedMultiplier=speedWindow./logSpeeds; ENTRANCE_DETECTOR_AUDIT.speedAdjusted=movementTrace; end\nmovementTrace = smooth(movementTrace, smoothFactor);\nif normalizeSpeed, ENTRANCE_DETECTOR_AUDIT.smoothed=movementTrace; ENTRANCE_DETECTOR_AUDIT.smoothFactor=smoothFactor; end",1)
s=s.replace('\nnormMovementTrace = (movementTrace - medVal) / sigma_base;',"\nnormMovementTrace = (movementTrace - medVal) / sigma_base;\nif normalizeSpeed, ENTRANCE_DETECTOR_AUDIT.baselineMedian=medVal; ENTRANCE_DETECTOR_AUDIT.baselineSigma=sigma_base; ENTRANCE_DETECTOR_AUDIT.normalizedBeforeClamp=normMovementTrace; ENTRANCE_DETECTOR_AUDIT.baselineFiniteNonStopCount=sum(finiteMask & ~stoppingFrames); end",1)
s=s.replace('normMovementTrace(isnan(normMovementTrace)) = 0;',"normMovementTrace(isnan(normMovementTrace)) = 0;\nif normalizeSpeed, ENTRANCE_DETECTOR_AUDIT.finalTrace=normMovementTrace; end",1)
(out/'computeWeightedMovementTrace.m').write_text(s)
s=(root/'BBanalysisSingleFile.m').read_text().replace('BBanalysisSingleFile(', 'auditEntranceSingleFile(',1).replace("'MAKEDEBUGPLOT',true","'MAKEDEBUGPLOT',false")
marker=' %% 5b - tail motion.'
assert marker in s
s=s.replace(marker,"\nR.auditForwardSpeeds=forwardSpeeds; R.auditCentroids=mouseCentroids; R.auditMouseFrames=mouseFrames; R.auditMovement=movementTrace; R.auditStarts=slipEventStarts; R.auditDurations=slipEventDurations;\nreturn; % Diagnostic capture ends after original slip calculation; no tail analysis/video output.\n"+marker,1)
(out/'auditEntranceSingleFile.m').write_text(s)
(out/'manifest.json').write_text(json.dumps({'baseSnapshot':str(root),'modifications':['Add side-effect copies of scalar/per-frame intermediate detector stages; no arithmetic changed.','Disable unconditional debug plot.','Return after original slip detection; do not run tail stage or return full video matrices.'],'sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*.m')}},indent=2))
print(out)
