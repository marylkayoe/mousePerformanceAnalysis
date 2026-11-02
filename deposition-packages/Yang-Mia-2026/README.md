# Yang-Mia-2026: open-field analysis

This package contains MATLAB code for tracking a mouse and measuring open-field
locomotion from a video. Video conversion is a separate preparation step.

**Maternal immune activation impairs development of cerebellar nuclei and motor coordination in offspring**

Yang Mi, Masato Hirota, Salvatore Andrea Lacava, Tara Turkki, Mio Miyagi,
Miho Tamai, Marylka Yoe Uusisaari\*, and Hiroki Ishikawa\*

## Contents

- `open-field/analysis/`: tracking and analysis functions.
- `open-field/helpers/`: trajectory and frame-classification helpers.
- `open-field/plotting/`: plots of speed and trajectory.
- `open-field/video/`: MP4 reader and separate AVI-to-MP4 converter.
- `open-field/examples/`: a short downsampled sali-group MP4 and its two plots.

## Requirements

MATLAB R2024b Update 10, Image Processing Toolbox, and Statistics and Machine
Learning Toolbox were used for the reanalysis. FFmpeg with `libx264`, available
on the system path used by MATLAB, is needed only for video conversion.

## Example: analyze a recording

In MATLAB, set the current folder to this `Yang-Mia-2026` folder, then run:

```matlab
addpath(genpath(fullfile(pwd, 'open-field')));
exampleFolder = fullfile(pwd, 'open-field', 'examples');
fileName = 'exampleVideo.mp4';

% Pixel size in the downsampled video, plots enabled, 15% border, 40 mm/s threshold.
[meanSpeed, maxSpeed, locoTime, totalDistance, locoDistance, meanLocoSpeed, centerPercent, speeds] = ...
    analyzeSingleOFfile(exampleFolder, fileName, 2, 1, 0.15, 40);
```

The included MP4 is an approximately 20-second, 2x-downsampled excerpt of the
sali-1-5 recording, cut from the losslessly encoded analysis MP4 without
re-encoding. It is an example, not a full one-minute trial. The two PNG files
show the speed and trajectory plots from this excerpt.

For other AVI recordings, conversion is a separate preparation step:

```matlab
mp4 = convertToMP4('/path/to/recording.avi', 2);
```

The converter keeps the AVI and reuses an existing MP4 of the same name without
checking how it was made. Conversion is not called by the analysis function;
use a fresh output location to change conversion settings.

## Video and calibration

The open-field recordings used in the analysis were recorded at a stated
100 frames/s for approximately one minute. The source AVIs were encoded as DV
at 720 x 480 pixels with pixel aspect ratio 8:9. A complete recording typically
contains approximately 6,000 frames; frame counts should be checked for each
file. Some source video metadata contained inconsistent frame-rate fields;
the conversion preserves timestamps. The MATLAB-decoded image dimensions can
differ from encoded dimensions because of pixel aspect ratio.

The included `exampleVideo.mp4` is a short excerpt: MATLAB decoded it as
2,001 frames at 320 x 240 pixels, with a reported frame rate of approximately
99.950 fps and a duration of about 20 seconds. It is not one of the full-length
files used to calculate the paper's trial measurements.

The converter uses H.264 (`libx264`), CRF 0, preset `veryslow`, no audio, and
spatial `scale=iw/2:-1` by default. It passes timestamps through without forcing
a frame rate. The 2023 command used `-vsync 0`; FFmpeg 9 removed that option,
so the active command uses `-fps_mode passthrough`. The historical command is
retained as a comment in `convertToMP4.m`.

For our downsampled recordings, the default `PIXELSIZE` is **2 mm per decoded
pixel**, based on an approximate 1 mm/pixel estimate before 2x downsampling.

`readVideoIntoMatrix` uses `floor(VideoReader.FrameRate)` for historical
reproducibility. For a previously tested downsampled recording MATLAB reported
approximately 99.939 fps, so analysis used 99 fps.

## Analysis and outputs

The tracker assumes a dark mouse is visible throughout a recording against a
light background. Each grayscale frame is quantized using ten thresholds; the
darkest class is hole-filled and closed, and its largest connected component
provides the centroid. There is no minimum-area cutoff. Inspect tracking results
before interpreting measurements.

Centroid positions are in mm. Speed is displacement over a one-second window
by default, advanced one frame at a time, with moving-median outlier handling.
Locomotion means speed **strictly greater than 40 mm/s** by default. Reported
distances integrate these processed speed estimates; they are not sums of
frame-to-frame trajectory lengths. The function returns mean and maximum speed
(mm/s), locomoting time (s), total and locomoting distance (mm), mean locomoting
speed (mm/s), center percentage, and the speed vector. If outliers are detected,
speed gap filling also fills the padded end; otherwise the padded end remains NaN.

The center is defined from each mouse's observed trajectory range, not measured
walls. `BORDERLIMIT = 0.15` assigns 15% of that range at each edge to the border.
The returned `centerFraction` is a **rounded whole percentage** from 0 to 100.


## Analysis code and reproducibility

This package implements the tracking and measurements used for the open-field
reanalysis. The core tracking, speed, and trajectory-based center calculations
follow the historical analysis. For this package, the code was reorganized and
documented, plotting was updated, and video conversion was made a separate step.
The pixel size and locomotion threshold can be supplied explicitly; the default
pixel size is 2 mm/pixel for the 2x-downsampled recordings described above.

Using MATLAB R2024b Update 10, the package was checked against the corrected
reanalysis for one complete recording and against the saved trajectory for the
included example excerpt. Their scalar measurements matched. The excerpt is
provided to demonstrate the workflow, rather than to reproduce a full trial.
