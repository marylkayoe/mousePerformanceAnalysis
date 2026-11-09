#!/usr/bin/env python3
"""Initialize a new, non-overwriting L40 beam rerun and freeze analysis source.
Timing metadata are prepared one video at a time by the launcher.
"""
import argparse, hashlib, json, re, shutil, subprocess, csv
from pathlib import Path
REPO = Path(__file__).resolve().parents[1]
SOURCE = Path('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved')
DOWNLOADS = Path('/Users/yoe/Downloads')

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def init(out):
    assert SOURCE.is_dir(), 'External source volume unavailable'
    assert not (out/'run_manifest.json').exists(), 'Existing run; use launcher to resume, never reinitialize'
    for d in ['code_snapshot','metadata','trials','logs','plots']: (out/d).mkdir(parents=True,exist_ok=True)
    source_files=list((REPO/'BEAMCROSS').glob('*.m'))+[REPO/'videoImageAnalysis/getMeanFrame.m']
    hashes=[]
    for p in source_files:
        shutil.copy2(p,out/'code_snapshot'/p.name)
        hashes.append({'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size})
    src=(REPO/'BEAMCROSS/BBanalysisSingleFile.m').read_text()
    src=src.replace('function R = BBanalysisSingleFile','function R = capturedTaraBeam')
    src=src.replace("'MAKEDEBUGPLOT',true","'MAKEDEBUGPLOT',false")
    src=src.replace('R.BBvideo              = trackedVideo;','% Instrumentation: do not return video matrices.')
    point='% we calculate where the mouse is most probably present in each frame'
    capture="""% Additive small-data checkpoint; calculations above are unchanged.
C=struct('fileName',fileName,'sourcePath',fullFilePath,'parameters',p.Results);
C.videoReaderFrameRate=frameRate; C.analysisFrameRate=FRAMERATE;
C.originalFrames=mouseFrames(:); C.firstOriginalFrame=firstMouseFrame; C.lastOriginalFrame=lastMouseFrame;
C.decodedVideoSize=size(videoMatrix); C.cropRange=cropRange;
C.barTopCoordOriginal=barTopCoordOriginal; C.barTopCoordAnalysis=barTopCoord;
C.barThickness=barThickness; C.mouseEntersFromRight=mouseEntersFromRight;
C.mouseCentroids=mouseCentroids; C.forwardSpeeds=forwardSpeeds;
stopIntervals=stoppingStartStops; if isempty(stopIntervals), stopIntervals=zeros(0,2); end
C.stoppingFrames=stoppingFrames; C.stoppingStartStops=stopIntervals;
C.summary=struct('mouseCentroids',mouseCentroids,'forwardSpeeds',forwardSpeeds, ...
    'meanSpeed',meanSpeed,'meanSpeedLoco',meanSpeedLoco,'stdSpeedLoco',stdSpeedLoco, ...
    'traverseDuration',traverseDuration,'nStops',size(stoppingStartStops,1), ...
    'stoppingDurations',stopIntervals(:,2)-stopIntervals(:,1)+1);
if isempty(stoppingStartStops), C.summary.stoppingDurations=0; end
C.stage='tracking'; save(getenv('TARA_BEAM_CHECKPOINT'),'C','-v7');
% Release only unused arrays; no numerical calculation is altered.
clear croppedVideo trimmedVideo
"""
    assert src.count(point)==1; src=src.replace(point,capture+'\n'+point)
    point=' T = getTailMotionMetrics'
    capture="""C.movementTrace=movementTrace; C.slipEventStarts=slipEventStarts;
C.slipEventDurations=slipEventDurations; C.slipEventAreas=slipEventAreas; C.slipEventPeaks=slipEventPeaks;
C.summary.nSlips=numel(slipEventStarts); C.summary.slipEventDurations=slipEventDurations;
C.summary.totalSlipMagnitude=sum(slipEventAreas); C.summary.meanSlipAmplitude=mean(slipEventAreas);
C.stage='slips'; save(getenv('TARA_BEAM_CHECKPOINT'),'C','-v7');
clear trackedVideo underBarCroppedVideo mouseMaskMatrix mouseProbMatrix
"""
    assert src.count(point)==1; src=src.replace(point,capture+'\n'+point)
    point='%% --- Generate Plots & Show Videos if Requested ---'
    capture="""C.tailMovementTrace=T.tailMovementTrace;
C.tailMovementTraceAboveBar=T.tailMovementTraceAboveBar;
C.tailMovementTraceUnderBar=T.tailMovementTraceUnderBar; C.tailBadFrames=T.badFrames;
C.verticalMotionTrace=T.verticalMotionTrace;
C.summary=R; C.stage='complete'; save(getenv('TARA_BEAM_CHECKPOINT'),'C','-v7');
C.rowMotion=computeBeamRowProfiles(T,mouseCentroids,barTopCoordOriginal,barThickness);
if strcmp(getenv('TARA_BEAM_DEBUG'),'1'), auditBeamRowProfiles(T,C,fileName); end
C.summary=R; C.stage='complete'; R.capture=C;
"""
    assert src.count(point)==1;src=src.replace(point,capture+'\n'+point)
    (out/'code_snapshot/capturedTaraBeam.m').write_text(src)
    grouping=json.loads((out/'grouping_metadata.json').read_text())
    assert grouping['sampleIDs_original'][:33]==[f'S{i:02d}' for i in range(1,34)]
    assert grouping['sampleIDs_original'][33:]==[f'S{i:02d}' for i in range(1,16)]
    key={(('TMCS2_' if i<33 else 'TMCS3_')+mouse):label for i,(mouse,label) in enumerate(zip(grouping['sampleIDs_original'],grouping['groupLabels']))}
    corroboration=DOWNLOADS/'TMCS2-3_BW_analysis_package/TMCS2-3_BW_mouseSlopes.csv'
    bw={r['mouseId']:r for r in csv.DictReader(corroboration.open())}
    files=[]
    for i,p in enumerate(sorted(SOURCE.glob('*.mp4')),1):
        m=re.fullmatch(r'(TMCS\d+)_S(\d+)_T(\d+)_C(\d+)_BB_D(\d+)_(\d+)_THT_TRIAL(\d+)_gray.mp4',p.name)
        assert m,p.name
        cohort,mouse,tail,cage,day,date,trial=m.groups()
        identity=f'{cohort}_S{int(mouse):02d}'
        matches=[(k,v) for k,v in key.items() if k==identity]
        if not matches:
            matches=[(k,v) for k,v in key.items() if k.replace('_S0','_S')==identity.replace('_S0','_S')]
        assert len(matches)==1, (identity,list(key)[:5])
        label=matches[0][1]; group={'S':'sedentary','W':'walk','R':'run','Sedentary':'sedentary','Walking':'walk','Running':'run','SED':'sedentary','WALK':'walk','RUN':'run','Sed':'sedentary','Walk':'walk','Run':'run','sedentary':'sedentary','walk':'walk','run':'run'}.get(label)
        assert group,(identity,label)
        assert identity in bw and {'Sed':'sedentary','Walk':'walk','Run':'run'}[bw[identity]['group']]==group, ('Group corroboration failed',identity)
        assert bw[identity]['cageId']==f'{cohort}_C{int(cage):02d}'
        files.append(dict(index=i,file=p.name,sourcePath=str(p),cohort=cohort,mouseID=identity,
            tailID=int(tail),cageID=f'{cohort}_C{int(cage):02d}',group=group,groupOriginal=label,
            day=int(day),recordingDate=date,trialNumber=int(trial),bytes=p.stat().st_size))
    refs=[{'path':str(corroboration),'sha256':sha(corroboration),'bytes':corroboration.stat().st_size}]
    for name in ['BB_values_261105_2.mat','BB_fileNames_261105_2.mat','BB_fieldNames_261105_2.mat','groupingMetadata_TMCS2_TMCS3.mat']:
        p=DOWNLOADS/name; refs.append({'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size})
    manifest=dict(sourceRoot=str(SOURCE),outputRoot=str(out),repoRoot=str(REPO),
        gitCommit=subprocess.check_output(['git','-C',str(REPO),'rev-parse','HEAD'],text=True).strip(),
        initialWorktree=subprocess.check_output(['git','-C',str(REPO),'status','--short'],text=True),
        code=hashes,referenceFiles=refs,files=files,
        parameters=dict(LOCOTHRESHOLD=40,SLIPTHRESHOLD=2.5,MOUSESIZETHRESHOLD=2,EXCLUDE_STOPPING_FRAMES=False,MAKEPLOT=False,SHOWVIDEOS=False),
        parameterProvenance='User confirmed three thresholds; other defaults retained, Tara version/other settings unverified')
    (out/'run_manifest.json').write_text(json.dumps(manifest,indent=2))
    print('Initialized',len(files),'trials; groups:',sorted(set(f['group'] for f in files)),flush=True)

def timing(out, row):
    dest=out/'metadata'/f"{row['file']}.json"
    if dest.exists():return
    p=Path(row['sourcePath'])
    if not p.is_file():
        dest.write_text(json.dumps(dict(file=row['file'],error='Source missing')));return
    d=json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe','-v','error','-select_streams','v:0',
        '-show_entries','stream=width,height,r_frame_rate,avg_frame_rate,nb_frames,start_time,duration:frame=best_effort_timestamp_time',
        '-of','json',str(p)]))
    timestamps=[float(f['best_effort_timestamp_time']) for f in d.pop('frames')]
    assert timestamps and all(b>a for a,b in zip(timestamps,timestamps[1:]))
    d.update(file=row['file'],timestampsSeconds=timestamps,sha256=sha(p),bytes=p.stat().st_size)
    temporary=dest.with_suffix('.pending.json')
    temporary.write_text(json.dumps(d,separators=(',',':')))
    temporary.replace(dest)
    print('TIMING_READY',row['index'],row['file'],flush=True)

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);ap.add_argument('--timing',nargs=2,type=int)
    a=ap.parse_args()
    if a.timing:
        rows=json.loads((a.output/'run_manifest.json').read_text())['files']
        for row in rows[a.timing[0]-1:a.timing[1]]:timing(a.output,row)
    else:init(a.output)
