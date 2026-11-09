"""Summarize post-hoc reweighting and draw transparent SVG comparison plots."""
from pathlib import Path
import csv,json,hashlib,subprocess,math,html,shutil
OUT=Path('/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_reweight_L40_halfdepth_20261109')
SRC=OUT.parent/'balance_beam_events_traces_L40_20261106'
rows=list(csv.DictReader((OUT/'comparison_by_file.csv').open()))
assert len(rows)==377, 'Do not publish a partial run as complete'
counts={s:sum(r['Status']==s for r in rows) for s in sorted({r['Status'] for r in rows})}
matches={k:sum(r[k]=='1' for r in rows) for k in ['OldTotalMatch','OldAboveMatch','OldBelowMatch']}
errors={k:max(float(r[k]) for r in rows if math.isfinite(float(r[k]))) for k in ['OldTotalMaxError','OldAboveMaxError','OldBelowMaxError']}
audited_frames=0
for row in rows:
    if row['Status']=='failed':continue
    data=list(csv.DictReader((OUT/'trials'/(row['File']+'.csv')).open()))
    assert len(data)==int(row['Frames']) and data[0]['InvalidFramePair']=='1'
    for i,d in enumerate(data):
        assert int(d['TraversalFrame'])==i+1
        if i:assert int(d['OriginalFrame'])==int(data[i-1]['OriginalFrame'])+1
        old,new=float(d['OldBelowRaw']),float(d['NewBelowRaw'])
        if math.isfinite(old) and math.isfinite(new):assert new+1e-10>=old
        if d['TailBadFrame']=='1':assert math.isnan(float(d['NewBelowNormalized']))
    audited_frames+=len(data)
summary={'trials':len(rows),'statusCounts':counts,'originalReconstructionPassCounts':matches,
         'independentlyAuditedCSVFrameRows':audited_frames,
         'maximumAbsoluteNormalizedReconstructionErrors':errors,
         'sourceRoot':str(SRC),'outputRoot':str(OUT),'gitHead':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()}
(OUT/'validation_summary.json').write_text(json.dumps(summary,indent=2)+'\n')
def chart_panel(parts,x,y,w,h,series,title):
    values=[v for _,_,points in series for _,v in points if math.isfinite(v)]
    lo=min(0,min(values));hi=max(values);hi=hi if hi>lo else lo+1
    allx=[t for _,_,points in series for t,v in points];xmin,xmax=min(allx),max(allx)
    parts.append(f'<text x="{x}" y="{y-18}">{html.escape(title)}</text>')
    parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="white" stroke="#bbb"/>')
    for label,color,points in series:
        segments=[];segment=[]
        for t,v in points:
            if math.isfinite(v):segment.append(f'{x+w*(t-xmin)/(xmax-xmin):.2f},{y+h-h*(v-lo)/(hi-lo):.2f}')
            elif segment:segments.append(segment);segment=[]
        if segment:segments.append(segment)
        for segment in segments:parts.append(f'<polyline fill="none" stroke="{color}" stroke-width="1.1" points="{" ".join(segment)}"/>')
    parts.append(f'<text x="{x}" y="{y+h+18}" font-size="12">x: {xmin:g}–{xmax:g}; y: {lo:.3g}–{hi:.3g}</text>')
def svg_start(height):return [f'<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="{height}" viewBox="0 0 1100 {height}"><rect width="100%" height="100%" fill="white"/><g font-family="sans-serif" font-size="15">']
parts=svg_start(350)
chart_panel(parts,60,60,970,220,[('old','#777',[(i/200,min(2*i/200,1)**3) for i in range(201)]),('new','#0072b2',[(i/200,1+min(2*i/200,1)) for i in range(201)])], 'Below-bar weights: old gray, new blue; depth 0 = first below-bar row, 1 = bottom')
parts.append('</g></svg>');(OUT/'weight_comparison.svg').write_text(''.join(parts))
examples=['TMCS3_S09_T3_C03_BB_D14_20260305_THT_TRIAL2_gray.mp4','TMCS2_S18_T3_C05_BB_D14_20251105_THT_TRIAL2_gray.mp4']
for name in examples:
    data=list(csv.DictReader((OUT/'trials'/(name+'.csv')).open()));parts=svg_start(700)
    parts.append(f'<text x="40" y="25">{name}</text>')
    for y,label,fields in [(80,'Raw below-bar motion (invalid pairs hidden)',['OldBelowRaw','NewBelowRaw']), (390,'Normalized below-bar trace (original bad-frame mask)',['OldBelowNormalized','NewBelowNormalized'])]:
        series=[]
        for field,color in zip(fields,['#777','#0072b2']):
            points=[(float(r['OriginalFrame']),float(r[field]) if not (y==80 and r['InvalidFramePair']=='1') else float('nan')) for r in data]
            series.append((field,color,points))
        chart_panel(parts,60,y,970,210,series,label+'; old gray, new blue; x = original frame')
    parts.append('<text x="60" y="665">Normalized traces have separate median/MAD scales; their amplitude ratio is not a raw-motion ratio.</text></g></svg>')
    (OUT/(name+'.comparison.svg')).write_text(''.join(parts))
