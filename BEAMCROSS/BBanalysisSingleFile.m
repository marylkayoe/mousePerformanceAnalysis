function R = BBanalysisSingleFile(dataPath, fileName, varargin)
% BBANALYSISSINGLEFILE  Analyze a single balance-beam video file.
%
%   R = BBanalysisSingleFile(dataPath, fileName, ...)
%
% This function loads a specified *.mp4 file (balance-beam video), tracks the
% mouse, detects slips under the bar, and optionally produces plots and an
% annotated video. It returns a result structure R with key metrics.
%
% REQUIRED INPUTS:
%   dataPath  : (char) Directory containing the video file.
%   fileName  : (char) Name of the .mp4 video file to analyze.
%
% OPTIONAL PARAMETERS (Name-Value pairs via varargin):
%   'MAKEPLOT'      : (logical) Whether to produce diagnostic plots. [true]
%   'FRAMERATE'     : (numeric) Frame rate used if not detected from file. [160]
%   'PIXELSIZE'     : (numeric) Spatial scaling factor (pixels to mm, etc.). [1]
%   'SLIPTHRESHOLD' : (numeric) Threshold for slip detection in z-scored
%                     movement trace. [2]
%   'LOCOTHRESHOLD' : (numeric) Threshold for stopping detection in pixels/sec. [100]
%   'MOUSESIZETHRESHOLD' : (numeric) Minimum fraction of frame area (0-100) for mouse, used for tracking. [5] 
%
% OUTPUT:
%   R : A structure with fields:
%       .mouseCentroids      : (nFrames x 2), XY coordinates of the mouse.
%       .forwardSpeeds       : (nFrames x 1) speed (pixels/sec or scaled).
%       .traverseDuration    : (scalar) Time (sec) from start to end of beam walk.
%       .meanSpeed           : (scalar) Average forward speed of the mouse.
%       .BBvideo             : (3D array) The tracked/cropped grayscale video.
%       .slipEventStarts     : Frame indices where each slip event begins.
%       .slipEventAreas      : Slip severity (area above threshold) per slip.
%       .slipEventDurations  : Number of frames of each slip.
%       .slipEventPeaks      : Maximum amplitude of each slip event.
%       .nSlips              : Total slip count in this trial.
%       .totalSlipMagnitude  : Sum of slipEventAreas for all slips.
%       .meanSlipAmplitude   : Mean slipEventAreas across all slips.
%       .annotatedVideo      : (4D array) Annotated video with shapes in slip frames.
%
%   Negative or error returns:
%       R = -1 if the file does not exist or is not an .mp4.
%
% USAGE EXAMPLE:
%   R = BBanalysisSingleFile('/myData/', 'mouse1_trialA.mp4', ...
%       'MAKEPLOT', true, 'SLIPTHRESHOLD', 2.5);
%
% DEPENDENCIES:
%   readVideoIntoMatrix, getMeanFrame, findCameraEdgeCoordsInImage, findBarYCoordInImage,
%   BBtrackingMouse, getMouseProbOnBeam, quantifyWeightedMovement,
%   detectSlipsFromMovement, annotateVideoMatrix, plotBBtrial,
%   displayBehaviorVideoMatrix, ...

% TODO: add option to give the vertical position of the bar as an input
% parameter
%
% -------------------------------------------------------------------------

%% --- Initialize Output Structure ---
R.mouseCentroids       = [];
R.forwardSpeeds        = [];
R.traverseDuration     = [];
R.meanSpeed            = [];

%% --- Parse Input Arguments ---
p = inputParser;
addRequired(p, 'dataPath', @ischar);
addRequired(p, 'fileName', @ischar);

