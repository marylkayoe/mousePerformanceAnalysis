function [slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations, movementTrace, underBarCroppedVideo] = ...
    detectSlips(trackedVideo, mouseMaskMatrix, barTopCoord, barThickness, forwardSpeeds, stoppingFrames, SLIPTHRESHOLD, UNDERBARSCALE, underBarSmoothFactor, LOCOTHRESHOLD)
% DETECTSLIPS  Quantify under-bar movement and flag slip episodes.
%
%   [starts, peaks, areas, durations, movementTrace, underBarVideo] = detectSlips(...)
%
%   INPUTS
%       trackedVideo        : height x width x nFrames video where mouse is enhanced.
%       mouseMaskMatrix     : logical mask (same size as trackedVideo) showing mouse pixels.
%       barTopCoord         : vertical coordinate of bar top (pixels).
%       barThickness        : bar thickness (pixels).
%       forwardSpeeds       : nFrames x 1 vector of horizontal speeds (pixels/sec).
%       stoppingFrames      : logical nFrames x 1 mask; true where mouse is stopped.
%       SLIPTHRESHOLD       : slip-detection threshold on normalized movement (default 2).
%       UNDERBARSCALE       : scale factor for the under-bar region thickness.
%       underBarSmoothFactor: smoothing window (frames) for the movement trace.
%       LOCOTHRESHOLD       : locomotion threshold used for speed-based normalization.
%
%   OUTPUTS
%       slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations :
%           per-slip metrics derived from the normalized movement trace. Areas are
%           the sum of positive residuals above SLIPTHRESHOLD (no negatives).
%       movementTrace       : normalized, non-negative 1D trace of weighted movement.
%       underBarCroppedVideo: video region used for slip extraction.
%
%   PIPELINE
%     1) Crop video to a band below the bar.
%     2) Weight frame-to-frame differences by mouse-column probability and vertical distance.
%     3) Normalize motion by local MAD and locomotor speed (fast movement down-weights slips).
%     4) Threshold, morphologically merge short gaps, and remove slip bursts shorter than SLIPSIZEFACTOR.
%     5) Measure per-event start, peak, duration, and area above threshold.

if ~exist('SLIPTHRESHOLD', 'var')
    SLIPTHRESHOLD = 2; % for detecting smaller events, decrease this value
end

if ~exist('underBarSmoothFactor', 'var')
    underBarSmoothFactor = 5; % rolling window, with 160 fps this is 0.4 sec
end

if ~exist('UNDERBARSCALE', 'var')
    UNDERBARSCALE = 2; % scale factor for the under-bar region (related to bar thickness) - this should NOT be much larger than the region into which mouse paw can reasonably reach!
end

BARADJUSTVALUE = 3; % this shifts the position where slips are detected downwards... use if bar detection fails
SLIPSIZEFACTOR = 5; % minimum slip duration in frames
normalizeMovementSpeed = true; % normalize by forward speed

% default output values
slipEventStarts = [];
slipEventPeaks = [];
slipEventAreas = [];
slipEventDurations = [];

disp('Detecting slips...');

%% --- Define "Under the Bar" Region ---
% We'll examine slip movements in a band below the bar region
% start: BARADJUSTVALUE px below midpoint of the bar
% end: UNDERBARSCALE x the bar thickness below the bar (+BARADJUSTVALUE pixels)
videoHeight = size(trackedVideo, 1);
underBarStart = round(barTopCoord + barThickness/2)+BARADJUSTVALUE;
underBarEnd   = round(barTopCoord + barThickness*UNDERBARSCALE)+BARADJUSTVALUE;
underBarStart = max(1, min(videoHeight, underBarStart));
underBarEnd   = max(underBarStart, min(videoHeight, underBarEnd));
underBarCroppedVideo = trackedVideo( underBarStart:underBarEnd, :, : );


%% --- Probability Mask for Mouse Columns ---
% we weight them by how much of "mouse" each column has. So tail will not
% count so much.
% we only use the pixels above the bar for this calculation
mouseMaskMatrix = mouseMaskMatrix(1: barTopCoord, :, :);
[normMouseProbVals, ~] = LF_computeMouseProbabilityMap(mouseMaskMatrix);

%% --- Quantify Weighted Movement  under the bar ---

movementTrace = LF_computeWeightedMovement( ...
    underBarCroppedVideo, normMouseProbVals, forwardSpeeds, ...
    'stoppingFrames', stoppingFrames, ...
    'smoothFactor', underBarSmoothFactor, ...
    'normalizeSpeed', normalizeMovementSpeed, ...
    'excludeStoppingFrames', true);


