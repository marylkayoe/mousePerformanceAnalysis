function [stoppingFrames, stoppingPeriods] = detectStoppingOnBeam(speedArray, LOCOTHRESHOLD, FRAMERATE)
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
        LOCOTHRESHOLD = 100; % Default threshold for stopping (in pixels/sec)
    end
    if ~exist('FRAMERATE', 'var')
        FRAMERATE = 160; % Default frame rate (in frames/sec)
    end

    % Step 1: Define stopping periods
    stoppingFrames = speedArray < LOCOTHRESHOLD;
    
    % Step 2: Fill gaps shorter than 5 frames in stopping periods
    maxGapDuration = 5; % Maximum gap duration in frames
    stoppingFrames = imclose(stoppingFrames, strel('line', maxGapDuration, 0));
    
    % Step 3: Remove short stopping periods
    minDuration = 10; % Minimum stopping duration in frames
    stoppingFrames = bwareaopen(stoppingFrames, minDuration);
    
    % Step 4: Expand stopping periods to include transitions to/from stopping
    % Use a box filter to expand the stopping periods
    expansionSize = floor(FRAMERATE/4); % Number of frames to use for the filter
    if mod(expansionSize, 2) == 0
        expansionSize = expansionSize + 1; % Ensure odd size for the kernel
    end
    kernel = ones(1, expansionSize); % Box kernel for expansion
    stoppingFrames = conv(double(stoppingFrames), kernel, 'same') > 0;
    
    % Step 5: Identify starts and stops of continuous stopping periods
    cc = bwconncomp(stoppingFrames);
    stoppingPeriods = cellfun(@(x) [x(1), x(end)], cc.PixelIdxList, 'UniformOutput', false);
    
    end
    