# BeamCross: A MATLAB Tool for Balance Beam Video Analysis

This repository contains a set of **MATLAB** functions and scripts for analyzing mouse locomotion and slip events on a balance beam. The core workflow includes detecting camera edges, locating the bar, tracking the mouse, computing weighted movement metrics, and identifying slip events.

## Overview

The camera view of a balance beam setup typically includes a horizontal bar and a mouse traversing the beam. The bar and camera edges are detected to establish a region of interest (ROI) for tracking the mouse. The mouse’s centroid is tracked across frames, and a weighted movement metric is computed to emphasize the mouse’s presence. Slip events are detected based on this metric, and their severity is quantified.
![Diagram](BeamcrossFrameStructure.png)


1. **`BBanalysisSingleFile.m`**  
   The main entry point for analyzing a single `.mp4` video file. Loads and preprocesses the video, detects the bar and camera edges, tracks the mouse, computes slips, and optionally produces diagnostic plots and annotated videos. Returns all relevant measurements in a structured output.

2. **`trackMouseOnBeam.m`**  
   Tracks the mouse position on the beam across frames. Typically returns mouse centroids, speeds, and a tracked/cropped version of the video.

3. **`detectCameras.m`**  
   Identifies the top and bottom camera rectangles (black regions) in a mean or reference frame, returning their vertical boundaries.

4. **`detectBar.m`**  
   Locates the horizontal bar by analyzing the image (e.g., a mean frame). Returns the bar’s top coordinate and thickness.

5. **`cropVideoBelowBar.m`**  
   Crops out the portion of the video below the bar. Useful for focusing on slip events that happen under the beam.

6. **`computeMouseProbabilityMap.m`**  
   Computes a per-column (and optionally per-pixel) “probability” or fraction of the mouse occupying that column. Helps weight movement by how fully the trunk is present vs. just the tail.

7. **`computeWeightedMovement.m`**  
   Given a video region of interest (e.g., under the bar) and the column probabilities, calculates a movement trace that weighs each column’s differences by how likely the mouse is there.

8. **`detectSlips.m`**  
   Uses the weighted movement trace to find slip intervals (above a certain threshold). Returns the start frames, duration, peak values, and area (severity) of each slip event.

9. **`plotBBtrial.m`**  
   Creates diagnostic plots: a movement trace vs. time (with slip markers) and a 2D mouse centroid trajectory, color-coded by speed. Also places arrow annotations and summary text on the figure.

## Additional Helpers and Subfolders

Some functions and scripts reside in separate subfolders for organization:

- **`visualization/`** may contain GUIs or interactive display tools like **`displayBehaviorVideoMatrix`** (a function that plays back frames, provides a slider and “play/pause” button, etc.).
- **`videoProcessing/`, `videoImageAnalysis/`, `helperFunctions/`** may hold smaller utility scripts (`readVideoIntoMatrix.m`, `getMeanFrame.m`, etc.) that perform image I/O, frame differencing, or morphological operations needed by the main pipeline.

## Basic Workflow

1. **Run** `BBanalysisSingleFile.m`, pointing it to a `.mp4` file and specifying optional parameters:
   ```matlab
   R = BBanalysisSingleFile('path/to/data', 'mouse_trialA.mp4', ...
       'MAKEPLOT', true, 'SLIPTHRESHOLD', 2.5);

2. **Inspect results** in R, which includes
  - mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration - info on the general traversing
  - slipEventStarts, slipEventDurations, slipEventAreas, etc. - info on detected slips
  - slipFrames, slipFrameDurations - the frames where slips occurred
  - slipPeakValues - the peak movement values during slips
3. **Visualize** the results with `plotBBtrial.m`:
   ```matlab
   plotBBtrial(R, 'mouse_trialA.mp4');
   ```
    This will show a movement trace, a 2D trajectory, and annotated slip events.
4. **Inspect** the annotated video (if requested) or other diagnostic plots to verify the analysis.

## Dependencies
- MATLAB (tested on R2024b).
- Image Processing Toolbox (for insertShape, morphological ops, etc.).
- Videos in .mp4 format, requires ffmpeg installation and presence on path.    
  
