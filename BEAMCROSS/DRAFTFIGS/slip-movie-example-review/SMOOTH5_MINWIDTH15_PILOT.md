# Five-frame smoothing pilot, fixed minimum mouse width15

Canonical: /Volumes/ShosaiData/DATA/Tara/RESULTS/balance_beam_tail_minwidth15_smooth5_20261112. Input balance_beam_tail_min_mouse_width15_20261112; six unchanged selected crossings. Script tests/testTailTemporalSmoothing.py; visual review tests/reviewTailSmoothingEvents.py. Original results/analysis unchanged; no full-dataset analysis.

Method: centered arithmetic moving mean of5 raw below-bar scalar samples (k-2:k+2) BEFORE per-trial median/1.4826MAD normalization. Windows shrink at contiguous-valid-run endpoints; never span invalid/nonfinite gaps, which remainNaN. Five acquisition frames~31.25ms at160fps. Re-estimate median/MAD on smoothed valid samples; positive normalized amplitude>3.5, closinglength5, minimumcomponent5, and existing motion-height-at-peak<=+7.5mm unchanged. Height remains independently calculated from UNSMOOTHED row motion with its existing5-frame height averaging; no additional height smoothing. Score=sum(max(z-3.5,0)) over event component, nofpsdivision. Modified minwidth15 column weights held fixed for raw/smoothed comparisons.

No smoothing of the displayed spatial green/red columns: movie shows original minwidth15 instantaneous contributions with new smoothed-detector event markers. Green2xlinear/redlog1p, purpleprofile/blackheight, shared per-mouse raw maximum, common score-scaled markerarea, source mapping/invalid flags/starttrim/finalhold preserved. This distinction matters: smoothing applies to the detection scalar, not spatial profiles.

Counts raw→smooth5: SED D0 6→5, D14 3→2; WALK D0 3→2, D14 2→2; RUN D0 4→5, D14 1→1. SED D0 oldpeaks1883/1896 merge into1881–1902; WALK D0 oldpeaks1919/1935 merge into1909–1938. SED D14 f777 drops; prior user interpretation was trailing paw motion, not necessarily noise, so do not call this a confirmed falsepositive.

New runnerD0 event2237–2241, peak2238 (~36.37s presentation), z6.1759,height-16.20mm,score10.8340. Lossless hash-checked triplet2234/2238/2242 shows verticalbelowbar tail. Earlier recovered2117event remains, now2115–2123 peak2119 (~32.40s). Earlier31.27s candidate still notaccepted. Gallery changed_event_gallery.png includes newly gained and lost events. Onlyone new non-overlapping accepted event found; not a full falsepositive validation sample.

Normalization materially changes: e.g.RUN D0 MAD38.04→27.86; its total normalizedscore547.57→851.73. Higher scores don't imply more actual physical motion. Allsix smoothedMADs lower; normalized eventscore comparisons across detector versions must be interpreted with the changing denominator. See summary.csv for exact values.

Validation: unsmoothed comparator reproduces prior minwidth15 events/start/end/peak/passheight and scores (1e-8relative/absolute). Explicit missing-gap test confirms no cross-gap smoothing. Reused columns/rows/crops reference alreadyvalidatedminwidth15 package. Renderer independently verifies every crop hash,mapping,smoothedmotionheight,outputframecount/fps/dimensions and fulldecode. Dataframes preserved includingNaNs.

Movie: presentations_smooth5/SED_WALK_RUN_D0_D14_tail_slips.mp4, plus individual andpaired movies. Allsource-linked inputs remain onShosaiData; moviesstandalone. Bulkresults external, code/notesinrepo, no commit/pushrequested. Rendering expected<250MB; no bulk scratch.