text=f'''# Post-hoc below-bar tail-motion reweighting

User-approved definition: weight 1 at the first below-bar image row, rising
linearly to 2 halfway from that row to the image bottom, then constant at 2.
For relative depth d in [0,1], w(d)=1+min(2*d,1). This meets the above-bar
maximum of 1 at the boundary. The old below-bar weight was min(2*d,1)^3
(with the original epsilon/max normalization). Above-bar and full-height
total-tail measures are unchanged. No new combined above/below measure is
introduced. This is a new below-bar measure, not a correction retroactively
applied to the old results. Weight depth is based on recorded image geometry,
not calibrated physical distance.

## Inputs and reproducibility

Source results: `{SRC}`.
Original source videos remain at the source path recorded in that result set;
none were read or copied for this calculation. No tracking was run.
Inputs were `trials/<original filename>.profiles.mat` and the corresponding
trial MAT. Each profile is row-by-frame, containing sum_x(abs(I_k-I_(k-1)) *
croppedNoMouseProbValues(:,k)^2), with the original 0.85 cutoff already applied.
Weights therefore use destination frame k. Profiles are compressed float32,
converted to double for row summation; tiny differences from recomputing video
pixels are expected. Original L40/S2.5/M2 parameters and trial identifiers are
retained in every output MAT. Original code/data and prior results are unchanged.

Run `tests/reweightTaraTailProfiles.m` in MATLAB R2024b, then
`tests/reportTailReweight.py` in Python 3. Choose a fresh destination in both
scripts before another run. The MATLAB script refuses an existing destination.
The code is copied into `code/`; environment, git HEAD and checksums are recorded.
No bulk scratch was required. Calculations process one small profile at a time.

## Validation

Trials: {len(rows)}. Status counts: {counts}.
Reconstruction passes (absolute tolerance 1e-6 plus relative tolerance 1e-6):
{matches}.
Maximum absolute normalized errors: {errors}.
Reconstruction uses the OLD vertical weights and compares all three tail
traces with the saved validated rerun. NaN locations and infinity signs must
also agree. Frame counts, exact original-frame/timestamp mapping, bar geometry,
row coordinates and original bad masks are asserted; no trimming or padding.
The new ramp is checked for endpoints, monotonicity and the half-depth plateau.
Per-file mismatches, zero/nonfinite normalization scales and exceptions remain
explicit in `comparison_by_file.csv`; completion alone is not validation.

## Output semantics

Each `trials/<original filename>.mat` stores R with exact applied row weights,
raw old/new below-bar motion, new smoothed and normalized traces, original
above/total/below traces, reconstruction diagnostics, identifiers and timing.
Matching CSVs contain one row per traversal frame. First raw sample is zero
solely to retain the existing algorithm's no-predecessor convention; the
invalid-pair flag remains true. This does not mean observed absence of motion.
No full row profiles or video matrices are duplicated in this result set.

Normalization retains smooth(raw,5), median centering and 1.4826*MAD scaling.
As in the original code, normalization is computed before applying the original
tail bad-frame mask, and normalized NaNs are converted to zero before that mask.
The pre-replacement normalized array, replacement flags and scale are preserved
in MAT; pre-replacement values also appear in CSV. Nonfinite values are not
silently discarded. The stricter invalid-frame-pair mask is saved separately;
it is used for raw-mean comparisons but is not newly applied to the legacy-style
trace. Thus this rerun changes the vertical weights only, not masking policy.

Raw weight values are comparable across the bar boundary. Independently
normalized above/below values are NOT directly comparable physical magnitudes.
Higher raw weighted motion does not imply a uniformly higher normalized trace.
Motion can include residual paw/body/background contributions and moving-crop
effects; this analysis does not newly validate biological specificity.

## Inspection

`weight_comparison.svg` shows the old/new ramps. The two example
`*.comparison.svg` files show raw and normalized old/new traces versus original
frame number. These are exploratory algorithm comparisons, not group inference.
Previously generated debug videos still show the old weights and were not
replaced; they must not be labeled as views of this reweighting.
'''
(OUT/'METHODS.md').write_text(text)
shutil.copy2(__file__,OUT/'code'/Path(__file__).name)
(OUT/'artifact_checksums.json').write_text(json.dumps({str(p.relative_to(OUT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.rglob('*') if p.is_file() and p.name!='artifact_checksums.json'},indent=2)+'\n')
print(json.dumps(summary,indent=2))
print('Total bytes:',sum(p.stat().st_size for p in OUT.rglob('*') if p.is_file()))
