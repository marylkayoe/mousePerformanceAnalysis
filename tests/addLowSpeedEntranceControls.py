"""Additional non-event controls with positive speed <=5 px/s at center."""
from reviewBeamEntrance import *
key=read(OUT/'review_key.csv');events=read(ROOT/'events.csv')
if any(r['ReviewID'].startswith('LOW_CONTROL') for r in key):raise SystemExit('Controls already prepared')
added=[];availability=[]
for cohort in ['TMCS2','TMCS3']:
    for group in ['sedentary','walk','run']:
        choices=[]
        for name in sorted(set(e['File'] for e in key if e['Cohort']==cohort and e['Group']==group)):
            ev=[e for e in events if e['File']==name and e['Type']=='slip']
            for row in trace(name):
                if not (.9<=float(row['XEntryRightFraction'])<.95 and 0<float(row['ForwardSpeed'])<=5):continue
                fr=int(row['OriginalFrame']);dist=min(max(int(e['StartOriginalFrame'])-fr,fr-int(e['EndOriginalFrame']),0) for e in ev)
                if dist>12:choices.append((dist,name,fr))
        availability.append({'Cohort':cohort,'Group':group,'EligibleCenterFrames':len(choices),'Rule':'center speed (0,5] px/s; x [0.9,0.95); >12 frames from any detected slip; selected reviewed trials only'})
        if not choices:continue
        dist,name,fr=max(choices);rid='LOW_CONTROL_%02d'%(len(added)+1)
        e=next(dict(e) for e in key if e['File']==name);e.update(ReviewID=rid,Kind='non_event',EventNumber='0',StartOriginalFrame=str(fr-8),EndOriginalFrame=str(fr+8));added.append(e)
        fs=np.rint(np.linspace(fr-16,fr+16,12)).astype(int).tolist();expr='+'.join('eq(n,%d)'%(f-1) for f in fs)
        raw=run(['/opt/homebrew/bin/ffmpeg','-v','error','-i',str(SOURCE/name),'-vf',"select='%s',format=gray"%expr,'-fps_mode','passthrough','-f','rawvideo','-'])
        images=np.frombuffer(raw,np.uint8).reshape(-1,356,1280);tr=trace(name);bar=int(round(np.nanmedian([float(r['CentroidYOriginal'])+float(r['CentroidYBarRelative']) for r in tr])))
        canvas=Image.new('RGB',(1200,590),'white');d=ImageDraw.Draw(canvas);d.text((10,5),rid+' | group hidden | low-speed center, algorithmic non-event window',fill='black')
        for j,(f,im) in enumerate(zip(fs,images)):
            x=j%4*300;y=30+j//4*175;canvas.paste(Image.fromarray(im).crop((980,bar-90,1280,bar+60)),(x,y));d.text((x+4,y+152),'frame %d'%f,fill='black')
        d.text((10,565),'Central non-event window %d-%d; quiet motion is NOT assumed.'%(fr-8,fr+8),fill='black');canvas.save(OUT/'sequences'/(rid+'.jpg'),quality=92)
        a,b=fr-56,fr+56
        run(['/opt/homebrew/bin/ffmpeg','-v','error','-y','-i',str(SOURCE/name),'-vf',f'trim=start_frame={a-1}:end_frame={b},setpts=4*(PTS-STARTPTS)','-r','40','-an','-c:v','libx264','-crf','20','-pix_fmt','yuv420p',str(OUT/'clips'/(rid+'.mp4'))])
        with (OUT/'traces'/(rid+'.csv')).open('w') as f:
            w=csv.DictWriter(f,fieldnames=list(tr[0]));w.writeheader();w.writerows(r for r in tr if a<=int(r['OriginalFrame'])<=b)
write('low_speed_control_availability.csv',availability);write('additional_low_speed_controls.csv',added);write('review_key.csv',key+added)
