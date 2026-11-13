# D14 last-retained-crossing figure

Select highest trialNumber among each mouse's three retained D14 crossings, not necessarily filename TRIAL3. Exact full filenames/frame timing in selected_crossings.csv. All42mice have3retained D14 crossings. This is D14-only, not D14−D0. Selection was motivated by previously inspected slowing results and is exploratory; do not substitute it as a prespecified primary endpoint.

Source assets/Tara-BB-trial-data.csv: meanSpeedLoco, meanPosturalHeight (both ×700/1201), nSlips,totalSlipMagnitude; mean event score=total/count. No-slip mean undefined and retained missing. Validated trial_manifest.csv supplies duration Frames/AnalysisFrameRate and stopped percentage CorrectStoppedFrames/Frames×100. Tail height=trial-motion-height.csv medianHeight, corrected full-profile smoothed motion-height index; tail score=whole-motion-reweighted/trial-values.csv sumLegacy/nLegacy, corrected whole-range frame mean with established Legacy mask. Tail measures not anatomical tail position. Source filenames preserved; original results untouched.

Main style: mouse circles,cage-mean diamonds,mouse group mean bars; full linear ranges,no clipping. Total slip score displayed in thousands only. Statistics: exact whole-cage labels within cohort, equal-cohort pairwise contrasts, direct two-sided p-values RUN–WALK primary, other pairs secondary. Original three-pair Holm values also saved; no across-outcome adjustment. Missing values explicitly listed; nonrandom allocation/exchangeability limitations unchanged.

Reproduce tests/plotLastCrossingD14.py. Combined editable SVG/PNG plus standalone panels and machine-readable values/tests. No source video reads or tracking.
