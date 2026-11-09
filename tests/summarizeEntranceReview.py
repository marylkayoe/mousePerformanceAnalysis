"""Join recorded visual observations to identities; exposure and camera checks."""
from reviewBeamEntrance import *
import hashlib,shutil

key=read(OUT/'review_key.csv');obs=json.loads(Path('tests/entranceReviewObservations.json').read_text())
annot=[]
for e in key:
    rid=e['ReviewID'];a,b=int(e['StartOriginalFrame']),int(e['EndOriginalFrame'])
    tr=trace(e['File']);seg=[t for t in tr if a<=int(t['OriginalFrame'])<=b]
    x=np.array([float(t['CentroidX']) for t in seg]);movement=np.array([float(t['MovementTrace']) for t in seg]);speed=np.array([float(t['ForwardSpeed']) for t in seg])
    annot.append({**{k:e[k] for k in ['ReviewID','Kind','File','Cohort','MouseID','CageID','Group','TrialNumber','EventNumber','StartOriginalFrame','EndOriginalFrame']},'VisualCategory':obs[rid][0],'Observation':obs[rid][1],'HindPawSlipAssessment':obs[rid][2],
    'EntranceContact':'not established; entrance platform outside field; marker proximity is not proof of contact',
    'TrackingCropAssessment':'no obvious discontinuity in source sequence; fixed review crop, not pipeline crop; tail mask not a slip-validity mask',
    'PeakMovementTrace':float(movement.max()),'MedianForwardSpeed':float(np.nanmedian(speed)),'StoppedFrameFraction':sum(int(t['StopMask']) for t in seg)/len(seg),'TailBadFrameFraction':sum(int(t['TailBadFrame']) for t in seg)/len(seg),'MaxCentroidXStepPixels':float(np.nanmax(abs(np.diff(x)))) if len(x)>1 else 0,'MissingCentroidSamples':sum(not np.isfinite(v) for v in x),
    'Sequence':'sequences/'+rid+'.jpg','Clip':'clips/'+rid+'.mp4','ClipFirstOriginalFrame':a-48,'ClipLastOriginalFrame':b+48,'Trace':'traces/'+rid+'.csv','ReviewMethod':'chronological 12-frame source sequence plus saved trace; slow-motion clip supplied for playback; not independent manual ground truth'})
write('review_observations.csv',annot)
counts=[]
for g in ['sedentary','walk','run']:
    r=[e for e in annot if e['Group']==g];ev=[e for e in r if e['Kind']=='event']
    counts.append({'Group':g,'ReviewedMice':len(set(e['MouseID'] for e in r)),'ReviewedCages':len(set(e['CageID'] for e in r)),'ReviewedTrials':len(set(e['File'] for e in r)),'ReviewedEvents':len(ev),'NonEventWindows':len(r)-len(ev),'Cohorts':';'.join(sorted(set(e['Cohort'] for e in r))),'ApparentHindPawSlips':sum(e['HindPawSlipAssessment']=='apparent' for e in ev),'PossibleHindPawSlips':sum(e['HindPawSlipAssessment']=='possible' for e in ev),'Uncertain':sum(e['HindPawSlipAssessment']=='uncertain' for e in ev),'NoClearHindSlip':sum(e['HindPawSlipAssessment']=='no_clear_hind_slip' for e in ev)})
write('review_coverage.csv',counts);print(counts,flush=True)
exposure=read(OUT/'D0_entry_exposure_by_trial.csv')
def aggregate(rows,label):
    seconds=sum(float(r['EntrySeconds']) for r in rows);n=sum(int(r['EntryEvents']) for r in rows)
    return {'Subset':label,'Trials':len(rows),'Mice':len(set(r['MouseID'] for r in rows)),'Cages':len(set(r['CageID'] for r in rows)),'Events':n,'EntrySeconds':seconds,'StoppedEntrySeconds':sum(float(r['EntryStoppedSeconds']) for r in rows),'EventsPerSecond':n/seconds if seconds else float('nan'),'EventsPerCrossing':n/len(rows)}
summary=[]
for g in ['sedentary','walk','run']:
    rows=[r for r in exposure if r['Group']==g];summary.append(aggregate(rows,g))
    for c in ['TMCS2','TMCS3']:summary.append(aggregate([r for r in rows if r['Cohort']==c],g+' '+c))
