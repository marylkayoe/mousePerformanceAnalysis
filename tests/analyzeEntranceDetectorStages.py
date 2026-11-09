"""Descriptive stages, speed strata and event comparisons; no pipeline changes."""
from reviewBeamEntrance import *

key=read(OUT/'review_key.csv');manifest={r['File']:r for r in read(ROOT/'trial_manifest.csv')}
stage={};trialstats=[];pool=[]
def med(a):
    a=np.asarray(a,float);a=a[np.isfinite(a)];return float(np.median(a)) if len(a) else float('nan')
def frac(a):return float(np.mean(a)) if len(a) else float('nan')
def speedbin(v):
    if v==0:return '0'
    if v<=5:return '(0,5]'
    if v<=20:return '(5,20]'
    if v<=40:return '(20,40]'
    if v<=100:return '(40,100]'
    return '>100'
for name in sorted(set(e['File'] for e in key)):
    status=json.loads((OUT/'detector_stages'/(name+'.status.json')).read_text());assert status['success'],name
    rows=read(OUT/'detector_stages'/(name+'.csv'));stage[name]=rows;m=manifest[name]
    inside=[r for r in rows if .9<=float(r['XEntryRightFraction'])<.95]
    sigma=status['baselineSigma'];baseline=status['baselineMedian'];threshold=baseline+2.5*sigma
    ts={'File':name,**{k:m[k] for k in ['Group','Cohort','MouseID','CageID','TrialNumber']},'EntryFrames':len(inside),'BaselineMedian':baseline,'BaselineSigma':sigma,'PreNormalizedThreshold':threshold,'RawEquivalentThresholdAtSpeed1':threshold*np.log1p(1)/160,'RawEquivalentThresholdAtSpeed5':threshold*np.log1p(5)/160,'RawEquivalentThresholdAtSpeed40':threshold*np.log1p(40)/160,'MedianEntrySpeed':med([r['ForwardSpeed'] for r in inside]),'MedianEntryRawWeighted':med([r['RawWeighted'] for r in inside]),'MedianEntryRawUnweighted':med([r['RawUnweighted'] for r in inside]),'EntryZeroSpeedFraction':frac([float(r['ForwardSpeed'])==0 for r in inside]),'EntryNonfiniteBeforeClampFraction':frac([not np.isfinite(float(r['NormalizedBeforeClamp'])) for r in inside]),'EntryAboveThresholdFraction':frac([float(r['FinalTrace'])>2.5 for r in inside])}
    trialstats.append(ts)
    for r in inside:pool.append({**r,**{k:m[k] for k in ['Group','Cohort','MouseID','CageID']},'File':name})
write('detector_stage_trial_summary.csv',trialstats)
def summarize(rows,keys):
    return {**keys,'Frames':len(rows),'Mice':len(set(r['MouseID'] for r in rows)),'Cages':len(set(r['CageID'] for r in rows)),'Trials':len(set(r['File'] for r in rows)),'MedianSpeed':med([r['ForwardSpeed'] for r in rows]),'MedianRawUnweighted':med([r['RawUnweighted'] for r in rows]),'MedianRawWeighted':med([r['RawWeighted'] for r in rows]),'MedianFiniteSpeedMultiplier':med([r['SpeedMultiplier'] for r in rows]),'MedianFiniteSpeedAdjusted':med([r['SpeedAdjusted'] for r in rows]),'MedianFinalTrace':med([r['FinalTrace'] for r in rows]),'FractionAboveThreshold':frac([float(r['FinalTrace'])>2.5 for r in rows]),'FractionNonfiniteBeforeClamp':frac([not np.isfinite(float(r['NormalizedBeforeClamp'])) for r in rows])}
groupstats=[]
for g in ['sedentary','walk','run']:
    a=[r for r in pool if r['Group']==g];groupstats.append(summarize(a,{'Group':g,'Subset':'reviewed trials'}))
    if g=='sedentary':groupstats.append(summarize([r for r in a if r['MouseID']!='TMCS3_S07'],{'Group':g,'Subset':'reviewed excluding TMCS3_S07'}))
write('detector_stage_group_summary.csv',groupstats)
strata=[]
for g in ['sedentary','walk','run']:
    for b in ['0','(0,5]','(5,20]','(20,40]','(40,100]','>100']:
        a=[r for r in pool if r['Group']==g and speedbin(float(r['ForwardSpeed']))==b]
        if a:strata.append(summarize(a,{'Group':g,'SpeedBin':b}))
write('detector_speed_strata.csv',strata)
mouse=[]
for mid in sorted(set(r['MouseID'] for r in pool)):
    a=[r for r in pool if r['MouseID']==mid];mouse.append(summarize(a,{'MouseID':mid,'Group':a[0]['Group'],'Cohort':a[0]['Cohort']}))
write('detector_stage_mouse_summary.csv',mouse)
# Shared raw-motion bins allow descriptive within-amplitude comparisons; frames are not replicates.
cuts=np.quantile([float(r['RawWeighted']) for r in pool],[0,.25,.5,.75,1]);rawstrata=[]
for j in range(4):
    for g in ['sedentary','walk','run']:
        a=[r for r in pool if r['Group']==g and cuts[j]<=float(r['RawWeighted']) and (float(r['RawWeighted'])<cuts[j+1] or j==3)]
        if a:rawstrata.append(summarize(a,{'Group':g,'RawWeightedBin':j+1,'BinLower':cuts[j],'BinUpper':cuts[j+1]}))
