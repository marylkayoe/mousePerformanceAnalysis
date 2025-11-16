function R = BBanalysisSingleFile(dataPath, fileName, varargin)
% BBANALYSISSINGLEFILE  Analyze a single balance-beam video file.
%
%   R = BBanalysisSingleFile(dataPath, fileName, ...)
%
% This function  is used to analyze single balance beam video files.
% the mp4 video is expected to contain a black mouse walking on a white-ish balance beam.
% The background is expected to be static and white-ish.
% The function will identify the position of the bar, and quanttify amount of movement seen under the bar.
% Movement under the bar indicates slips. Importantly, in order to avoid confounding movement of the tail,
% the movement is weighted by the position of the mouse above the bar, so that only slips that are seen
%  UNDER the mouse count.
%
% REQUIRED INPUTS:
%   dataPath  : (char) Directory containing the video file.
%   fileName  : (char) Name of the .mp4 video file to analyze.
%
% OPTIONAL PARAMETERS (Name-Value pairs via varargin):
%   'MAKEPLOT'      : (logical) Whether to produce plots. [true]
%   'FRAMERATE'     : (numeric) Frame rate used if not detected from file. [160]
%   'PIXELSIZE'     : (numeric) Spatial scaling factor (pixels to mm, etc.). [1]
%   'SLIPTHRESHOLD' : (numeric) Threshold for slip detection in z-scored(ish)
%                     movement trace. [2]
%   'LOCOTHRESHOLD' : (numeric) Threshold for stopping detection in pixels/sec. [100]
%   'MOUSESIZETHRESHOLD' : (numeric) Minimum fraction of frame area (0-100) for mouse, used for tracking. [5]
%   'BARPOSITION'   : (numeric) Vertical position of the bar in pixels. If empty, it will be detected. []
%   'BARWIDTH'      : (numeric) Width of the bar in pixels. If empty, it will be detected. []
%   'mouseStartPosition' : "L" or "R", indicating the mouse's starting position on the beam.
%                   if not given, we will assume that trials with CAM1 it's L, and CAM2 it's R.
%   'meanImageFrames' : array of frame indices to use for mean image calculation. default: [1:5].
%                       If there's a lot of movement at the beginning of the video, it might be better to
%                       use a different set of frames, eg last 5 frames.
%   'SHOWVIDEOS' : show the videos of movement under bar, if you want to check the limits [false]
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
%
%   Negative or error returns:
%       R = -1 if the file does not exist or is not an .mp4.
%
% USAGE EXAMPLE:
%   R = BBanalysisSingleFile('/myData/', 'mouse1_trialA.mp4', ...
%       'MAKEPLOT', true, 'SLIPTHRESHOLD', 2.5);
%
% DEPENDENCIES:
%   readVideoIntoMatrix, getMeanFrame, detectBar, trackMouseOnBeam,
%   detectStoppingOnBeam, detectSlips, computeMouseProbabilityMap,
%   computeWeightedMovement, getMouseProbOnBeam, displayBehaviorVideoMatrix,
%   annotateVideoMatrix, plotBBtrial, cleanUnderscores
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
addParameter(p, 'SHOWVIDEOS', false, @islogical); % show the video of movement under bar
addParameter(p, 'CROPVIDEOSCALE', 4, @isnumeric); % how much to crop above and below the bar (multiplies of bar width)


parse(p, dataPath, fileName, varargin{:});

dataPath      = p.Results.dataPath;
fileName      = p.Results.fileName;
MAKEPLOT      = p.Results.MAKEPLOT;
FRAMERATE     = p.Results.FRAMERATE;      % might be used if readVideoIntoMatrix fails
PIXELSIZE     = p.Results.PIXELSIZE;      % potential future use for distance scaling
SLIPTHRESHOLD = p.Results.SLIPTHRESHOLD;
LOCOTHRESHOLD = p.Results.LOCOTHRESHOLD;
MOUSESIZETH   = p.Results.MOUSESIZETHRESHOLD; % on short beam, 5; long beam, 2
BARPOSITION   = p.Results.BARPOSITION;
BARWIDTH      = p.Results.BARWIDTH;
mouseStartPosition = p.Results.mouseStartPosition;
meanImageFrames = p.Results.meanImageFrames;
SHOWVIDEOS = p.Results.SHOWVIDEOS;
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
[videoMatrix, frameRate] = readBBVideoIntoMatrix(fullFilePath);

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
FRAMERATE = round(frameRate);

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


