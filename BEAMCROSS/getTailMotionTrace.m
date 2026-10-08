function normTailMovementTrace = getTailMotionTrace(videoMatrix, noMouseProbVals, varargin)
%%  getTailMotionTrace
%   Computes the tail movement trace from the video matrix, excluding
%   stopping frames and without normalizing by forward speed.
%   the noMouseProbVals input contains for each frame a vector of probabilities of how much mouse is there in each vertical column of the video.
%   Obviously this assumes the mouse is going across the video horizontally. 
%   TODO: make it so that we only look at pixels BEHIND the mouse
%.  SPECIFICALLY: only show the frames from mouse centroid backwards to make it faster
%   Inputs:
%       videoMatrix      : 3D matrix of video frames (height x width x nFrames)
%       noMouseProbVals  : matrix of probabilities indicating absence of mouse (width x nFrames)

%   varargin         : additional optional parameters
%   stoppingFrames          : logical mask of frames to suppress (typically locomotor pauses)
%   smoothFactor            : temporal smoothing window for the movement trace
%   speedWindow             : multiplicative constant applied during speed normalization
%   excludeStoppingFrames   : zero out movement at stopping frames before/after speed scaling, default false for tail
%   verticalWeightPower      : exponent applied to vertical weights, default 1

% OUTPUT:
%       tailMovementTrace: vector of tail movement values (nFrames x 1)
%
%parse inputs
p = inputParser;
addParameter(p, 'stoppingFrames', false(size(videoMatrix, 3), 1), @(x) islogical(x) && numel(x) == size(videoMatrix, 3));
addParameter(p, 'smoothFactor', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'speedWindow', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'excludeStoppingFrames', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'verticalWeightPower', 3, @(x) isnumeric(x) && isscalar(x));
parse(p, varargin{:});
stoppingFrames = p.Results.stoppingFrames;
smoothFactor = p.Results.smoothFactor;
excludeStoppingFrames = p.Results.excludeStoppingFrames;
verticalWeightPower = p.Results.verticalWeightPower;


nFramesVideo = size(videoMatrix, 3);


% check if we have stopping frames specified and ensure they match the number of video frames

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
% this is based on the idea that when mouse is well balanced, the tail is held up and straight. 
% so if it swings to either side of the mouse body (that is, it gets low), the mouse has needed to correct its balance.
% so movement that happens high is less significant for balance correction.
% this function is receiving videos that have regions both below and above the bar included. 


height    = size(videoMatrix, 1);
rowIdx    = (0:height-1)' / (height-1);      % 0 top → 1 bottom
rowWeights = rowIdx + eps; % starting from nonzero
rowWeights = rowWeights .^ verticalWeightPower; % apply vertical weighting power, higher values emphasize lower rows more
rowWeights = rowWeights / max(rowWeights);   % normalize so bottom = 1

% Convert video to double once
videoDouble = im2double(videoMatrix);

% Compute absolute difference across frames in one operation
videoDiff = abs(diff(videoDouble, 1, 3));  % size: [height x width x (nFrames-1)]
 videoDiff   = videoDiff .* reshape(rowWeights, [], 1, 1);
% Sum pixel differences column-wise (collapse rows)
colDiffSum = squeeze(sum(videoDiff, 1));   % size: [width x (nFrames-1)]

% Square the normMouseProbVals to enhance differences
weightedProbs = noMouseProbVals(:, 2:end).^2;  % size: [width x (nFrames-1)]

% Element-wise multiplication and sum columns for each frame (vectorized)
tailMovementTrace = sum(colDiffSum .* weightedProbs, 1)'; % size: [(nFrames-1) x 1]

% Insert 0 at first frame since no prior frame
tailMovementTrace = [0; tailMovementTrace];

tailMovementTrace = smooth(tailMovementTrace, smoothFactor);

% Robust normalization using Median Absolute Deviation (MAD)
medVal = median(tailMovementTrace, "omitnan");
madVal = median(abs(tailMovementTrace - medVal), "omitnan");
sigma_base = 1.4826 * madVal;
normTailMovementTrace = (tailMovementTrace - medVal) / sigma_base;

% make negative values zero
normTailMovementTrace(normTailMovementTrace < 0) = 0;

% make nan values zero
normTailMovementTrace(isnan(normTailMovementTrace)) = 0;

end
