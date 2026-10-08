function normMovementTrace = computeWeightedMovementTrace(videoMatrix, normMouseProbVals, forwardSpeeds, varargin)
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
