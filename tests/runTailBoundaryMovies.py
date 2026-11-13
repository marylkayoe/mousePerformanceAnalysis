from pathlib import Path
import json,subprocess,sys
B=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS');O=B/'balance_beam_tail_centroid_boundary_20261113';limits=json.loads((O/'movie_color_limits.json').read_text())
for factor in [2,3]:
 p=O/f'factor{factor}'
 cmd=[sys.executable,'tests/renderMarkedTailExamples.py','--base',str(p),'--event-table',str(p/'normalized_movie_events.csv'),'--motion-csv',str(p/'motion_colors.csv'),'--score-markers','--log-below','--horizontal','--height-max-mm','7.5','--display-smooth-columns','5','--height-trail','--trail-direction','right','--boundary-overlay','--color-limits',*map(str,limits),'--scale-manifest',str(B/'balance_beam_tail_minwidth15_smooth5_20261112/presentations_height_trail_right_20261113/manifest.json'),'--output-name','presentations']
 subprocess.run(cmd,check=True)
