#!/usr/bin/env python3
"""Finish authorized rerun after extraction, visual review, then notify/transfer.
Does not delete or move canonical outputs. The review gate is written only after
actual plot inspection. All transfer results are retained alongside the archive.
"""
import argparse, datetime, json, subprocess, time
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);a=ap.parse_args();root=a.output.resolve();repo=Path(__file__).resolve().parents[1]
launcher=root/'logs/launcher.log'
print('WAITING_FOR_EXTRACTION',flush=True)
while True:
    text=launcher.read_text(errors='replace') if launcher.exists() else ''
    if 'ALL_TRIALS_ATTEMPTED' in text:break
    if 'MATLAB batch failed with status' in text or 'Traceback (most recent call last)' in text:
        raise SystemExit('Extraction launcher stopped; inspect launcher.log and resume before finalizing')
    time.sleep(15)
print('FINALIZING',flush=True)
cmd=f"addpath('{repo}/tests'); finalizeTaraBeamRerun('{root}')"
subprocess.run(['/Applications/MATLAB_R2024b.app/bin/matlab','-nodisplay','-logfile',str(root/'logs/final_verification.log'),'-batch',cmd],check=True)
subprocess.run(['/usr/bin/python3',str(repo/'tests/reportTaraBeamRerun.py'),str(root)],check=True)
print('READY_FOR_VISUAL_REVIEW',flush=True)
while not (root/'visual_review_passed.json').exists():time.sleep(10)
review=json.loads((root/'visual_review_passed.json').read_text());assert review.get('passed') is True
subprocess.run(['/usr/bin/python3',str(repo/'tests/packageTaraBeamRerun.py'),str(root)],check=True)
archive=json.loads((root/'archive_verification.json').read_text())
summary=json.loads((root/'validation_summary.json').read_text())
plan=json.loads((root/'delivery_plan.json').read_text())
result={'startedUTC':datetime.datetime.now(datetime.timezone.utc).isoformat(),'archive':archive,'phone':{},'air':{}}

def record():
    (root/'delivery_result.json').write_text(json.dumps(result,indent=2))

def send(path,target,label,timeout):
    command=['/opt/homebrew/bin/tailscale','file','cp','--verbose','--update-interval=0',str(path),target+':']
    print('TAIL DROP START',label,flush=True)
    try:
        r=subprocess.run(command,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
        log=r.stdout;state={'target':target,'returncode':r.returncode,'success':r.returncode==0,'log':log}
    except subprocess.TimeoutExpired as e:
        log=e.stdout or '';log=log.decode(errors='replace') if isinstance(log,bytes) else log
        state={'target':target,'returncode':None,'success':False,'error':'transfer timeout','log':log}
    (root/f'taildrop_{label}.log').write_text(log)
    print('TAIL DROP RESULT',label,json.dumps(state),flush=True)
    return state

note=root/plan['noteFilename']
note.write_text('TARA BALANCE-BEAM ANALYSIS FINISHED\n\n'
    f"All {summary['trials']} retained trials have an explicit outcome: {summary['outcomes']}.\n"
    f"Verified row profiles: {summary['profilesVerified']}.\n"
    'The event/trace tables, D0/D14 plots, validation report and ZIP are ready.\n'
    'Please wake your MacBook Air if you want the ZIP now; I will check briefly for it.\n\n'
    f"Canonical results: {root}\nZIP: {archive['archive']}\n"
    f"ZIP bytes: {archive['bytes']}\nSHA-256: {archive['sha256']}\n\n"
    'Original results remain on ShosaiData. See VALIDATION_REPORT.txt for caveats and any discrepancies.\n')
result['phone']=send(note,plan['completionNoteTargetIP'],'phone_completion',120);record()
print('WATCHING_FOR_AIR',flush=True)
deadline=time.monotonic()+600;ready=False
while time.monotonic()<deadline:
    targets=subprocess.run(['/opt/homebrew/bin/tailscale','file','cp','--targets'],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
    targetLines=[line for line in targets.stdout.splitlines() if plan['archiveTargetIP'] in line or '\t'+plan['archiveTarget'] in line]
    result['air']['lastTargetCheck']=targetLines;record()
    if any('offline' not in line.lower() for line in targetLines):ready=True;break
    time.sleep(30)
if ready:
    result['air']=send(Path(archive['archive']),plan['archiveTargetIP'],'air_zip',1800)
else:
    result['air'].update(success=False,error='Air remained offline/unavailable during ten-minute watch; ZIP retained')
result['finishedUTC']=datetime.datetime.now(datetime.timezone.utc).isoformat();record()
print('DELIVERY_FINISHED',json.dumps(result),flush=True)