addParameter(p, 'MAKEPLOT', true, @islogical);
addParameter(p, 'FRAMERATE', 160, @isnumeric);
addParameter(p, 'PIXELSIZE', 1,  @isnumeric);
addParameter(p, 'SLIPTHRESHOLD', 2, @isnumeric);
addParameter(p, 'LOCOTHRESHOLD', 100, @isnumeric);
addParameter(p, 'MOUSESIZETHRESHOLD', 5, @isnumeric);
addParameter(p, 'BARPOSITION', [], @isnumeric); % vertical position of the bar, if empty, it will be detected
addParameter(p, 'BARWIDTH', 20, @isnumeric); % thickness of the bar, if empty, it will be detected
% Note: both BARPOSITION and BARTHICKNESS must be provided if one is provided

parse(p, dataPath, fileName, varargin{:});

dataPath      = p.Results.dataPath;
fileName      = p.Results.fileName;
MAKEPLOT      = p.Results.MAKEPLOT;
FRAMERATE     = p.Results.FRAMERATE;      % might be used if readVideoIntoMatrix fails
PIXELSIZE     = p.Results.PIXELSIZE;      % potential future use for distance scaling
SLIPTHRESHOLD = p.Results.SLIPTHRESHOLD;
LOCOTHRESHOLD = p.Results.LOCOTHRESHOLD;
MOUSESIZETH   = p.Results.MOUSESIZETHRESHOLD;
BARPOSITION   = p.Results.BARPOSITION;
BARWIDTH = p.Results.BARWIDTH;

%% --- Check File Existence & Validity ---
fullFilePath = fullfile(dataPath, fileName);

if ~exist(fullFilePath, 'file')
    warning('File does not exist: %s\nAborting...', fullFilePath);
    R = -1;
    return;
end

[~, ~, ext] = fileparts(fileName);
if ~strcmpi(ext, '.mp4')
    warning('File is not an MP4 (%s). Aborting...', ext);
    R = -1;
    return;
end

%% --- Load the Video into a Matrix ---
% readVideoIntoMatrix is assumed to return (videoMatrix, frameRate).
% frameRate is automatically detected from the file if possible.
[videoMatrix, frameRate] = readVideoIntoMatrix(fullFilePath, 'enhanceContrast', false);

% If readVideoIntoMatrix fails to detect, we fallback on user param:
if isempty(frameRate) || (frameRate <= 0)
    frameRate = FRAMERATE;
end
FRAMERATE = floor(frameRate);
%% ===========================================================
%   CROPPING & LAYOUT DETECTION (where we expect the beam and mouse to be)
%   1) Compute a mean frame to see the static background.
%   2) Crop horizontally by ~5% on left & right to remove black edges (for beam detection).
%   3) Identify top & bottom camera edges in that horizontally cropped frame.
%   4) Find the bar's vertical position (top Y) & width in that same frame.
%   5) Finally, crop the original video in vertical dimension to isolate the region
%      between topCameraEdgeY and bottomCameraEdgeY.
%% ===========================================================

% 0 crop top 15%
% this is because of a shadow sometimes seen at the top of the image
videoMatrix = videoMatrix( round(size(videoMatrix, 1) * 0.15):end, :, :);


% 1) Compute mean frame (optionally from the 5 first frames)
%meanFrame = getMeanFrame(videoMatrix(:, :, 1:5));
meanFrame = getMeanFrame(videoMatrix);

% 2) Crop horizontally by 5%
leftCropIndex  = round(size(meanFrame, 2) * 0.05);
rightCropIndex = round(size(meanFrame, 2) * 0.95);
meanFrameCroppedHoriz = meanFrame(:, leftCropIndex:rightCropIndex);

% 3) Identify the camera rectangles (top & bottom)
[topCameraEdgeY, bottomCameraEdgeY] = detectCameras(meanFrameCroppedHoriz);
% These should define the black camera boxes at the top & bottom of the image.

% 4) Locate the balance bar in this horizontally cropped mean frame if not provided
if isempty(BARPOSITION)

[barTopCoord, barThickness] = detectBar(meanFrameCroppedHoriz);
else
    barTopCoord = BARPOSITION;
    barThickness = BARWIDTH;
