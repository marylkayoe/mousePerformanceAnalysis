function [stoppingFrames, stoppingStartStops] = detectStoppingOnBeam(speedArray, LOCOTHRESHOLD, FRAMERATE)
% DETECTSTOPPINGONBEAM Identifies stopping periods on a balance beam.
%
%   [stoppingFrames, stoppingDurations] = detectStoppingOnBeam(speedArray, LOCOTHRESHOLD)
%
%   INPUT:
%       speedArray    - (Nx1 array) Speed values over time.
%       LOCOTHRESHOLD - (scalar) Threshold below which the mouse is considered to be stopping.
%
%   OUTPUT:
%       stoppingFrames  - (Nx1 logical array) Binary mask indicating stopping frames.
%       stoppingPeriods - (cell array) Start and end indices of stopping periods.
%
%   ALGORITHM:
%     1) Threshold the speed array to define initial stopping periods.
%     2) Use morphological closing to fill small gaps.
%     3) Remove very short stopping periods using `bwareaopen`.
%     4) Expand stopping periods using convolution with a box filter to account for slowing down and speeding up.
%     5) Identify contiguous stopping periods and extract start/end frames.


if ~exist('LOCOTHRESHOLD', 'var')
    LOCOTHRESHOLD = 40; % Default threshold for stopping (in pixels/sec)
end
if ~exist('FRAMERATE', 'var')
    FRAMERATE = 160; % Default frame rate (in frames/sec)
end
if ~isvector(speedArray) || ~isnumeric(speedArray)
    error('Input speedArray must be a numeric vector.');
end
% Step 1: Define stopping frames
stoppingFrames = speedArray < LOCOTHRESHOLD;

% Step 2: Close small gaps
maxGapDuration = 5; % frames
stoppingFrames = imclose(stoppingFrames, strel('line', maxGapDuration, 0));

% Step 3: Remove short stops
minDuration = 10; % frames
stoppingFrames = bwareaopen(stoppingFrames, minDuration);

% Step 4: Smooth transitions
expansionSize = floor(FRAMERATE/16); % e.g., 0.25 sec window
if mod(expansionSize, 2) == 0
    expansionSize = expansionSize + 1; % ensure odd-sized kernel
end
kernel = ones(1, expansionSize);
stoppingFrames = conv(double(stoppingFrames), kernel, 'same') > 0;

% Step 5: Get start-stop frame pairs
cc = bwconncomp(stoppingFrames);
stoppingStartStops = cell2mat(cellfun(@(x) [x(1), x(end)], cc.PixelIdxList, 'UniformOutput', false)');

end