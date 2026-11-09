"""Extract only a single trial pair or dataset index from the Tara rerun ZIP."""
import pathlib, shutil, sys, zipfile
archive, key, destination = sys.argv[1:]
dest=pathlib.Path(destination)
root='balance_beam_events_traces_L40_20261106/'
if key=='--index':
    pairs=[(root+n,n) for n in ('dataset_index.mat','trial_manifest.csv','README.txt','METHODS.txt','VALIDATION_REPORT.txt','VISUAL_AUDIT_NOTES.txt','run_manifest.json')]
else:
    if pathlib.PurePath(key).name!=key or not key.endswith('.mp4'):
        raise ValueError('Expected complete original MP4 basename')
    pairs=[(root+'trials/'+key+'.mat','trial.mat'),(root+'trials/'+key+'.profiles.mat','profiles.mat')]
with zipfile.ZipFile(archive) as z:
    names=z.namelist()
    for source,name in pairs:
        if names.count(source)!=1:raise ValueError('Expected exactly one archive member: '+source)
        with z.open(source) as src, (dest/name).open('wb') as out:shutil.copyfileobj(src,out,1024*1024)