end
% barYCoordTop is the vertical coordinate of the bar's top edge,
% and barWidth is its estimated thickness.

% 5) Crop the original video vertically using the camera edges
%croppedVideo = videoMatrix(topCameraEdgeY : bottomCameraEdgeY, :, :);
croppedVideo = videoMatrix(topCameraEdgeY : BARPOSITION + BARWIDTH*4, :, :);

% The bar's top coordinate in this newly cropped system is offset:
barYCoordTopCrop = barTopCoord - topCameraEdgeY;
% new size of the final cropped video
[imHeight, imWidth, nFrames] = size(croppedVideo);

%% --- Track the Mouse in the Cropped Video ---
[mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, stoppingPeriods, meanPosturalHeight, ...
    mouseMaskMatrix, trackedVideo, croppedOriginalVideo] = trackMouseOnBeam(croppedVideo, MOUSESIZETH, LOCOTHRESHOLD, FRAMERATE);

% Flip mouseCentroids' Y so that top=0 => bar is near zero, easier to
% visualize
mouseCentroids(:, 2) = imHeight - mouseCentroids(:, 2) + 1; % invert vertically
mouseCentroids(:, 2) = mouseCentroids(:,2) - barYCoordTopCrop; % shift so bar is at ~0

%% --- Define "Under the Bar" Region ---
% We'll examine slip movements in a band below the bar region, e.g., barY + half bar thickness
underBarStart = barYCoordTopCrop + barThickness/2;
underBarEnd   = barYCoordTopCrop + barThickness*2;
underBarCroppedVideo = trackedVideo( underBarStart:underBarEnd, :, : );

%% --- Probability Mask for Mouse Columns ---
% we weight them by how much of "mouse" each column has. So tail will not
% count so much. 
[normMouseProbVals, mouseProbMatrix] = computeMouseProbabilityMap(mouseMaskMatrix);

%% --- Quantify Weighted Movement  under the bar (Slip Indicator) ---
movementTrace = computeWeightedMovement(underBarCroppedVideo, normMouseProbVals);

%% --- Detect Slips from Movement Trace ---
[slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations] = ...
    detectSlips(movementTrace, SLIPTHRESHOLD);

%% --- Annotate the Original (Tracked) Video with Slip Intervals ---
annotatedVideo = annotateVideoMatrix(trackedVideo, slipEventStarts, slipEventDurations, ...
    'ShapeType','FilledRectangle','ShapeColor','red');

%% --- Store Results in Output Structure ---
R.mouseCentroids       = mouseCentroids;
R.forwardSpeeds        = forwardSpeeds;
R.traverseDuration     = traverseDuration;
R.meanSpeed            = meanSpeed;
R.BBvideo              = trackedVideo;

R.slipEventStarts      = slipEventStarts;
R.slipEventAreas       = slipEventAreas;
R.slipEventDurations   = slipEventDurations;
R.slipEventPeaks       = slipEventPeaks;
R.nSlips               = length(slipEventStarts);
R.totalSlipMagnitude   = sum(slipEventAreas);
R.meanSlipAmplitude    = mean(slipEventAreas);

R.nStops = length(stoppingPeriods);
R.stoppingPeriods = stoppingPeriods;
R.stoppingDurations = cellfun(@(x) diff(x)+1, stoppingPeriods);


R.annotatedVideo       = annotatedVideo;

%% --- Generate Plots if Requested ---
if MAKEPLOT
    % 1) Plot the movement trace with slip events
    plotBBtrial(movementTrace, FRAMERATE, slipEventStarts, slipEventAreas, ...
        mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, ...
        meanPosturalHeight, fileName );

    % 2) Display annotated video with an interactive UI
    displayBehaviorVideoMatrix(annotatedVideo, cleanUnderscores(fileName), movementTrace);
end

end

