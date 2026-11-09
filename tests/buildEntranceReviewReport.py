"""Assemble a navigable, local review package from audited tables and observations."""
from reviewBeamEntrance import *
import html,shutil,hashlib,datetime

def table(rows,cols):
    def value(x):
        try:
            v=float(x)
            return ('%.4g'%v) if np.isfinite(v) else str(x)
        except (ValueError,TypeError):return str(x)
    return '\n'.join([' | '.join(cols)]+[' | '.join(value(r[c]) for c in cols) for r in rows])
coverage=read(OUT/'review_coverage.csv');exposure=read(OUT/'exposure_summary.csv')
stages=read(OUT/'detector_stage_group_summary.csv');trialstages=read(OUT/'detector_stage_trial_summary.csv');speed=read(OUT/'all_D0_speed_summary.csv')
observations=read(OUT/'review_observations.csv');pairs=read(OUT/'plotted_comparable_pairs.csv')
geometry=read(OUT/'detector_geometry.csv');cam=read(OUT/'camera_summary.csv')
statuses=[json.loads(f.read_text()) for f in (OUT/'detector_stages').glob('*.status.json')]
assert len(statuses)==21 and all(d['success'] and d['exactTraceSpeedCentroidFrameEventMatch'] for d in statuses)
speedsummary=[]
for g in ['sedentary','walk','run']:
    a=[r for r in speed if r['Group']==g];total=sum(float(r['Seconds']) for r in a)
    low=sum(float(r['Seconds']) for r in a if r['SpeedBin'] in ['0','(0,5]','(5,20]','(20,40]'])
    tiny=sum(float(r['Seconds']) for r in a if r['SpeedBin'] in ['0','(0,5]'])
    zero=sum(float(r['Seconds']) for r in a if r['SpeedBin']=='0')
    speedsummary.append({'Group':g,'SecondsAtSpeedLE40':low,'PercentEntryAtSpeedLE40':100*low/total,'PercentEntryAtSpeedLE5':100*tiny/total,'PercentEntryAtZeroSpeed':100*zero/total})