%% SLIP DETECTION
% -- 1) Create a logical mask of slip frames --
slipMask = movementTrace > SLIPTHRESHOLD;  % 1D array; 1 means "potential slip in this frame"

% -- 2) Cleaning up the slip mask --
%  'closing' merges small gaps up to 2 frames wide
% (two slips separted by >SLIPSIZEFACTOR frames of non-slip are merged into one)
se = ones(SLIPSIZEFACTOR,1);  % structuring element of length=3
slipMask = imclose(slipMask, se);

% remove slips shorter than 3 frames:
slipMask = bwareaopen(slipMask, SLIPSIZEFACTOR);

% -- 3) Find contiguous slipping periods --
cc = bwconncomp(slipMask);  % returns connected-component info
nSLIPS = cc.NumObjects;  % number of slip events
if nSLIPS == 0
    warning('No slip events detected.');
    return;
end


% -- 5) Loop through each slip event and calculate properties --
for slip = 1 : nSLIPS
    slipFrames = cc.PixelIdxList{slip};  % frame indices for the s-th slip
    startSlipFrame = min(slipFrames);
    endSlipFrame   = max(slipFrames);

    slipMagnitudes = movementTrace(slipFrames);
    peakSlipValue  = max(slipMagnitudes);

    % "Area above threshold" => sum( (value - threshold) )
    posDiff = max(slipMagnitudes - SLIPTHRESHOLD, 0);
    areaVal = sum(posDiff);

    % collect the results into the output arrays
    slipEventStarts(slip) = startSlipFrame;
    slipEventPeaks(slip)  = peakSlipValue;
    slipEventAreas(slip)  = areaVal;
    slipEventDurations(slip) = endSlipFrame - startSlipFrame + 1;

end
end



function [normMouseProbVals, mouseProbMatrix] = LF_computeMouseProbabilityMap(mouseMaskMatrix)
% COMPUTEMOUSEPROBABILITYMAP Efficiently computes mouse pixel fraction per column per frame.
%
% INPUT:
%   mouseMaskMatrix: logical array (height x width x nFrames), indicating mouse pixels.
%
% OUTPUTS:
%   normMouseProbVals : (width x nFrames), fraction of mouse pixels per column.
%   mouseProbMatrix   : (height x width x nFrames), replicated probability images.

[imHeight, imWidth, nFrames] = size(mouseMaskMatrix);

% 1. Sum mouse-pixels along rows for all frames simultaneously
colSumAllFrames = squeeze(sum(mouseMaskMatrix, 1)); % size: [imWidth x nFrames]

% 2. Convert column-sums to fractions (dividing by height)
normMouseProbVals = colSumAllFrames / imHeight; % [imWidth x nFrames]

% 3. Replicate fractions down the rows to create mouse probability matrix
mouseProbMatrix = repmat(reshape(normMouseProbVals, [1, imWidth, nFrames]), imHeight, 1, 1);

end



function normMovementTrace = LF_computeWeightedMovement(videoMatrix, normMouseProbVals, forwardSpeeds, varargin)
% COMPUTEWEIGHTEDMOVEMENT Computes weighted frame-to-frame motion efficiently.
% stoppingFrames: logical mask (length = nFrames) marking frames where the mouse is stopping.

p = inputParser;
p.FunctionName = 'LF_computeWeightedMovement';

