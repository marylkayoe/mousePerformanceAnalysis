#!/usr/bin/env python3
"""Summarize completed validation with explicit failures, mismatches and denominators."""
import argparse, collections, csv, json, math
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);a=ap.parse_args();root=a.output
read=lambda name:list(csv.DictReader((root/name).open()))
trials=read('trial_manifest.csv');events=read('events.csv');comparisons=read('comparison_by_file.csv')
truth=lambda v:str(v).lower() in {'1','true'}
number=lambda v:float(v) if v else float('nan')
status=collections.Counter(r['Status'] for r in trials)
fields=sorted(set(r['Field'] for r in comparisons))
summary=[]
for field in fields:
    rows=[r for r in comparisons if r['Field']==field]
    summary.append({'Field':field,'Compared':len(rows),'Matched':sum(truth(r['Match']) for r in rows),
                    'Mismatched':sum(not truth(r['Match']) for r in rows)})
with (root/'comparison_summary.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=['Field','Compared','Matched','Mismatched']);w.writeheader();w.writerows(summary)
counts=collections.Counter(r['Type'] for r in events)
nonfinite={field:sum(number(r[field]) for r in trials if math.isfinite(number(r[field]))) for field in
 ['TraceInfinities','MissingCentroidSamples','SpeedNonfinite','MovementNonfinite','TailTotalNonfinite','TailAboveNonfinite','TailBelowNonfinite','EventsWithMissingPosition']}
metadata=[r for r in trials if truth(r['FrameRateMismatch'])]
failed=[r for r in trials if r['Status']!='complete']
key_fields=['nSlips','slipEventDurations','totalSlipMagnitude','meanSlipAmplitude','nStops','stoppingDurations',
            'correctStoppedFrames','meanSpeedLoco','stdSpeedLoco','mouseCentroids','meanPosturalHeight','traverseDuration',
            'tailMotionSum','tailMotionIndex','tailMotionMean','tailMotionSumAboveBar','tailMotionIndexAboveBar','tailMotionMeanAboveBar',
            'tailMotionSumUnderBar','tailMotionIndexUnderBar','tailMotionMeanUnderBar']
lines=['Tara balance-beam rerun: final validation report','',
 f'Trials: {len(trials)}; outcomes: {dict(status)}.',f'Events retained: {dict(counts)}.',
 f'Profiles present: {sum(truth(r["ProfilesPresent"]) for r in trials)}; fully verified: {sum(truth(r["ProfilesVerified"]) for r in trials)}.',
 'Confirmed thresholds: LOCOTHRESHOLD=40, SLIPTHRESHOLD=2.5, MOUSESIZETHRESHOLD=2.',
 'Other settings and original numerical behavior preserved; exact source/provenance in run_manifest.json and code_snapshot/.','',
 'REFERENCE AGREEMENT (per original filename; detailed values/differences in comparison_by_file.csv)']
for field in key_fields:
    rows=[r for r in comparisons if r['Field']==field];lines.append(f'{field}: {sum(truth(r["Match"]) for r in rows)}/{len(rows)} matched.')
lines+=['','KNOWN REFERENCE/PIPELINE SCHEMA ISSUES',
 'Reference tailMovementTrace contains scalar placeholders, so it cannot validate a frame-by-frame tail trace.',
 'Raw stoppingDurationsTotal is compared separately from the pipeline singular stoppingDurationTotal.',
 'The latter can contain traversal length instead of stopped-frame count. correctStoppedFrames compares',
 'the preserved stop mask with the sum of the reference stop-duration list; use that corrected field.',
 'No original scalar values were silently repaired.','', 'FAILURES / PARTIAL TRIALS']
if not failed:lines.append('None.')
for r in failed:lines += [r['File']+' | '+r['Status']+' | '+r['Stage'],r['Error']]
lines+=['','NONFINITE / MISSING VALUES']
lines += [f'{key}: {int(value)}' for key,value in nonfinite.items()]
lines+=['Final speed samples are NaN by the original algorithm. Tail bad-frame masks and NaNs remain intact.',
        'trial_manifest.csv also lists nonfinite scalar summary fields. For example, no-slip trials have an',
        'undefined meanSlipAmplitude (NaN); matching NaNs do not establish a measurable quantity.',
        'Missing centroid samples and missing event positions are not imputed. Profile first frames, invalid',
        'frame pairs, and zero/nonfinite motion totals produce NaN height/fraction indices, not zeros.','',
        f'FRAME-RATE METADATA: {len(metadata)} trials differ between VideoReader rate and encoded timing.',
        'Time axes use independently decoded encoded timestamps. Original rounded analysis rates are retained;',
        'speed values are not rescaled retrospectively. Full details are in trial_manifest.csv and metadata/.',
        f"Decoded/encoded image-geometry mismatches: {sum(truth(r['GeometryMismatch']) for r in trials)}.",
        'Native MATLAB geometry is preserved, with no automatic resizing or cropping to force agreement.','',
        'EVENT-POSITION VALIDATION',
        'Intervals reproduce preserved masks; starts/ends map to original frames; sampled midpoints are checked',
        'against unchanged centroid arrays. Positions are finite or explicitly marked missing. The midpoint',
        'sample is the earlier central sample for an even-length event. This is algorithmic validation, not',
        'manual ground truth of biological slip/stop onset. The reference has no independent event positions.','',
        'ROW-PROFILE VALIDATION',
        'Weighted row profiles reconstruct existing total, above-bar and below-bar tail traces using the',
        'original vertical weights, normalization and smoothing. Compressed single-precision profiles are',
        'read back and their derived height checked against the double-precision index (absolute tolerance',
        '2e-4 pixels). Profile/frame/mask dimensions and invalid/no-motion NaNs are checked.',
        'Paired original post-mouse debug frames and profile plots are in plots/*.row_profile_audit.png.',
        'Motion-weighted height reflects where motion occurs; it is not stationary-tail height, and residual',
        'body/paw/bar/background or moving-crop contributions remain possible. See METHODS.txt.','',
        'EXPLORATORY D0/D14 PLOTS',
        f'Eligible algorithm/reference-validated crossings: slips {sum(truth(r["ValidSlipPlotCrossing"]) for r in trials)}, stops {sum(truth(r["ValidStopPlotCrossing"]) for r in trials)} (all days).',
        'D0/D14 group/day denominators and exclusions: position_plot_denominators.csv.',
        'Bin counts and denominators: position_bin_counts.csv. Each crossing contributes once to a bin it visits.',
        'Zero-event crossings are included. Common horizontal camera-field fraction is mirrored for left-entry',
        'crossings so entry is on the right. No per-trial endpoint stretching or physical beam-length claim.',
        'The figures are descriptive; events/crossings are not treated as independent biological replicates.',
        'Mouse and cage identifiers remain available for later hierarchical analyses.','',
        'STORAGE AND DELIVERY',f'Canonical results: {root}',
        'Original source videos remain in place; no full video matrices or debug movies were saved.',
        'Small stage checkpoints preserve partial results. No bulk scratch directory was used.',
        'Reproduction helpers/docs belong in Git; all generated tables, profiles, figures and logs stay external.',
        'A clearly named ZIP is prepared after visual review. ZIP verification and transfer logs are separate.',
        'Original canonical files are retained regardless of transfer outcome.']
(root/'VALIDATION_REPORT.txt').write_text('\n'.join(lines)+'\n')
(root/'validation_summary.json').write_text(json.dumps({'trials':len(trials),'outcomes':dict(status),'events':dict(counts),
 'profilesVerified':sum(truth(r['ProfilesVerified']) for r in trials),'nonfinite':nonfinite,'frameRateMismatches':len(metadata),
 'fields':summary,'failedFiles':[r['File'] for r in failed]},indent=2))
print(json.dumps({'trials':len(trials),'outcomes':dict(status),'events':dict(counts),'profilesVerified':sum(truth(r['ProfilesVerified']) for r in trials)}))

brief=["TARA BALANCE-BEAM RESULTS — LOCOTHRESHOLD 40", "",
 f"Trials: {len(trials)}; outcomes: {dict(status)}", f"Events: {dict(counts)}",
 f"Verified row profiles: {sum(truth(r['ProfilesVerified']) for r in trials)}", "",
 "Start with VALIDATION_REPORT.txt for matches, discrepancies and limitations.",
 "METHODS.txt gives exact settings, instrumentation, coordinate and weighting definitions.", "",
 "Files:", "  trial_manifest.csv — identifiers, timing, QC and availability for every retained file",
 "  events.csv — slips/stops, frame intervals, midpoint positions and validation flags",
 "  comparison_by_file.csv — regenerated versus Tara reference values",
 "  position_bin_counts.csv / position_plot_denominators.csv — plot data and exposure counts",
 "  dataset_index.mat — MATLAB tables for the combined dataset",
 "  trials/<original filename>.mat — C: traces, metadata, summaries and events",
 "  trials/<original filename>.trace.csv — frame-by-frame traces and compact new indices",
 "  trials/<original filename>.profiles.mat — P: compressed unweighted/weighted row profiles",
 "  plots/ — D0/D14 event-position figure and original/debug-frame audits", "",
 "P.unweighted and P.probabilityWeighted are [original decoded row x traversal frame].",
 "P.originalFrames and P.timeSeconds map columns to the original video.",
 "The new motion-height index is NOT the existing scalar verticalMotionTrace or stationary-tail height.",
 "Use correctStoppedFrames rather than the pipeline's inconsistent total-stop-duration field.",
 "All source videos remain in their original folder; none are included in the ZIP."]
(root/'README.txt').write_text('\n'.join(brief)+'\n')
