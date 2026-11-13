# Last-retained D14 scalar ordered-pattern tests

Exploratory either-direction order test for posture,speed,tail-motion height and tail-motion score from last-crossing_values.csv. These are scalar endpoints, NOT tests along beam position. Speed is meanSpeedLoco (stops excluded); spatial speed profiles include stops. Motion height scalar is median within crossing, spatial bins are mean heights; tail score scalar uses Legacy mask while spatial profiles use exported valid-pair mask. Therefore do NOT place these p-values on spatial curves as if testing their shape.

Cage means (15 cages), additive cohort nuisance, no D0 predictor. Four unrestricted parameters,11 residual df. Null equality versus either monotone order with plateaus allowed; independent homoscedastic Gaussian Monte Carlo200000 draws and approximate null-residual HC2 wild signs32768 sensitivity. Same cone solver/calibration as tests/testOrderedCageChanges.py. Direction-specific values saved only for transparency. Last crossing and outcomes chosen after inspection; no across-outcome correction. Nonrandom allocation, sparse cages and common-cohort-effect assumptions remain. An ordered test does not establish RUN–WALK specifically.

| Metric | Either-direction Gaussian p | Either-direction wild sensitivity p |
|---|---:|---:|
| posture | 0.1798 | 0.1140 |
| speed | 0.0037 | 0.0034 |
| motion_height | 0.7469 | 0.6870 |
| tail_score | 0.0684 | 0.0906 |
