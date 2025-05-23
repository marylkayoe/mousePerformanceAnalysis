# BeamCross: A MATLAB Tool for Balance Beam Video Analysis

This repository contains a set of **MATLAB** functions and scripts for analyzing mouse locomotion and slip events on a balance beam.

## Table of Contents
- [BeamCross: A MATLAB Tool for Balance Beam Video Analysis]
  - [Background](#background)
  - [Formal description of the algorithm](#formal-description-of-the-algorithm)
    - [Formal Definition of Slip Events and Magnitudes](#formal-definition-of-slip-events-and-magnitudes)
  - [Description of functions](#description-of-functions)
    - [**`BBanalysisSingleFile.m`**](#bbanalysissinglefilem)
    - [**`trackMouseOnBeam.m`**](#trackmouseonbeamm)
    - [**`detectBar.m`**](#detectbarm)
    - [**`detectSlips.m`**](#detectslipsm)
    - [**`plotBBtrial.m`**](#plotbbtrialm)
    - [**`detectStoppingOnBeam.m`**](#detectstoppingonbeamm)
    - [**`readBBVideoIntoMatrix.m`**](#readbbvideointomatrixm)
    - [**`displayBehaviorVideoMatrix.m`**](#displaybehaviorvideomatrixm)
    - [**`annotateVideoMatrix.m`**](#annotatevideomatrixm)
  - [Additional Helpers and Subfolders](#additional-helpers-and-subfolders)
  - [Dependencies](#dependencies)


## Background and motivation for the work

Assessing mouse performance on a balance beam is one of the gold classics of systems neurobiology, as balance perturbations are a common symptom of numerous malfunctions of the central nervous system as well as the periferal sensory mechanisms. Experiments where a mouse is tasked by traversal of a narrow beam have been conducted for decades, and the assessment has been, until recently, based entirely on manual scoring - i.e. by a researcher observing either the animals or recorded videos and counting the number of slipping occurrences. 

While this approach is reasonably robust when used by experienced personnel, it has limitations. First, it doesn't easily scale to large numbers of trials to be examined. Second, it inherently lacks resolution: unless the bar is very narrow, healthy mice rarely slip and revealing subtle differences will need numerous repetitions, risking confounding factors related to habituation and motor learning even when combined with another simple metric such as duration of the traverse.

In this context, machine learning-based, markerless pose estimation tools such as DeepLabCut (Mathis et al, 2018) have recently been used to analyze mouse behavior on balance beams (Wahl et al, 2023; Bidgood et al, 2024). In this approach, positions of mouse body parts such as paws are estimated using a deep learning model trained on annotated videos, and their trajectories are then examined to identify slips. 

Without engaging in the broader discussion regarding increasing reliance on machine learning tools in experimental neuroscience (Narayanan and Kapoor, 2025), we simply note that instanciating a complex deep learning model is a massive overkill for a simple task of detecing slips, as the importance of green computing practises is increasingly recognized (Lannelongue et al, 2021).
 Here, we demonstrate that the problem of quantitative assessment of balance beam slips can be formulated using simple, discrete vector algebra, and that the task can be accomplished using a straightforward algorithm that is efficient, elegant and easy to modify. 

The algorithm is based on the idea that all we need to do is to observe how much movement is seen under the bar, assuming that the mouse is attempting to stay above the bar. Thus, we can simply calculate the frame-to-frame difference in pixel intensities below the bar, and identify slips as periods of movement above a certain threshold. The confounding factors are the mouse's tail and the fact that the mouse is not a rectangle, so we need to take into account the probability of the mouse being present in each column of the image. This is done by calculating a "mouse mask" that indicates which pixels belong to the mouse in each frame using a simple thresholding operation, and this mask is used to adjust the movement metric.

The code presented here not only calculates slip events, but also provides a number of additional (if trivial) features such as the severity of slips, duration of stops, and advancing speed during locomotion, that are useful for analyzing balance beam behavior.

It is beyond our means or interest to compare the performance of our algorithm with the deep learning-based approaches, but we note that the algorithm as implemented in Matlab (v2024b) is very fast. On a Macbook Air (M3, MacOS 14.6, 24GB RAM), a 10-second video (160 fps, 640x480 pixels, 9-12MB lossless .mp4 file) is processed in less than 10 seconds (excluding file IO) without any particular attempts at improving speed. 

Due to the simplicity of the algorithm, it is also easy to modify or expand - for example, in the context of balance beams with decreasing diameter. We hope that this work will not only speed up your analysis of balance beam videos, but also serve as an inspiration for considering simple, elegant solutions to problems that tend to be solved using unnecessarily complex deep learning models.

If you use this code or algorithm in your research, please cite it as:

Uusisaari, MY, (2025). BeamCross: A MATLAB Tool for Balance Beam Video Analysis. Retrieved from [gitHub](https://github.com/marylkayoe/mousePerformanceAnalysis/tree/main/BEAMCROSS)


### References
- Bidgood, Raphaëlle, et al. [Automated procedure to detect subtle motor alterations in the balance beam test in a mouse model of early Parkinson’s disease.](https://doi.org/10.1038/s41598-024-51225-1) Scientific reports 14.1 (2024): 862. 
- Lannelongue, Loïc, Jason Grealey, and Michael Inouye. [Green algorithms: quantifying the carbon footprint of computation](https://doi.org/10.1002/advs.202100707) Advanced science 8.12 (2021): 2100707. 
- Mathis, Alexander, et al. [DeepLabCut: markerless pose estimation of user-defined body parts with deep learning.](https://doi.org/10.1038/s41593-018-0209-y) Nature neuroscience 21.9 (2018): 1281-1289.
- Narayanan, Arvind, and Sayash Kapoor. [Why an overreliance on AI-driven modelling is bad for science.](https://doi.org/10.1038/d41586-025-01067-2) Nature 640.8058 (2025): 312-314.
- Wahl, Lucas, et al. [Detecting ataxia using an automated analysis of motor coordination and balance of mice on the balance beam.](https://doi.org/10.1101/2023.07.03.547476) bioRxiv (2023): 2023-07.


## Formal description of the algorithm

After loading and preprocessing the video, detecting the bar, and tracking the mouse, we compute a weighted movement metric to quantify mouse-related movement. This metric is used to identify slip events based on a user-defined threshold. The algorithm consists of the following steps:

We quantify mouse-related movement from video data using a weighted, pixel-level difference metric.
Given a binary mouse-mask matrix $M \in \{0,1\}^{H \times W \times N}$, where $M_{h,w,n}=1$ indicates that pixel $(h,w)$ belongs to the mouse in frame $n$, and an under-bar grayscale video matrix $V \in [0,1]^{H\times W\times N}$, we first calculate the fraction of mouse pixels per column as:

$$
C_{w,n} = \frac{1}{H}\sum_{h=1}^{H} M_{h,w,n}, \quad w=1,\dots,W,\quad n=1,\dots,N
$$

Next, we compute the absolute frame-to-frame difference in pixel intensity (with $D_{h,w,1}=0$):

$$
D_{h,w,n} = |V_{h,w,n} - V_{h,w,n-1}|,\quad n=2,\dots,N
$$

Summing vertically along columns, we obtain a column-wise measure of pixel intensity change:

$$
S_{w,n} = \sum_{h=1}^{H} D_{h,w,n}, \quad n=2,\dots,N
$$

Finally, these differences are weighted by the squared mouse fractions to emphasize areas with high mouse occupancy, yielding our weighted movement measure per frame:

$$
W_n = \sum_{w=1}^{W} S_{w,n}\,(C_{w,n})^2,\quad n=2,\dots,N
$$

This weighted metric $W_n$ robustly captures mouse-specific movement, which can be further normalized or smoothed as needed, and is used to identify slip events based on a user-defined threshold.

To detect slip events, we apply a threshold $\tau$ to obtain a binary slip mask $B_n$:

$$
B_n = 
\begin{cases}
  1, & W_n \geq \tau \\
  0, & W_n < \tau
\end{cases}
,\quad n=2,\dots,N
$$

We refine this slip mask with morphological operations to ensure robust event detection:

* **Morphological Closing**:
  Small gaps (up to 2 frames wide) are closed to merge temporally close slip detections. Given a linear structuring element $E$ of length 3, morphological closing (dilation followed by erosion) is defined as:

$$
  B_n^{\text{closed}} = (B_n \oplus E) \ominus E
$$

  where $\oplus$ and $\ominus$ represent dilation and erosion, respectively.

* **Removal of Brief Slip Events**:
  We discard slip events shorter than 3 frames, ensuring each detected slip event $S_j$ (a contiguous set of slip frames) satisfies:

$$
  |S_j| \geq 3 \text{ frames}
$$

Lastly, we identify contiguous slipping periods as connected components in $B_n^{\text{closed}}$. Each contiguous set of slip frames defines a distinct slip event for further analysis.

### Formal Definition of Slip Events and Magnitudes

Given the previously defined binary slip mask $B_n^{\text{closed}}$, we identify contiguous slip events as connected components within it. Each contiguous slip event $S_j$ (where $j = 1,\dots,n_{\text{slips}}$) is defined by a set of frame indices:

$$
S_j = \{ n \mid B_n^{\text{closed}} = 1 \text{ and } n_{\text{start}, j} \leq n \leq n_{\text{end}, j} \}
$$

where $n_{\text{start}, j}$ and $n_{\text{end}, j}$ are the first and last frames of the $j$-th slip event, respectively.

For each slip event, the **slip magnitude** ($A_j$) is computed as the area under the weighted movement trace $W_n$, above the slip threshold $\tau$:

$$
A_j = \sum_{n \in S_j}(W_n - \tau), \quad j = 1,\dots,n_{\text{slips}}
$$

The **peak slip magnitude** ($P_j$) is defined as the maximum weighted movement during the slip event:

$$
P_j = \max_{n \in S_j}(W_n), \quad j = 1,\dots,n_{\text{slips}}
$$

Finally, the **slip duration** ($D_j$) for the $j$-th slip is simply the number of frames within the slip event:

$$
D_j = n_{\text{end}, j} - n_{\text{start}, j} + 1, \quad j = 1,\dots,n_{\text{slips}}
$$

The total number of detected slips in a trial is then given by $n_{\text{slips}}$.


The algorithm is implemented in the `detectSlips.m` function, which processes the video data and mouse mask to identify slip events based on the computed weighted movement trace. See details in the documentation below.

## Description of functions

The camera view of a balance beam setup typically includes a horizontal bar and a mouse traversing the beam. The bar and camera edges are detected to establish a region of interest (ROI) for tracking the mouse. The mouse’s centroid is tracked across frames, and a weighted movement metric is computed to emphasize the mouse’s presence. Slip events are detected based on this metric, and their severity is quantified.
![Diagram](IMAGES/BeamcrossFrameStructure.png)

### `BBanalysisSingleFile.m` 
   The main entry point for analyzing a single `.mp4` video file. Loads and preprocesses the video, detects the bar, tracks the mouse, computes slips, and optionally produces plots and annotated videos. Returns all relevant measurements in a structured output.

### **`trackMouseOnBeam.m`**  
Tracks the mouse position on the beam across frames. Returns mouse centroids, speed information, stops, and three versions of the video: binary mask, a background-subtracted video with the centroid of the mouse indicated, and the original video cropped and trimmed to match the tracked ones.

```matlab
[mouseCentroids, instForwardSpeed, meanSpeed, traverseDuration, stoppingPeriods,...
 meanSpeedLoco, stdSpeedLoco, mouseMaskMatrix, trackedVideo, croppedVideo] = ...
 trackMouseOnBeam(croppedVideo, MOUSESIZETH, LOCOTHRESHOLD, USEMORPHOCLEAN, ...
 mouseContrastThreshold, FRAMERATE)
```

   _Notes_:
   - The mouse is presumed to be black (or much darker than anything else in the image). 
   - MOUSESIZETH defines the minimal area (in percentage of the cropped image) that need to be black to be considered mouse. Current default is 5%. Note that since the mouse walks into the frame at the beginning, the tracking only starts when there's "enough" of a mouse in the frame. You can decrease this to get more frames at the beginning (and end), but best not to go too low or you can get noise.
   - LOCOTHRESHOLD indicates the threshold horizontal speed (in px/sec) below which we consider the mouse has stopped. 
   - USEMORPHOCLEAN: set to "true" if the image is noisy and you want the mouse border to look smoother. However should not be necessary for tracking as it is a costly operation.
   - mouseContrastThreshold: used to binarize the mouse. Current default is 0.6 (should be between 0 and 1). If the mouse is not dark enough, make this value higher. 
   - Experimenter's hand is not usually a problem as long as it stays away from the mouse tracking area (indicated in the diagram above).
   - The resulting data and videos are given only for the (longest) period in the trial in which a mouse is deemed present.


   ![Diagram](IMAGES/originalTrimmedImage.png)
   ![Diagram](IMAGES/mouseMaskImage.png)
   ![Diagram](IMAGES/trackedMouseImage.png)

### **`detectBar.m`**  
   Locates the horizontal bar by analyzing the edges of the mean image. Pixels in the region where the tapes are are summed horizontally, and points of fast darkening and brightening are taken as the bar edges (i.e. peaks in the differential of the sum). Returns the bar’s top coordinate and thickness in pixels.

```matlab
[barTopYCoord, barWidth] = detectBar(barImage, mouseStartPosition, varargin)
```
   _Notes on input arguments_:
   - barImage: the mean image of the cropped video (or a single frame) where the bar is visible
   - mouseStartPosition: the side of the bar where the mouse starts (L or R). This is used to determine which side of the bar to look at for the edge detection.
   - 'MAKEDEBUGPLOT' - Enable debugging plots (default: false).
%  - 'barTapeWidth' - Percentage of image width for bar tape width (default:2%).

    <img src="IMAGES/barposition.png" alt="Diagram" width="300" height="300">
   Points to note: 
   - To avoid getting confused by cases where the recording starts too late and mouse is already on the bar in first frames, we look at the side opposite to mouse starting position. The starting position is currently expected to be L for CAM1 and R for CAM2.
   - However, as the bar is never completely straight, the value will not be exactly correct (maybe 5 - 8 pixels difference between left and right sides). If we could be sure that there are some frames without a mouse, we could take both sides and average (or project a straight line between them).
   - This means also that the posture of the mouse most likely will be seen to shift gradually from one to another edge, as it's calculated relative to bar position.
   - Note that the top-level function `BBanalysisSingleFile` can also receive bar position and thickness as input arguments, in which case it will not be recalculated. This helps if the bar in your images is not easily detectable (e.g. there are no black tapes on) or you want to speed up the code by skipping the bar detection step.
  

### **`detectSlips.m`**  
   Generates the weighted movement trace to find slip intervals (above a threshold). The slips are only counted if they happen "under the mouse". Returns the start frames, duration, peak values, and area (severity) of each slip event.

```matlab
[slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations, movementTrace, ...
underBarCroppedVideo] = detectSlips(trackedVideo, mouseMaskMatrix, barTopCoord, ...
 barThickness, SLIPTHRESHOLD, UNDERBARSCALE, DETRENDWINDOW)
 ```

   _Notes on input arguments_:
   - tracked video: grayscale, background-removed, mouse-enhanced video cropped and trimmed to the same dimensions as the binarized video
   - mouseMaskMatrix: the binarized mouse mask video
   - bardTopCoord: the y-coordinate of the top edge of the bar, as obtained by detectBar-function; used to define the "above-bar" region note that the coordinate matches bar position in the cropped (rather than original) video
   - barThickness: thickness of bar in pixels, used to define the "below-bar" region for detecting slipping
   - SLIPTHRESHOLD: a threshold value (a.u.) describing how large a below-bar movement should be to be considered a slip. If you worry about false slips detected with normal paw motion, increase this value. Current default: 2.
   -UNDERBARSCALE (optional): how much below the bar we look for movement (multiplies of bar width). Current default: 2
   -DETRENDWINDOW (optional): temporal window for detrending the movement trace to sharpen slip detection. Currend default 64 frames (0.4s)

   Principle is simple: look at how much between-frames changes happen below the bar:
```matlab
   totalMovement = sum(abs(currentFrame - previousFrame)); 
```
However, sometimes the tail of the mouse swings below the bar and might be detcted as a slip:
 ![Diagram](IMAGES/underbartail.png)

 To avoid this, we want to only consider movement below the bar in positions that are under the mouse. As the mouse is not a rectangle, calculate "mouse probability distribution" above the bar using local functions:
 -  **`LF_computeMouseProbabilityMap.m`**  
   Computes a per-column “probability” or fraction of the mouse mask occupying that column above the bar. Helps weight movement by how fully the trunk is present vs. just the tail. 
   -  **`LF_computeWeightedMovement.m`**  
   Given a video region of interest (e.g., under the bar) and the column probabilities, calculates a movement trace that weighs each column’s differences by how likely the mouse is there.

   Combining the results of these two local functions, we can get a weighted movement trace that is robust to noise and tail movements. Slips are detected by thresholding this trace, and the results are returned in the following output variables: 
   - slipEventStarts: the frame numbers where slips start
   - slipEventPeaks: the peak values of the weighted movement trace during slips
   - slipEventAreas: the area under the weighted movement trace during slips
   - slipEventDurations: the duration of each slip event in frames
   - movementTrace: the full weighted movement trace for the entire video
   - underBarCroppedVideo: the cropped video of the region below the bar, used for visualization

### **`plotBBtrial.m`**  
   Creates diagnostic plots: a movement trace vs. time (with slip markers) and a 2D mouse centroid trajectory, color-coded by speed. Also places arrow annotations and summary text on the figure.
```matlab
plotBBtrial( movementTrace, FRAMERATE, slipEventStarts, slipEventAreas, ...
    mouseCentroids, forwardSpeeds,meanSpeed, meanPosturalHeight,trialName, LOCOTHRESHOLD, SLIPTHRESHOLD)
```
   _Notes on input arguments_:
   - movementTrace: the full weighted movement trace for the entire video
   - FRAMERATE: the frame rate of the video
   - slipEventStarts: the frame numbers where slips start
   - slipEventAreas: the area under the weighted movement trace during slips
   - mouseCentroids: the x and y coordinates of the mouse centroid in each frame
   - forwardSpeeds: the forward speed of the mouse in each frame
   - meanSpeed: the mean speed of the mouse in each frame
   - meanPosturalHeight: the mean height of the mouse above the bar in each frame
   - trialName: the name of the trial (used for plot titles)
   - LOCOTHRESHOLD: the threshold for determining if the mouse is moving or stopped (in px/sec, default:100)
   - SLIPTHRESHOLD: the threshold for determining if a slip has occurred (in a.u., default:2.5)
   
   The function generates a figure with the following panels:
      ![Diagram](IMAGES/slipDetectionResults.png)

## Additional Helper functions

### **`detectStoppingOnBeam.m`**

Identifies stopping periods of the mouse on the beam from a computed speed trace. The function applies thresholding, morphological operations, and smoothing to robustly detect intervals of low speed ("stopping"). The result is a binary frame-level mask indicating stopping frames, and a list of start-end indices for each detected stopping period.
```matlab
[stoppingFrames, stoppingStartStops] = detectStoppingOnBeam(speedArray, LOCOTHRESHOLD, FRAMERATE)
```

Notes on input arguments:
* `speedArray`: Array of instantaneous speeds (in px/sec) for each frame.
* `LOCOTHRESHOLD`: Speed threshold (in px/sec) below which the mouse is considered to be stopped. Default: 100 px/sec.
* `FRAMERATE`: Frame rate of the video (in Hz). Used to convert frame indices to time in seconds. Default: 160 fps

Outputs:
* `stoppingFrames`: Logical array indicating frames where the mouse is stopped (1) or moving (0).
* `stoppingStartStops`: Matrix (nStops rows, 2 columns) of start and end frame indices for each detected stopping period. So, start frames are in column 1 and end frames in column 2. Note that his will be empty if no stopping periods are detected.

**Algorithm summary**:

* Threshold speed array to identify candidate stopping frames.
* Apply morphological closing to merge brief gaps.
* Remove stopping periods shorter than a specified minimum duration.
* Smooth transitions into and out of stopping periods using convolution to handle gradual changes in speed.
* Extract contiguous stopping periods as start-end frame intervals.

### **`readBBVideoIntoMatrix.m`**

Reads a balance beam video file (`.mp4`) into a MATLAB 3D matrix (height × width × frames). It automatically detects and converts RGB videos into grayscale, supports optional spatial downscaling (via a user-defined scale factor), and returns the video frame rate. 

```matlab
[videoMatrix, frameRate] = readBBVideoIntoMatrix('mouse_trial.mp4', 'scaleFactor', 0.5);
```

### **`visualization/displayBehaviorVideoMatrix.m`**
 Displays a grayscale or RGB video with a slider and play button. Simplified version of MATLAB's built-in `VideoPlayer` function. It allows for frame-by-frame navigation and playback at a specified frame rate. Also, it can display a symbol denoting frames when an event is present (e.g., slip or stop).
```matlab
displayBehaviorVideoMatrix(videoMatrix, titleString, dispData, logicalData, NORMHISTO);
```

**Inputs:**
* `videoMatrix`: (H×W×nFrames) grayscale or RGB video frames.
* `titleString`: Title for the video display.
* `dispData`: Numeric to display on the video (e.g., mouse position, speed). If nothing given, the function will display the frame number.
* `logicalData`: Logical array indicating frames with events (e.g., slips, stops). If empty, no symbols are displayed.
* `NORMHISTO`: Normalization flag for histogram display (default: false).
  
![Diagram](IMAGES/displayBehaviorMatrixImage.png)


### `videoProcessing/annotateVideoMatrix.m`

Generates an annotated RGB video from a grayscale input, highlighting events (e.g., mouse slips, stops, or movements) with colored indicators and labels.

**Usage Example:**

```matlab
annotatedVideo = annotateVideoMatrix(videoMatrix, slipStarts, slipDurations, ...
    stopStarts, stopDurations, ...
    'ShapePosition1',[10 10 40 30], 'ShapeColor1','red', 'eventLabel1','Slip', ...
    'ShapePosition2',[60 10 40 30], 'ShapeColor2','blue','eventLabel2','Stop');
```
   
**Inputs:**

* `videoMatrix`: (H×W×nFrames) grayscale video frames.
* `eventStarts` / `eventDurations`: frame indices and durations for events.

**Optional Parameters (examples):**

* `'ShapeType1'`, `'ShapeType2'`: Shape types (`'FilledRectangle'`, default).
* `'ShapeColor1'`, `'ShapeColor2'`: Shape colors (`'red'`, `'blue'`, etc.).
* `'eventLabel1'`, `'eventLabel2'`: Text labels under event shapes.
* `'Opacity'`, `'LineWidth'`: Visual customization of annotations.

**Output:**

* Annotated RGB video matrix suitable for playback with displayBehaviorVideoMatrix.m.
  
  ![Diagram](IMAGES/annotateSlipStopVideo.png)



- **`videoProcessing/`, `videoImageAnalysis/`, `helperFunctions/`** may hold smaller utility scripts ()`getMeanFrame.m`, etc.) 

## Dependencies
- MATLAB (tested on R2024b).
- Image Processing Toolbox (for insertShape, morphological ops, etc.).
- Signal Processing Toolbox (for smoothing)
- Curve Fitting Toolbox (for smoothing)
- Computer Vision Toolbox (for video reading and writing)
- Videos in .mp4 format, requires ffmpeg installation and presence on path to run convertAVItoMP4.m.    
  
