# Tail-slip threshold pilot, 2026-11-12

## Scope and provenance

Threshold-only sensitivity first, then motion-height filtering, as requested. No production detector, saved measurements, source videos or existing movies were changed. This is a small exploratory calibration on six existing example crossings, not an independent validation set. Repository HEAD: `e52c789f43c7d513121f44df0a8e326be7dbed54`; working tree contains uncommitted workflow work, including the scripts listed below.

Canonical review outputs: `/Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_threshold_review_20261112`.
Inputs: validated lossless crops and masks in `balance_beam_tail_D14_examples_marked_20261112` under the same RESULTS root; corrected `NewBelowRaw` from `balance_beam_tail_reweight_L40_halfdepth_20261109`. Source and L40 rerun remain in their established locations. Underlying analysis settings remain LOCOTHRESHOLD=40, SLIPTHRESHOLD=2.5, MOUSESIZETHRESHOLD=2; these are distinct from the exploratory tail peak prominence multiplier.

## Sampling and review

One mouse and one cage per group, two trials each (D0 and D14):

|Group|Mouse|Cage|Trials|Baseline peaks reviewed|Tail below at peak|
|---|---|---|---|---:|---:|
|SED|TMCS3_S08|TMCS3 C03|D0 T1, D14 T1|9|6|
|WALK|TMCS2_S19|TMCS2 C06|D0 T3, D14 T1|13|2|
|RUN|TMCS3_S01|TMCS3 C01|D0 T1, D14 T1|7|2|

Full filenames and original frames are in threshold_events.csv and visual_event_labels.csv. All 29 baseline peaks were reviewed at the lossless peak crop and +/-8 original frames (+/-0.05 s at 160 fps). Single AI visual review, unblinded to trial and trace values; no independent human adjudication. Label means a visible tail below the beam bottom at the peak, not proof of a physical slip. Repeated peaks may belong to the same tail-lowering episode. Events are not independent animals.

## Detector comparison

Keep raw corrected below-bar motion, saved joint valid mask, contiguous-run handling and 0.1 s minimum peak separation unchanged. MATLAB findpeaks prominence threshold is multiplier times 1.4826*median(abs(valid values - median(valid values))), calculated separately per trial. Tested multipliers 5, 7.5, 10, 15, 20, 30, 50. Below-bar row weights are 1 immediately below beam, rise linearly to 2 at half-depth, then remain 2. No display log transform enters detection.

|Prominence multiplier|Height gate|Detections|Visibly below|Fraction below|
|---:|---|---:|---:|---:|
|5|None|29|10|34.5%|
|7.5|None|11|9|81.8%|
|10|None|7|7|100%|
|15|None|4|4|100%|
|20|None|2|2|100%|
|5|Height at peak <=0|9|9|100%|
|7.5|Height at peak <=0|9|9|100%|
|10|Height at peak <=0|7|7|100%|

30 and 50 yield no detections. Allowing the minimum height within +/-100 ms instead of height at peak gives the same retained events in this sample. Height is the existing full-profile motion-weighted median with five-frame smoothing, not anatomical tail position. All higher-threshold peaks mapped to reviewed baseline peaks. Complete sweep is in threshold_visual_summary.csv.

## Important missed episode

TMCS3_S08_T2_C03_BB_D00_20260219_THT_TRIAL1_gray.mp4: original frames around 1467–1482 show a nearly vertical tail below the beam. See sedentary_D0_vertical_tail_window.png (frames 1438–1494 at four-frame intervals). There is no baseline 5x peak in that episode. A diagnostic local-prominence calculation over the reviewed 1458–1486 window finds a largest local prominence about 3.218x MAD at frame 1479. This diagnostic is not the MATLAB threshold sweep. Motion height remains positive (minimum about +5.012 mm in that window), so a <=0 height gate also misses the episode.

Thus raising the threshold removes noise but cannot recover this anatomically below-bar episode. The whole-profile median can remain above while a narrow tail extends below. A motion detector cannot measure all tail-below occupancy, especially with little frame-to-frame motion. Conversely SED D14 original frame999 has a visibly below-bar tip and positive motion height (+11.8 mm); the height gate removes that valid anatomical-below detection.

## Interpretation and next step

Threshold 10 alone is a useful conservative candidate: all seven retained peaks have visible below-bar tail in this sample, but it retains only seven of ten baseline visually-below peaks. Threshold 7.5 plus height<=0 retains nine, all visibly below; threshold5 plus the same gate happens to retain exactly the same nine. Therefore this pilot does not establish an advantage of 7.5 over 5 once gated, nor a general 100% reliability claim. These fractions describe selected peak precision, not sensitivity/recall for all below-bar episodes.

Before choosing a new production setting, validate the candidates on additional mice/cages and independently reviewed event and non-event windows. Preserve a separate anatomical tail-below/occupancy question if that is the intended metric. Do not treat this pilot as validation that counted peaks are distinct physical slips.

## Reproduction and files

- tests/reviewTailThresholds.m: exact MATLAB threshold sweep; requires fresh destination, refuses overwrite.
- tests/makeTailThresholdReviewSheets.py: lossless event contact sheets and coarse scans.
- tests/summarizeTailThresholdReview.py: explicit review labels and threshold/gate tables.
- tests/reviewVerticalTailMiss.py: dense missed-episode contact sheet.
- Canonical folder contains per-event data, visual labels, summary, contact sheets and vertical_tail_missed_window.json with per-frame raw motion, height and validity.
- Repository retains code, this report and small review/summary tables only. No bulk scratch or new movie export. Internal free space after review:33 GiB.