write('all_D0_speed_exposure_overview.csv',speedsummary)
report='''D0 BEAM-ENTRANCE REVIEW — exploratory, 2026-11-07

Scope and interpretation
The 0.90–0.95 camera-field interval was selected after viewing the original plot.
This is a descriptive investigation, not a confirmatory group test or an estimate
of detector sensitivity/specificity. Events and frames are not independent animals.
The fixed camera-field fraction is not a calibrated physical beam distance.
Slips during stops remain allowed; stopping alone was never treated as an error.

The detailed findings and interpretation are in FINDINGS.txt. This methods/results
appendix records the review coverage, numerical comparisons and file organization.

Review coverage
'''+table(coverage,['Group','ReviewedMice','ReviewedCages','ReviewedTrials','ReviewedEvents','NonEventWindows'])+'''
Both cohorts are represented in every group. The visual sample contains all 13
entry-region detections in TMCS3_S07 trial 4, plus first and last entry detections
for 12 other purposefully selected mice spanning additional cages. Selection is
not a random or representative sample of all detected events.
Twenty-four non-target event sequences were presented in shuffled anonymous IDs
before identity/group lookup. The target was known, and the analyst knew the
selection design: this is partial label masking, not an independent blinded study.
Visual judgments use chronological source-frame sequences (12 samples around each
interval), with targeted band overlays and context; they are not expert manual
ground truth or exhaustive frame-by-frame annotation. Full-field slow-motion clips
preserve every source frame at 0.25x playback for independent inspection.
Six initial non-event windows maximize separation from detections within the chosen
trials. Four additional windows have positive center speed <=5 px/s and >12-frame
separation. No selected run trial supplied a center meeting that strict low-speed
control rule; this limitation is preserved in low_speed_control_availability.csv.
Non-event means no algorithmic detection, not biological absence of a slip.

All eligible D0 crossing exposure (not limited to the visual sample)
'''+table(exposure,['Subset','Trials','Mice','Cages','Events','EntrySeconds','StoppedEntrySeconds','EventsPerSecond'])+'''
Exposure uses exact saved encoded timestamp differences, with the last sample
assigned the median frame interval. Event membership uses the saved sampled event
midpoint centroid; the whole event need not lie inside the spatial bin.

Speed exposure across all 124 eligible D0 crossings
'''+table(speedsummary,['Group','SecondsAtSpeedLE40','PercentEntryAtSpeedLE40','PercentEntryAtSpeedLE5','PercentEntryAtZeroSpeed'])+'''
Speed <=40 is a descriptive bin; it is not identical to the temporally processed
stop mask. Full speed-stratum frame exceedance counts are in all_D0_speed_summary.csv.
Frame exceedance (>2.5) is not an event count: the detector subsequently closes
gaps and removes short connected components.

Detector-stage audit
All 21 selected trial reruns exactly reproduced saved forward speeds, centroids,
original-frame vectors, final under-bar traces, event starts and event durations.
No tolerance-based trimming or padding was used. First four attempts encountered
a capture-code insertion error; the correction changed instrumentation only.
Failed attempt records/logs are retained, and all four successful retries passed
the same exact checks. No failed diagnostic attempt was used in the comparisons.

'''+table(stages,['Group','Subset','Mice','Cages','Trials','MedianSpeed','MedianRawUnweighted','MedianRawWeighted','MedianFiniteSpeedMultiplier','FractionAboveThreshold','FractionNonfiniteBeforeClamp'])+'''
These medians/fractions pool entry frames and therefore weight long visits more.
detector_stage_mouse_summary.csv supplies one row per mouse instead. None of these
pooled quantities is an independent-animal statistical test. Reviewed trials were
chosen through events, so stage summaries should not be generalized as unbiased
population detector performance. Shared raw-amplitude bins and speed bins remain
descriptive and can still differ in movement anatomy, waveform and trial baseline.

What each detector stage means
RawUnweighted: sum of absolute frame-to-frame pixel differences in the under-bar
band of the existing background-enhanced tracked video. It is pre-weighting and
pre-speed adjustment, not raw camera photon intensity or a paw-specific measure.
RawWeighted: that difference after the original sigmoid row weighting and squared
mouse-column probabilities, before speed adjustment, smoothing and normalization.
SpeedMultiplier = 160/log1p(forwardSpeed); SpeedAdjusted = RawWeighted*multiplier.
The unchanged function smooths with smooth(...,10), then subtracts a baseline
median and divides by 1.4826*MAD from finite NON-STOPPING frames of the full
traversal (fallback rules preserved). Negative normalized values become zero;
NaNs become zero. Intermediate Inf/NaN values are retained in this audit.
The input threshold remains 2.5; morphological closing uses five frames and the
minimum retained connected component is five frames. Settings remain L40/S2.5/M2,
EXCLUDE_STOPPING_FRAMES=false, under-bar extent factor 1.5, smooth argument 10.
The copied analysis returns after the unchanged slip computation; tail analysis
and full-video outputs are unnecessary for this diagnostic and were not generated.

At positive speeds 1, 5 and 40 px/s the multiplier is approximately 230.83, 89.30
and 43.09. Thus identical instantaneous weighted raw motion is amplified 5.36x
more at speed 1 than speed 40 before smoothing. Different trial median/MAD baselines
can offset or accentuate that difference. The raw-equivalent threshold columns
describe a locally constant-speed/constant-motion approximation, not a replacement
event detector. Zero speed is a separate numerical singularity, not the limit of
a valid monotonic sensitivity comparison.

Similar-raw-peak examples
'''+table(pairs,['ReviewA','ReviewB','GroupA','GroupB','Cohort','RawPeakRatioAoverB','SpeedA','SpeedB','FinalPeakA','FinalPeakB','SigmaA','SigmaB'])+'''
Pairs share cohort, weighted raw peak within 25% and duration within factor two.
They do NOT have matched anatomy, complete waveform or baseline. Pair figures use
separate labeled y scales; blue vertical lines bracket the selected event and
other peaks in the surrounding context may belong to other events. Four plotted
pairs were purposefully chosen to illustrate low speed, baseline differences and
both cohorts. All eligible pairs are retained in the comparison CSV.

Recording checks
All 124 eligible D0 sources are 1280x356. Exact detected bar tops are 207–208 in
TMCS2 and 213–214 in TMCS3; thickness ranges overlap between groups (15–17 pixels).
The original centroid-coordinate reference row is one pixel below the detected
bar top in these videos. It is explicitly named CentroidYReferenceRow; exact
detector geometry comes from saved C metadata in detector_geometry.csv.
The target trial detector band maps to original rows 224–240 inclusive.
Brightness checks sample the middle entry frame in each crossing, using the fixed
unoccupied background ROI x500:900,y40:140 (zero-based, half-open). They do not
measure complete temporal flicker, exposure calibration or every local shadow.
'''+table(cam,['Cohort','Group','TrialsWithEntry','BackgroundMeanMedian','BackgroundMeanMin','BackgroundMeanMax'])+'''
No conspicuous group-specific framing or lighting change was visible in the reviewed
full-field examples. This does not prove recording conditions are identical.
The entrance platform itself lies outside the field; contact cannot be established
from proximity to the dark beam marker. Handler fingers appear in at least one
walk non-event example. No gross centroid jumps or missing centroid samples occur
inside the reviewed event intervals; this does not certify every image mask/crop.
The saved tail bad-frame mask is not the slip detector's validity mask.

Repeated detections and the target numerical gap
Target detections 11 and 12 span 1728–1755 and 1778–1848. The head remains below
the beam through the intervening period. Saved speed is zero at 1760–1772, and the
saved motion trace is zero at 1756–1777. A synthetic positive constant raw-motion
check using the saved speeds and exact speed/smooth/normalization operations
reproduces this exact invalid-smoothed/zero-output interval. It is not a biological
rerun and was never substituted for the saved measurements. Actual instrumented
stages are supplied alongside this isolated numerical check.
The short earlier detections are separate threshold excursions; the visual review
does not establish 13 separate hind-paw slip cycles. The gaps between some detections
are only a few frames, within an ongoing crouched/repositioning episode.

Files and reproducibility
FINDINGS.txt: concise scientific interpretation, separating observation/inference.
review.html: local clip/sequence browser, with group/observation behind details.
review_observations.csv: every reviewed event/control, full filename and frames,
categories, uncertainty, trace peak/speed/stop fraction and missing-position checks.
clips/: 47 short full-field 0.25x clips plus a continuous target context clip.
sequences/: inspected chronological source-frame sheets. Red borders mark detected
intervals; fixed display crop is not a moving analysis crop.
detector_stages/: compact MATLAB MAT and CSV per selected trial, preserving every
intermediate nonfinite value plus exact-match status JSON.
detector_figures/: group behavior, similar-raw pairs and target-stage figures.
camera_checks.csv / detector_geometry.csv: per-file recording checks and exact rows.
exposure_by_mouse.csv and detector_stage_mouse_summary.csv: animal-level summaries.
zero_speed_diagnostic.*: small synthetic check, explicitly separated from real data.
provenance.json / detector_instrumentation/: hashes, frozen code origin, instrumentation.

Original code/data and the previous canonical rerun were not changed. Canonical
review outputs are in the current visible review folder under Tara/RESULTS.
No bulk scratch directory, source-video copy or full video matrix was saved.
Small reproducibility helpers belong in the repository; generated review products
remain external. This review does not propose excluding stopped frames or changing
thresholds on the basis of these exploratory group differences.
'''
(OUT/'METHODS_AND_RESULTS.txt').write_text(report)
shutil.copy2(Path('tests/entranceReviewFindings.txt'),OUT/'FINDINGS.txt')
cards=[]
for r in observations:
    esc=html.escape
    cards.append(f'''<article><h2>{esc(r['ReviewID'])} | original frames {r['StartOriginalFrame']}–{r['EndOriginalFrame']}</h2>
<video controls preload="none" src="{esc(r['Clip'])}"></video><p><a href="{esc(r['Sequence'])}">Inspected frame sequence</a> · <a href="{esc(r['Trace'])}">Saved trace CSV</a></p>
<details><summary>Reveal identity and observations</summary><p>{esc(r['File'])}<br>{esc(r['Group'])} · {esc(r['CageID'])}</p><p>{esc(r['Observation'])}</p><p>Assessment: {esc(r['HindPawSlipAssessment'])}. {esc(r['ReviewMethod'])}</p></details></article>''')
(OUT/'review.html').write_text('''<!doctype html><html><meta charset="utf-8"><title>D0 entry exploratory review</title>
<style>body{font:17px system-ui;max-width:1100px;margin:35px auto;padding:0 20px;line-height:1.5}article{border-top:1px solid #aaa;margin-top:32px;padding-top:12px}video{width:100%;background:#222}summary{cursor:pointer}h2{font-size:20px}</style>
<h1>D0 entry exploratory review</h1><p>Clips play at one-quarter original speed; every source frame is retained. Labels/observations are hidden below each clip for optional independent review. Sampling is purposeful, not an estimate of false-positive rates.</p>
<p><a href="FINDINGS.txt">Findings</a> · <a href="METHODS_AND_RESULTS.txt">Methods and results</a> · <a href="review_observations.csv">Complete review table</a> · <a href="clips/TARGET_continuous_1069_1935.mp4">Continuous target context (frames 1069–1935)</a></p>
<p><a href="detector_figures/group_detector_behavior.png">Group detector behavior</a> · <a href="detector_figures/raw_matched_pair_1.png">Raw comparison 1</a> · <a href="detector_figures/raw_matched_pair_2.png">Raw comparison 2</a> · <a href="detector_figures/raw_matched_pair_3.png">Raw comparison 3</a> · <a href="detector_figures/raw_matched_pair_4.png">Raw comparison 4</a> · <a href="target_detector_band.jpg">Target detector-band overlay</a></p>
'''+''.join(cards)+'</html>')
scripts=['reviewBeamEntrance.py','summarizeEntranceReview.py','entranceReviewObservations.json','entranceReviewFindings.txt','addLowSpeedEntranceControls.py','checkEntranceNumerics.m','prepareEntranceDetectorAudit.py','runEntranceDetectorAudit.m','launchEntranceDetectorAudit.py','analyzeEntranceDetectorStages.py','plotEntranceDetectorStages.m','buildEntranceReviewReport.py','illustrateEntranceDetectorBand.py']
for name in scripts:shutil.copy2(Path('tests')/name,OUT/name)
p=json.loads((OUT/'provenance.json').read_text());p.update(completedUTC=datetime.datetime.now(datetime.timezone.utc).isoformat(),detectorStageExactMatches=21,reviewedEvents=37,reviewedNonEventWindows=10,reviewedMice=13,reviewedTrials=21,reviewedCages=11,scripts={n:hashlib.sha256((OUT/n).read_bytes()).hexdigest() for n in scripts})
(OUT/'provenance.json').write_text(json.dumps(p,indent=2))
print('Report and browser prepared')
