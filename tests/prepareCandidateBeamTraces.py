#!/usr/bin/env python3
"""Record source/code hashes and independently verify encoded video timing."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

repo = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1])
output.mkdir(parents=True, exist_ok=True)
source = Path('/Volumes/ShosaiData/DATA/Tara/DATA/BB/TMCS2-3_badRemoved_allTrials_aviToGray_exclMiceRemoved')

def describe(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return {'path': str(path), 'bytes': path.stat().st_size, 'sha256': h.hexdigest()}

videos, timing = [], []
for prefix, dates in [('TMCS3_S09_T3_C03', ['20260219', '20260305']),
                      ('TMCS2_S18_T3_C05', ['20251022', '20251105'])]:
    for day, date in zip([0, 14], dates):
        trials = [1, 2, 4] if prefix.startswith('TMCS3') and day == 0 else [1, 2, 3]
        for trial in trials:
            path = source / f'{prefix}_BB_D{day:02d}_{date}_THT_TRIAL{trial}_gray.mp4'
            row = {'file': path.name, 'exists': path.is_file()}
            if path.is_file():
                row.update(describe(path))
                data = json.loads(subprocess.check_output([
                    '/opt/homebrew/bin/ffprobe', '-v', 'error', '-select_streams', 'v:0',
                    '-show_entries', 'stream=width,height,r_frame_rate,avg_frame_rate,nb_frames,start_time,duration:frame=best_effort_timestamp_time',
                    '-of', 'json', str(path)]))
                times = [float(frame['best_effort_timestamp_time']) for frame in data.pop('frames')]
                data.update(file=path.name, timestampCount=len(times), firstTimestamp=times[0],
                            lastTimestamp=times[-1], maxDeviationFrom160fpsSeconds=max(
                                abs(t - i / 160) for i, t in enumerate(times)))
                timing.append(data)
            videos.append(row)
(output / 'source_video_manifest.json').write_text(json.dumps({'root': str(source), 'videos': videos}, indent=2))
(output / 'encoded_timing_validation.json').write_text(json.dumps(timing, indent=2))
paths = list((repo / 'BEAMCROSS').glob('*.m')) + [repo / 'videoImageAnalysis/getMeanFrame.m']
paths += list((repo / 'tests').glob('*CandidateBeamTraces.*'))
paths += list(Path('/Users/yoe/Downloads').glob('BB_*261105_2.mat'))
manifest = {'commit': subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip(),
            'worktree': subprocess.check_output(['git', '-C', str(repo), 'status', '--short'], text=True),
            'files': [describe(p) for p in paths]}
(output / 'reproduction_manifest.json').write_text(json.dumps(manifest, indent=2))
print(f'Prepared {sum(v["exists"] for v in videos)}/{len(videos)} source videos')