%% real work starts here
% 1) --- Compute mean frame from the frames specified in meanImageFrames (default: 1:5)
meanFrame = getMeanFrame(videoMatrix(:, :, meanImageFrames));

% 2) --- Locate the balance bar in this horizontally cropped mean frame if not provided
if isempty(BARPOSITION)
    [barTopCoord, barThickness, barCenter] = detectBar(meanFrame, 'mouseStartPosition', mouseStartPosition, 'MAKEDEBUGPLOT',false);
    if isempty(barTopCoord)
        warning('Bar position not detected in file %s. Aborting...', fileName);
        R = -1;
        return;
    end
else
    barTopCoord = BARPOSITION;
    barThickness = BARWIDTH;
end

%% 3) --- Crop the original video vertically ---

[imHeight, ~, ~] = size(videoMatrix);
cropRange = round(barTopCoord + barThickness * CROPVIDEOSCALE * [-1,1]);
cropRange = max(min(cropRange, imHeight), 1); % efficient bounding
croppedVideo = videoMatrix(cropRange(1):cropRange(2), :, :);
barTopCoord = barThickness * CROPVIDEOSCALE;


[imHeight, ~, nFrames] = size(croppedVideo);
USEMORPHOCLEAN = false;
UNDERBARWINDOW = 1.5;
mouseContrastThreshold = 0.6;

%% 4)  --- Track the Mouse in the Cropped Video ---
[mouseCentroids, forwardSpeeds, meanSpeed, traverseDuration, stoppingStartStops, stoppingFrames, ...
    meanSpeedLoco, stdSpeedLoco, mouseMaskMatrix, trackedVideo, trimmedVideo] = ...
    trackMouseOnBeam(croppedVideo, MOUSESIZETH, LOCOTHRESHOLD, USEMORPHOCLEAN, mouseContrastThreshold, FRAMERATE );

% NOTE: trackedVideo has the mouse overlaid with centroid marker, mouseMaskMatrix is the mask image video
% trimmedVideo is the original video trimmed/cropped

% Flip mouseCentroids' Y so that top=0 => bar is near zero
mouseCentroids(:, 2) = imHeight - mouseCentroids(:, 2) + 1; % invert vertically
mouseCentroids(:, 2) = mouseCentroids(:,2) - barTopCoord; % shift to be relative to bar

%% 5 --- Detect Slips from using the tracked video (mouse is enhanced in it) ---
[slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations, movementTrace, underBarCroppedVideo] = ...
    detectSlips(trackedVideo, mouseMaskMatrix, barTopCoord, barThickness, forwardSpeeds, stoppingFrames, SLIPTHRESHOLD, UNDERBARWINDOW, 10);

%% 6 --- Store Results in Output Structure ---
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

if isempty(stoppingStartStops)
    R.nStops = 0;
    R.stoppingStartStops = [nan nan];
    R.stoppingDurationsTotal = 0;
    R.stoppingDurations = 0;
else
    R.nStops = length(stoppingStartStops(:, 1));
    R.stoppingStartStops = stoppingStartStops;
    R.stoppingDurationTotal = length(stoppingFrames);
    R.stoppingDurations = stoppingStartStops(:, 2) - stoppingStartStops(:, 1) + 1;

end
%% --- Generate Plots & Show Videos if Requested ---
if MAKEPLOT
    plotBBTrial(movementTrace, FRAMERATE, slipEventStarts, slipEventAreas, ...
        mouseCentroids, forwardSpeeds, meanSpeedLoco, ...
        R.meanPosturalHeight, fileName, LOCOTHRESHOLD, ...
        SLIPTHRESHOLD);
end
if SHOWVIDEOS

    % Annotate the tracked Video with Slip Intervals
    annotatedVideo = annotateVideoMatrix(trackedVideo, slipEventStarts, slipEventDurations, ...
        'ShapeType','FilledRectangle','ShapeColor','red', ...
        'EventStarts2',R.stoppingStartStops(:,1), ...
        'EventDurations2',R.stoppingDurations, 'EventLabel1', 'slip', 'EventLabel2','Stop');

    displayBehaviorVideoMatrix(annotatedVideo, cleanUnderscores(fileName), (1:nFrames) ./FRAMERATE);
    displayBehaviorVideoMatrix(mouseMaskMatrix, 'Binary mask');
    displayBehaviorVideoMatrix(underBarCroppedVideo, 'UnderBarVideo', movementTrace);
    displayBehaviorVideoMatrix(trimmedVideo, 'Frame-trimmed , cropped video', forwardSpeeds);
end

end

