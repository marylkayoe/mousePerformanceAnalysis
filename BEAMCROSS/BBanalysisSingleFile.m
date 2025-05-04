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
%   'MAKEPLOT'      : (logical) Whether to produce plots. [true]
%   'FRAMERATE'     : (numeric) Frame rate used if not detected from file. [160]
%   'PIXELSIZE'     : (numeric) Spatial scaling factor (pixels to mm, etc.). [1]
%   'SLIPTHRESHOLD' : (numeric) Threshold for slip detection in z-scored
%                     movement trace. [2]
%   'LOCOTHRESHOLD' : (numeric) Threshold for stopping detection in pixels/sec. [100]
%   'MOUSESIZETHRESHOLD' : (numeric) Minimum fraction of frame area (0-100) for mouse, used for tracking. [5]
%   'BARPOSITION'   : (numeric) Vertical position of the bar in pixels. If empty, it will be detected. []
%   'BARWIDTH'      : (numeric) Width of the bar in pixels. If empty, it will be detected. []
%   'mouseStartPosition' : "L" or "R", indicating the mouse's starting position on the beam.
%                   if not given, we will assume that trials with CAM1 it's L, and CAM2 it's R.
%   'meanImageFrames' : array of frame indices to use for mean image calculation. default: [1:5]. In case there's a lot of movement at the beginning of the video, it might be better to use a different set of frames, eg last 5 frames.
%   'SHOWUNDERBARVIDEO' : show the video of movement under bar, if you want
%   to check the limits; defaul is false
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
addParameter(p, 'FRAMERATE', 160, @isnumeric); % used only if readVideoIntoMatrix fails to find it
addParameter(p, 'PIXELSIZE', 1,  @isnumeric);
addParameter(p, 'SLIPTHRESHOLD', 2, @isnumeric);
addParameter(p, 'LOCOTHRESHOLD', 100, @isnumeric);
addParameter(p, 'MOUSESIZETHRESHOLD', 5, @isnumeric);
addParameter(p, 'BARPOSITION', [], @isnumeric); % vertical position of the bar, if empty, it will be detected
addParameter(p, 'BARWIDTH', 20, @isnumeric); % thickness of the bar, if empty, it will be detected
% Note: both BARPOSITION and BARTHICKNESS must be provided if one is provided
addParameter(p, 'mouseStartPosition', [], @(x) ischar(x) || isempty(x)); % "L" or "R", if empty, it will be detected
addParameter(p, 'meanImageFrames', 1:5, @(x) isnumeric(x) && all(x > 0)); % frames to use for mean image calculation
addParameter(p, 'SHOWUNDERBARVIDEO', false, @islogical); % show the video of movement under bar
addParameter(p, 'CROPVIDEOSCALE', 4, @isnumeric); % how much to crop above and below the bar


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
BARWIDTH      = p.Results.BARWIDTH;
mouseStartPosition = p.Results.mouseStartPosition;
meanImageFrames = p.Results.meanImageFrames;
SHOWUNDERBARVIDEO = p.Results.SHOWUNDERBARVIDEO;

CROPVIDEOSCALE = p.Results.CROPVIDEOSCALE; % this is the scale factor for the video cropping, so we will crop 3x the bar thickness above and below the bar
% if the bar is 20 pixels thick, we will crop 60 pixels above and below the top edge bar for tracking and slip detection

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

% if videoMatrix is empty, it means the video could not be read
if isempty(videoMatrix)
    warning('Failed to read video file: %s\nAborting...', fullFilePath);
    R = -1;
    return;
end

% If readVideoIntoMatrix fails to detect, we fallback on user param: (defaults to 160)
if isempty(frameRate) || (frameRate <= 0)
    frameRate = FRAMERATE;
end
FRAMERATE = floor(frameRate);

% if mouseStartPosition is not given, we will assume that trials with CAM1 it's L, and CAM2 it's R.
% so, in CAM1 view the mouse goes from left to right, and in CAM2 view it goes from right to left.
if isempty(mouseStartPosition)
    if contains(fileName, 'CAM1')
        mouseStartPosition = 'L';
    elseif contains(fileName, 'CAM2')
        mouseStartPosition = 'R';
    else
        mouseStartPosition = ''; % default to L if not specified
    end
end


%% ===========================================================
%   CROPPING & LAYOUT DETECTION (where we expect the beam and mouse to be)
%   1) Compute a mean frame to see the static background.
%   2) Find the bar's vertical position (top Y) & width in that same frame.
%   3) Crop the original video to 3x the bar thickness above and below the bar.
%   6) Track the mouse in the cropped video, detecting its centroid and speed.
%   7) Define the "under the bar" region for slip detection.
%   8) Movement is computed in this region, weighted by the mouse's position above the movement

%% ===========================================================

% 0 crop top 15%
% this is because of a shadow sometimes seen at the top of the image (shadow of the hand)
%videoMatrix = videoMatrix(round(size(videoMatrix, 1) * 0.15):end, :, :);


% 1) Compute mean frame from the frames specified in meanImageFrames (default: 1:5)
% if there's a lot of movement at the beginning of the video, it might be better to use a different set of frames, eg last 5 frames.
meanFrame = getMeanFrame(videoMatrix(:, :, meanImageFrames));

