"""Exploratory saved-event review; no pipeline changes. Python: numpy, Pillow, ffmpeg."""
import csv,json,random,subprocess,collections
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw

ROOT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_events_traces_L40_20261106')
SOURCE=Path('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved')
OUT=ROOT.parent/'balance_beam_entry_review_20261107'
def read(p):
    with p.open() as f:return list(csv.DictReader(f))
def write(name,rows):
    if not rows:return
    with (OUT/name).open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def trace(name):return read(ROOT/'trials'/(name+'.trace.csv'))
def run(cmd):
    p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if p.returncode:raise RuntimeError(p.stderr.decode(errors='replace'))
    return p.stdout

def main():
    OUT.mkdir(exist_ok=True)
    for d in ['clips','sequences','traces']:(OUT/d).mkdir(exist_ok=True)
    events=read(ROOT/'events.csv');trials=read(ROOT/'trial_manifest.csv')
    entry=[e for e in events if e['Day']=='0' and e['Type']=='slip' and e['EligibleForPositionPlot']=='1' and .90<=float(e['XEntryRightFraction'])<.95]
    write('all_entry_events.csv',entry)
    exposure=[]
    for t in trials:
        if t['Day']!='0' or t['ValidSlipPlotCrossing']!='1':continue
        tr=trace(t['File']);a=np.array([float(x['XEntryRightFraction']) for x in tr]);inside=(a>=.9)&(a<.95)
        ts=np.array([float(x['TimeSeconds']) for x in tr]);dt=np.r_[np.diff(ts),np.median(np.diff(ts))]
        stopped=np.array([int(x['StopMask']) for x in tr],bool)
        es=[e for e in entry if e['File']==t['File']]
        bar=np.array([float(x['CentroidYOriginal'])+float(x['CentroidYBarRelative']) for x in tr])
        exposure.append({**{k:t[k] for k in ['File','Cohort','MouseID','CageID','Group','TrialNumber','ImageWidth','ImageHeight']},'EntrySeconds':float(dt[inside].sum()),'EntryStoppedSeconds':float(dt[inside&stopped].sum()),'EntryFrames':int(inside.sum()),'EntryEvents':len(es),'CentroidYReferenceRow':float(np.nanmedian(bar))})
    write('D0_entry_exposure_by_trial.csv',exposure)
    selected=[e for e in entry if e['MouseID']=='TMCS3_S07' and e['TrialNumber']=='4']
    # Purposeful variation across cages/cohorts; first and last entry event for each selected mouse.
    mice=['TMCS2_S13','TMCS2_S15','TMCS2_S28','TMCS3_S13',
          'TMCS2_S07','TMCS2_S31','TMCS3_S04','TMCS3_S05',
          'TMCS2_S10','TMCS2_S17','TMCS3_S02','TMCS3_S10']
    other=[]
    for m in mice:
        a=[e for e in entry if e['MouseID']==m]
        other.extend([a[0],a[-1]] if len(a)>1 else a)
    random.Random(701).shuffle(other)
    review=[]
    for i,e in enumerate(selected+other):
        review.append({**e,'ReviewID':('TARGET_%02d'%(i+1)) if i<len(selected) else ('BLIND_%02d'%(i-len(selected)+1)),'Kind':'event'})
    # A non-event window from each of six cohort/group combinations: maximum distance to detected slips.
    for cohort in ['TMCS2','TMCS3']:
        for group in ['sedentary','walk','run']:
            options=[]
            for name in sorted(set(e['File'] for e in review if e['Cohort']==cohort and e['Group']==group)):
                tr=trace(name);ev=[e for e in events if e['File']==name and e['Type']=='slip']
                for x in tr:
                    if not .9<=float(x['XEntryRightFraction'])<.95:continue
                    fr=int(x['OriginalFrame']);distance=min([max(int(e['StartOriginalFrame'])-fr,fr-int(e['EndOriginalFrame']),0) for e in ev],default=9999)
                    options.append((distance,name,fr))
            if options:
                dist,name,fr=max(options)
                t=next(t for t in trials if t['File']==name)
                e={k:'' for k in events[0]};e.update({k:t[k] for k in ['File','Cohort','MouseID','CageID','Group','Day','TrialNumber']})
                half=min(16,max(0,dist-1));e.update(StartOriginalFrame=str(fr-half),EndOriginalFrame=str(fr+half),EventNumber='0',ReviewID='CONTROL_%02d'%(len([r for r in review if r['Kind']=='non_event'])+1),Kind='non_event')
                review.append(e)
    write('review_key.csv',review)
    # All labels shown during review are IDs and original frame numbers, not group or filename.
    for name in sorted(set(e['File'] for e in review),key=lambda s:('TMCS3_S07' not in s,s)):
        rs=[e for e in review if e['File']==name];tr=trace(name);byframe={int(t['OriginalFrame']):t for t in tr}
        bar=int(round(np.nanmedian([float(x['CentroidYOriginal'])+float(x['CentroidYBarRelative']) for x in tr])))
        plans={}
        for e in rs:
            start,end=int(e['StartOriginalFrame']),int(e['EndOriginalFrame'])
            # 12 chronological frames: include before/after and dense sampling for short events.
            frames=np.unique(np.rint(np.linspace(start-12,end+12,12)).astype(int)).tolist()
            plans[e['ReviewID']]=frames
        wanted=sorted(set(f for fs in plans.values() for f in fs))
        def balanced(parts):
            if len(parts)==1:return parts[0]
            mid=len(parts)//2
            return '('+balanced(parts[:mid])+'+'+balanced(parts[mid:])+')'
        expr=balanced(['eq(n,%d)'%(f-1) for f in wanted])
        raw=run(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(SOURCE/name),'-vf',"select='%s',format=gray"%expr,'-fps_mode','passthrough','-f','rawvideo','-'])
        t=next(t for t in trials if t['File']==name);w,h=int(t['ImageWidth']),int(t['ImageHeight'])
        imgs=np.frombuffer(raw,np.uint8).reshape((-1,h,w));assert len(imgs)==len(wanted)
        lookup=dict(zip(wanted,imgs))
        for e in rs:
            rid=e['ReviewID'];fs=plans[rid];start,end=int(e['StartOriginalFrame']),int(e['EndOriginalFrame'])
            canvas=Image.new('RGB',(1200,680),'white');d=ImageDraw.Draw(canvas)
            d.text((10,8),rid+' | chronological source frames; red border = detected interval; fixed right-edge crop',fill='black')
            for j,f in enumerate(fs):
                im=Image.fromarray(lookup[f]).crop((980,max(0,bar-90),1280,min(h,bar+60))).resize((300,150))
                x=(j%4)*300;y=30+(j//4)*175;canvas.paste(im,(x,y));d.text((x+4,y+152),'frame %d'%f,fill='black')
                if e['Kind']=='event' and start<=f<=end:d.rectangle((x,y,x+299,y+149),outline='red',width=2)
            # Trace is saved separately with original frame/time and all requested signals.
            context=[t for t in tr if start-48<=int(t['OriginalFrame'])<=end+48]
            with (OUT/'traces'/(rid+'.csv')).open('w') as f:
                cw=csv.DictWriter(f,fieldnames=list(tr[0]));cw.writeheader();cw.writerows(context)
            d.text((10,565),'Saved detector interval: %d-%d; threshold 2.5; no group labels on review sheets.'%(start,end),fill='black')
            # Small trace panel, capped at 20 for readability (exact values preserved in CSV).
            if context:
                xs=[int(t['OriginalFrame']) for t in context];ys=[float(t['MovementTrace']) for t in context]
                def point(f,v):return (20+1160*(f-xs[0])/max(1,xs[-1]-xs[0]),655-65*min(20,max(0,v))/20)
                d.line([point(xs[0],2.5),point(xs[-1],2.5)],fill='red')
                d.line([point(f,v) for f,v in zip(xs,ys)],fill='black',width=2)
                d.text((20,660),'movementTrace (display 0-20, clipped); red horizontal line = 2.5',fill='black')
            canvas.save(OUT/'sequences'/(rid+'.jpg'),quality=92)
            # Short slow-motion clip includes all original frames; no temporal subsampling.
            a=max(1,start-48);b=end+48
            run(['/opt/homebrew/bin/ffmpeg','-v','error','-y','-i',str(SOURCE/name),'-vf',f'trim=start_frame={a-1}:end_frame={b},setpts=4*(PTS-STARTPTS)', '-r','40','-an','-c:v','libx264','-crf','20','-pix_fmt','yuv420p',str(OUT/'clips'/(rid+'.mp4'))])
        print('prepared',name,flush=True)
    (OUT/'review_design.json').write_text(json.dumps({'settings':{'LOCOTHRESHOLD':40,'SLIPTHRESHOLD':2.5,'MOUSESIZETHRESHOLD':2},'region':[.9,.95],'selection':'13 target trial events; first and last entry event for 12 additional specified mice; six maximally separated non-event controls. Purposeful, not random representative sampling. Blind IDs are shuffled for non-target events; analyst knows target and selection design.','sequenceCropOriginalPixels':[980,'barTop-90',1280,'barTop+60'],'clipSpeed':.25,'reviewEvents':sum(e['Kind']=='event' for e in review)},indent=2))

if __name__=='__main__':main()
