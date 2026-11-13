"""Crop-area normalization sensitivity, existing conventional scatter style."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tests/plotWholeTailNoVerticalWeight.py').read_text()
s=s.replace("balance_beam_whole_tail_no_vertical_weight_20261113')","balance_beam_whole_tail_no_vertical_weight_20261113/per_crop_pixel')").replace("q['MeanWholeMotion']","q['MeanWholeMotionTimes1000']").replace("r['MeanWholeMotion']","r['MeanWholeMotionTimes1000']")
s=s.replace('upper=150*math.ceil','upper=.6*math.ceil').replace('/150)','/.6)').replace("'raw a.u.'","'10⁻³ a.u./pixel'").replace('whole-no-vertical-weight\'','whole-no-vertical-weight/per-crop-pixel\'')
s=s.replace("Mean raw motion over current joint-valid frames.","Mean weighted motion divided by geometrical crop pixel count, multiplied by1000 for display. Crop pixels=decoded height times number of offsets0:1.25*mousePixelLength. No brightness, physical magnification or visible-tail-area correction; exploratory size sensitivity.")
exec(compile(s,__file__,'exec'),{'__file__':str(R/'tests/plotWholeTailNoVerticalWeight.py'),'__name__':'__main__'})