% 4) Locate the balance bar in this horizontally cropped mean frame if not provided
if isempty(BARPOSITION)
    [barTopCoord, barThickness] = detectBar(meanFrame, mouseStartPosition, 'MAKEDEBUGPLOT',true);
    if isempty(barTopCoord)
        warningmsg = sprintf('Bar position not detected in file %s. Aborting...', fileName);
        warning(warningmsg);
        R = -1;
        return;
    end
else
    barTopCoord = BARPOSITION;
    barThickness = BARWIDTH;
end

% 5) Crop the original video vertically
% the limits are defined based on the bar width
% barTopCoord is the top of the bar, so we want to crop CROPVIDEOSCALE x the bar thickness above and below

croppedVideo = videoMatrix(barTopCoord-barThickness*CROPVIDEOSCALE : barTopCoord + barThickness*CROPVIDEOSCALE, :, :);

% The bar's top coordinate in this newly cropped system is offset:
barYCoordTopCrop = barThickness*CROPVIDEOSCALE;
% new size of the final cropped video
[imHeight, ~, ~] = size(croppedVideo);

%% --- Track the Mouse in the Cropped Video ---
[mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, stoppingPeriods, meanSpeedLoco, stdSpeedLoco, mouseMaskMatrix, trackedVideo, trimmedVideo] =...
    trackMouseOnBeam(croppedVideo, MOUSESIZETH, LOCOTHRESHOLD, FRAMERATE );

% Flip mouseCentroids' Y so that top=0 => bar is near zero, easier to
% visualize
mouseCentroids(:, 2) = imHeight - mouseCentroids(:, 2) + 1; % invert vertically
mouseCentroids(:, 2) = mouseCentroids(:,2) - barYCoordTopCrop; % shift so bar is at ~0

%% --- Define "Under the Bar" Region ---
% We'll examine slip movements in a band below the bar region
% start: a bit below the midpoint of the bar
% end: 2x the bar thickness below the bar (+5 pixels)
underBarStart = round(barYCoordTopCrop + barThickness/2)+5;
underBarEnd   = round(barYCoordTopCrop + barThickness*2)+5;
underBarCroppedVideo = trackedVideo( underBarStart:underBarEnd, :, : );


%% --- Probability Mask for Mouse Columns ---
% we weight them by how much of "mouse" each column has. So tail will not
% count so much.
[normMouseProbVals, ~] = computeMouseProbabilityMap(mouseMaskMatrix);

%% --- Quantify Weighted Movement  under the bar ---
movementTrace = computeWeightedMovement(underBarCroppedVideo, normMouseProbVals);

%% --- Detect Slips from Movement Trace ---
DETRENDWINDOW  = 64;
[slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations] = ...
    detectSlips(movementTrace, SLIPTHRESHOLD, DETRENDWINDOW);

%% --- Annotate the Original (Tracked) Video with Slip Intervals ---
annotatedVideo = annotateVideoMatrix(trackedVideo, slipEventStarts, slipEventDurations, ...
    'ShapeType','FilledRectangle','ShapeColor','red');

%% --- Store Results in Output Structure ---
R.mouseCentroids       = mouseCentroids;
R.forwardSpeeds        = forwardSpeeds;
R.traverseDuration     = traverseDuration;
R.meanSpeed            = meanSpeed;
R.meanSpeedLoco        = meanSpeedLoco;
R.stdSpeedLoco         = stdSpeedLoco;
R.BBvideo              = trackedVideo;

R.slipEventStarts      = slipEventStarts;
R.slipEventAreas       = slipEventAreas;
R.slipEventDurations   = slipEventDurations;
R.slipEventPeaks       = slipEventPeaks;
R.nSlips               = length(slipEventStarts);
R.totalSlipMagnitude   = sum(slipEventAreas);
R.meanSlipAmplitude    = mean(slipEventAreas);

R.meanPosturalHeight = mean(mouseCentroids(:, 2), 'omitnan');
R.stdPosturalHeight = std(mouseCentroids(:, 2), 'omitnan');

R.nStops = length(stoppingPeriods);
R.stoppingPeriods = stoppingPeriods;
R.stoppingDurations = cellfun(@(x) diff(x)+1, stoppingPeriods);


R.annotatedVideo       = annotatedVideo;

%% --- Generate Plots if Requested ---
if MAKEPLOT
    % 1) Plot the movement trace with slip events
    plotBBtrial(movementTrace, FRAMERATE, slipEventStarts, slipEventAreas, ...
        mouseCentroids, forwardSpeeds, meanSpeedLoco, ...
        R.meanPosturalHeight, fileName, LOCOTHRESHOLD, ...
        SLIPTHRESHOLD);

    % 2) Display annotated video with an interactive UI
    displayBehaviorVideoMatrix(annotatedVideo, cleanUnderscores(fileName), movementTrace);

    displayBehaviorVideoMatrix(mouseMaskMatrix, 'Binary mask');

    if SHOWUNDERBARVIDEO
        displayBehaviorVideoMatrix(underBarCroppedVideo, 'UnderBarVideo');
    end

    displayBehaviorVideoMatrix(trimmedVideo, 'Frame-trimmed , cropped video');
end

end