write('detector_raw_amplitude_strata.csv',rawstrata)
evstats=[]
for e in key:
    a=[r for r in stage[e['File']] if int(e['StartOriginalFrame'])<=int(r['OriginalFrame'])<=int(e['EndOriginalFrame'])]
    t=next(t for t in trialstats if t['File']==e['File']);obs=json.loads(Path('tests/entranceReviewObservations.json').read_text())[e['ReviewID']]
    evstats.append({**{k:e[k] for k in ['ReviewID','Kind','File','Group','Cohort','MouseID','CageID','StartOriginalFrame','EndOriginalFrame']},'Category':obs[0],'Frames':len(a),'RawUnweightedPeak':max(float(r['RawUnweighted']) for r in a),'RawWeightedPeak':max(float(r['RawWeighted']) for r in a),'RawWeightedMedian':med([r['RawWeighted'] for r in a]),'MedianSpeed':med([r['ForwardSpeed'] for r in a]),'MedianFiniteSpeedMultiplier':med([r['SpeedMultiplier'] for r in a]),'MedianFiniteSpeedAdjusted':med([r['SpeedAdjusted'] for r in a]),'FinalPeak':max(float(r['FinalTrace']) for r in a),'BaselineMedian':t['BaselineMedian'],'BaselineSigma':t['BaselineSigma'],'PreNormalizedThreshold':t['PreNormalizedThreshold']})
write('reviewed_event_detector_stages.csv',evstats)
pairs=[]
for i,a in enumerate(evstats):
    if a['Kind']!='event':continue
    for b in evstats[i+1:]:
        if b['Kind']!='event' or a['Group']==b['Group'] or a['Cohort']!=b['Cohort']:continue
        ratio=a['RawWeightedPeak']/b['RawWeightedPeak'];duration=a['Frames']/b['Frames']
        if .8<=ratio<=1.25 and .5<=duration<=2:
            pairs.append({'ReviewA':a['ReviewID'],'ReviewB':b['ReviewID'],'GroupA':a['Group'],'GroupB':b['Group'],'Cohort':a['Cohort'],'RawPeakRatioAoverB':ratio,'DurationRatioAoverB':duration,'SpeedA':a['MedianSpeed'],'SpeedB':b['MedianSpeed'],'FinalPeakA':a['FinalPeak'],'FinalPeakB':b['FinalPeak'],'SigmaA':a['BaselineSigma'],'SigmaB':b['BaselineSigma'],'Caution':'Similar weighted raw peak and duration, not matched anatomy/full waveform or independent replicates'})
write('comparable_raw_event_pairs.csv',pairs)
# Entire eligible D0 dataset: speed exposure, independent of purposeful visual sample.
all_speed=[]
for t in read(OUT/'D0_entry_exposure_by_trial.csv'):
    full=trace(t['File']);times=np.array([float(r['TimeSeconds']) for r in full]);dts=np.r_[np.diff(times),np.median(np.diff(times))]
    frame_dt={int(r['OriginalFrame']):dt for r,dt in zip(full,dts)}
    rows=[r for r in full if .9<=float(r['XEntryRightFraction'])<.95]
    for b in ['0','(0,5]','(5,20]','(20,40]','(40,100]','>100']:
        r=[r for r in rows if speedbin(float(r['ForwardSpeed']))==b]
        all_speed.append({**{k:t[k] for k in ['File','MouseID','CageID','Group','Cohort']},'SpeedBin':b,'Frames':len(r),'Seconds':sum(frame_dt[int(x['OriginalFrame'])] for x in r),'AboveThresholdFrames':sum(float(x['MovementTrace'])>2.5 for x in r)})
write('all_D0_speed_exposure.csv',all_speed)
all_summary=[]
for g in ['sedentary','walk','run']:
    for b in ['0','(0,5]','(5,20]','(20,40]','(40,100]','>100']:
        a=[r for r in all_speed if r['Group']==g and r['SpeedBin']==b];n=sum(r['Frames'] for r in a)
        all_summary.append({'Group':g,'SpeedBin':b,'Frames':n,'Seconds':sum(r['Seconds'] for r in a),'AboveThresholdFrames':sum(r['AboveThresholdFrames'] for r in a),'AboveThresholdFraction':sum(r['AboveThresholdFrames'] for r in a)/n if n else float('nan'),'ContributingMice':len(set(r['MouseID'] for r in a if r['Frames'])),'ContributingCages':len(set(r['CageID'] for r in a if r['Frames']))})
write('all_D0_speed_summary.csv',all_summary)
bins=list(dict.fromkeys(r['SpeedBin'] for r in all_summary));total=sum(r['Frames'] for r in all_summary)
weights={b:sum(r['Frames'] for r in all_summary if r['SpeedBin']==b)/total for b in bins}
standardized=[]
for g in ['sedentary','walk','run']:
    a=[r for r in all_summary if r['Group']==g]
    standardized.append({'Group':g,'ObservedFrameExceedanceFraction':sum(r['AboveThresholdFrames'] for r in a)/sum(r['Frames'] for r in a),'CommonSpeedDistributionFrameExceedanceFraction':sum(weights[r['SpeedBin']]*r['AboveThresholdFraction'] for r in a)})
write('speed_standardized_frame_exceedance.csv',standardized)
write('speed_standardization_weights.csv',[{'SpeedBin':b,'PooledFrameWeight':w} for b,w in weights.items()])
print('STAGE ANALYSIS COMPLETE',len(stage),'trials',len(pool),'entry frames')