addRequired(p, 'videoMatrix', @(x) isnumeric(x) || islogical(x));
addRequired(p, 'normMouseProbVals', @(x) isnumeric(x));
addRequired(p, 'forwardSpeeds', @(x) isnumeric(x) || islogical(x));
addParameter(p, 'stoppingFrames', [], @(x) islogical(x) || isempty(x));
addParameter(p, 'smoothFactor', 5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'normalizeSpeed', true, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(p, 'LOCOTHRESHOLD', 40, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'speedWindow', 160, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'excludeStoppingFrames', true, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
addParameter(p, 'normalizeByDistanceFromBar', true, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));

parse(p, videoMatrix, normMouseProbVals, forwardSpeeds, varargin{:});
stoppingFrames = p.Results.stoppingFrames;
smoothFactor   = p.Results.smoothFactor;
normalizeSpeed = p.Results.normalizeSpeed;
speedWindow    = p.Results.speedWindow;
LOCOTHRESHOLD  = p.Results.LOCOTHRESHOLD;
excludeStoppingFrames = p.Results.excludeStoppingFrames;
normalizeByDistanceFromBar = p.Results.normalizeByDistanceFromBar;

% Optional parameters summary:
%   stoppingFrames          : logical mask of frames to suppress (typically locomotor pauses)
%   smoothFactor            : temporal smoothing window for the movement trace
%   normalizeSpeed          : whether to scale movement by forward speed
%   speedWindow             : multiplicative constant applied during speed normalization
%   LOCOTHRESHOLD           : kept for compatibility; actual stop mask should come from caller
%   excludeStoppingFrames   : zero out movement at stopping frames before/after speed scaling
%   normalizeByDistanceFromBar : enable/disable vertical weighting of pixel differences

forwardSpeeds = forwardSpeeds(:);
nFramesVideo = size(videoMatrix, 3);

if numel(forwardSpeeds) ~= nFramesVideo
    warning('LF_computeWeightedMovement:SpeedLengthMismatch', ...
        'forwardSpeeds has %d samples, but video has %d frames; truncating to the shorter length.', ...
        numel(forwardSpeeds), nFramesVideo);
    minFrames = min(numel(forwardSpeeds), nFramesVideo);
    forwardSpeeds = forwardSpeeds(1:minFrames);
    videoMatrix = videoMatrix(:, :, 1:minFrames);
    normMouseProbVals = normMouseProbVals(:, 1:minFrames);
    nFramesVideo = minFrames;
end

if isempty(stoppingFrames)
    stoppingFrames = false(nFramesVideo, 1);
else
    stoppingFrames = logical(stoppingFrames(:));
    if numel(stoppingFrames) ~= nFramesVideo
        warning('LF_computeWeightedMovement:StopLengthMismatch', ...
            'stoppingFrames length (%d) differs from video frames (%d); truncating to match.', ...
            numel(stoppingFrames), nFramesVideo);
        minFrames = min(numel(stoppingFrames), nFramesVideo);
        stoppingFrames = stoppingFrames(1:minFrames);
        if minFrames < nFramesVideo
            stoppingFrames(end+1:nFramesVideo, 1) = false;
        end
    end
end

%% Vertical weighting of frame differences
% Rows farther from the bar should contribute more strongly to the movement
% trace (slips happen below the bar). We build a normalized sigmoid profile
% so the top rows are down-weighted and the lower half reaches weight 1.

height    = size(videoMatrix, 1);
rowIdx    = (0:height-1)' / (height-1);      % 0 top → 1 bottom

steepness = 20;                              % larger → sharper rise near midpoint
midpoint  = 0.2;                             % reach weight ~1 before halfway
rowWeights = 1 ./ (1 + exp(-steepness * (rowIdx - midpoint)));
rowWeights = rowWeights / max(rowWeights);   % normalize so bottom = 1




% Convert video to double once
videoDouble = im2double(videoMatrix);

% Compute absolute difference across frames in one operation
videoDiff = abs(diff(videoDouble, 1, 3));  % size: [height x width x (nFrames-1)]


% apply vertical weights to each pixel difference
if normalizeByDistanceFromBar
    videoDiff   = videoDiff .* reshape(rowWeights, [], 1, 1);
end


% Sum pixel differences column-wise (collapse rows)
colDiffSum = squeeze(sum(videoDiff, 1));   % size: [width x (nFrames-1)]

% Square the normMouseProbVals to enhance differences
weightedProbs = normMouseProbVals(:, 2:end).^2;  % size: [width x (nFrames-1)]

% Element-wise multiplication and sum columns for each frame (vectorized)
movementTrace = sum(colDiffSum .* weightedProbs, 1)'; % size: [(nFrames-1) x 1]

% Insert 0 at first frame since no prior frame
movementTrace = [0; movementTrace];

% Set movement to a very small value (eps) at stopping frames if specified
if excludeStoppingFrames
    movementTrace(stoppingFrames) = eps;
end

% Speed-adjusted movement trace: slips during faster locomotion contribute less
% note that the speedWindow scales the effect linearly just for convenience of display
if normalizeSpeed


    logSpeeds = log1p(forwardSpeeds); % log scale to compress high speeds, log1p handles zero safely
    logSpeeds(logSpeeds < 0) = eps;

    movementTrace = movementTrace .* (speedWindow ./ logSpeeds);

    if excludeStoppingFrames
        movementTrace(stoppingFrames) = eps;
    end
end

movementTrace = smooth(movementTrace, smoothFactor);

% Robust normalization using Median Absolute Deviation (MAD)
medVal = median(movementTrace, "omitnan");
madVal = median(abs(movementTrace - medVal), "omitnan");
sigma_base = 1.4826 * madVal;
normMovementTrace = (movementTrace - medVal) / sigma_base;


% make negative values zero
normMovementTrace(normMovementTrace < 0) = 0;

% make nan values zero
normMovementTrace(isnan(normMovementTrace)) = 0;


end
