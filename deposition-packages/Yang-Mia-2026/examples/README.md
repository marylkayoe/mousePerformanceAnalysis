# Example recording

The MP4 is an approximately 20-second excerpt of the sali-1-5 open-field
recording, spatially downsampled by 2. It was cut from the losslessly encoded
analysis video without re-encoding. It is provided to demonstrate the code;
its measurements do not represent the full one-minute trial.

`example-speed.png` and `example-trajectory.png` show the plots generated from
this excerpt. To create them in MATLAB, set the current folder to the
`Yang-Mia-2026` package folder and run:

```matlab
addpath(genpath(pwd));
exampleFolder = fullfile(pwd, 'examples');
fileName = 'exampleVideo.mp4';

% 2 mm/pixel, plots on, 15% border, 40 mm/s locomotion threshold.
analyzeSingleOFfile(exampleFolder, fileName, 2, 1, 0.15, 40);
```

This opens the two figures in MATLAB. See the [package README](../README.md)
for video parameters and analysis details.