summary.append(aggregate([r for r in exposure if r['Group']=='sedentary' and r['MouseID']!='TMCS3_S07'],'sedentary excluding TMCS3_S07'))
summary.append(aggregate([r for r in exposure if r['Group']=='sedentary' and not(r['MouseID']=='TMCS3_S07' and r['TrialNumber']=='4')],'sedentary excluding S07 trial4'))
write('exposure_summary.csv',summary)
mouse=[]
for mid in sorted(set(r['MouseID'] for r in exposure)):
    rows=[r for r in exposure if r['MouseID']==mid];mouse.append({**aggregate(rows,mid),'Group':rows[0]['Group'],'Cohort':rows[0]['Cohort'],'CageID':rows[0]['CageID']})
write('exposure_by_mouse.csv',mouse)
camera=[];thumbs=[]
for j,t in enumerate(exposure):
    tr=trace(t['File']);inside=[r for r in tr if .9<=float(r['XEntryRightFraction'])<.95]
    if not inside:continue
    row=inside[len(inside)//2];fr=int(row['OriginalFrame']);w,h=int(t['ImageWidth']),int(t['ImageHeight'])
    raw=run(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(SOURCE/t['File']),'-vf',"select='eq(n,%d)',format=gray"%(fr-1),'-frames:v','1','-f','rawvideo','-'])
    im=np.frombuffer(raw,np.uint8).reshape(h,w)
    roi=im[40:140,500:900]
    camera.append({**{k:t[k] for k in ['File','Cohort','MouseID','CageID','Group','ImageWidth','ImageHeight','CentroidYReferenceRow']},'OriginalFrame':fr,'BackgroundROIMean':float(roi.mean()),'BackgroundROIStd':float(roi.std()),'ROI':'zero-based x500:900 y40:140; single middle entry frame'})
    if t['File'] in set(e['File'] for e in key):
        tile=Image.new('RGB',(640,210),'white');tile.paste(Image.fromarray(im).resize((640,178)),(0,0));ImageDraw.Draw(tile).text((4,181),t['MouseID']+' '+t['Group']+' T'+t['TrialNumber']+' frame '+str(fr),fill='black');thumbs.append(tile)
    if j%20==0:print('camera',j+1,flush=True)
write('camera_checks.csv',camera)
cam_summary=[]
for c in ['TMCS2','TMCS3']:
    for g in ['sedentary','walk','run']:
        a=[r for r in camera if r['Group']==g and r['Cohort']==c];v=[r['BackgroundROIMean'] for r in a];bar=[float(r['CentroidYReferenceRow']) for r in a]
        cam_summary.append({'Cohort':c,'Group':g,'TrialsWithEntry':len(a),'BackgroundMeanMedian':float(np.median(v)),'BackgroundMeanMin':min(v),'BackgroundMeanMax':max(v),'CentroidYReferenceMin':min(bar),'CentroidYReferenceMax':max(bar)})
write('camera_summary.csv',cam_summary)
for page in range((len(thumbs)+5)//6):
    canvas=Image.new('RGB',(1280,630),'white')
    for k,tile in enumerate(thumbs[page*6:(page+1)*6]):canvas.paste(tile,((k%2)*640,(k//2)*210))
    canvas.save(OUT/('framing_examples_%02d.jpg'%(page+1)),quality=90)
# Clip integrity: original frame mapping and expected 4x slowed encoded duration.
checks=[]
for e in annot:
    p=OUT/e['Clip'];d=json.loads(run(['/opt/homebrew/bin/ffprobe','-v','error','-show_entries','stream=nb_frames,r_frame_rate,width,height:format=duration','-of','json',str(p)]))
    n=e['ClipLastOriginalFrame']-e['ClipFirstOriginalFrame']+1;actual=int(d['streams'][0]['nb_frames']);assert actual==n,(p,n,actual)
    checks.append({'ReviewID':e['ReviewID'],'SourceFrames':n,'ClipFrames':actual,'ClipFrameRate':d['streams'][0]['r_frame_rate'],'FrameCountMatch':True})
write('clip_validation.csv',checks)
for f in ['reviewBeamEntrance.py','summarizeEntranceReview.py','entranceReviewObservations.json']:shutil.copy2(Path('tests')/f,OUT/f)
(OUT/'provenance.json').write_text(json.dumps({'codeCommit':'f7d85f52b946a295c035f1ba32a3e1468151b1fd','originalCodeChanged':False,'sourceRoot':str(SOURCE),'recoveredResults':str(ROOT),'reviewRoot':str(OUT),'sourceResultsHashes':{f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in ['events.csv','trial_manifest.csv','run_manifest.json']},'scripts':{f:hashlib.sha256((OUT/f).read_bytes()).hexdigest() for f in ['reviewBeamEntrance.py','summarizeEntranceReview.py','entranceReviewObservations.json']}},indent=2))
print('DONE',flush=True)
