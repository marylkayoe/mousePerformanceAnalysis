# Exploratory spatial tests of speed change, D14−D0

Within each mouse, subtract saved D0 spatial speed from D14 at each identical bin; convert pixels/s to mm/s using 700/1201. Average mouse changes within cage. The statistic is the equally weighted mean of the two cohort-specific between-group cage-mean differences. Permute whole cage profiles between the two groups within cohort, preserving group cage counts; enumerate every allocation. Two-sided tests assume cage labels are exchangeable within cohort under the null. This does not establish that allocation was randomized.

Only bins with every contributing mouse finite in every cage of that comparison enter inference; missing values remain missing, without interpolation. The fixed support is unchanged under permutations. Profile graphics retain their existing mouse-mean/SEM display and coverage rule; the inference uses cage means and stricter support. Adjacent bins are not independent: each permutation retains the complete spatial profile.

At each bin, compare the absolute observed difference to the permutation maximum absolute difference over all eligible bins. This controls the spatial family under the exchangeability null; multiply those p-values by three (capped at one) to also correct across the three group comparisons. Alpha 0.05, two-sided; no cluster threshold, selected centre window, new smoothing, or choice of test based on its result. Raw pointwise p-values are diagnostic, not significance annotations. This maximum-difference statistic is unstudentized and therefore may be conservative where variance is smaller.

The question is whether groups differ in D14−D0 change, not whether one group changes from zero or is faster in absolute terms at D14. Analysis is exploratory, prompted by inspecting the profiles. Small cage numbers give coarse exact p-values. No significant bin is not evidence of equivalence. No inference identifies a precisely bounded biological centre region.

Reproduce: `tests/testSpeedSpatialChanges.py` (Python with NumPy). Source `speed-profile-source.json` from saved speed-absolute-position-data.mat; cage/group metadata from weighted-speed/speed-D14-minus-D0.csv. Original measurements unchanged.

- run minus sedentary: 126 allocations; 121/123 bins eligible; min raw p=0.00793651; min spatial-corrected p=0.015873; min spatial+three-pair p=0.047619; 1 significant bins.

- run minus walk: 168 allocations; 121/123 bins eligible; min raw p=0.0178571; min spatial-corrected p=0.732143; min spatial+three-pair p=1; 0 significant bins.

- walk minus sedentary: 30 allocations; 122/123 bins eligible; min raw p=0.0333333; min spatial-corrected p=0.6; min spatial+three-pair p=1; 0 significant bins.
