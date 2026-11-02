function [instSpeeds] = getMouseSpeedFromTraj(traj, FRAMERATE, speedWindow, outlierWindowFactor)

    % Calculate whole-mouse speed from displacement over a sliding window.
    % traj: gap-filled positions, samples in rows and 1-3 coordinates in columns.
    % FRAMERATE: frames per second (default 300).
    % speedWindow: displacement window in frames (default FRAMERATE, one second).
    % outlierWindowFactor: moving-median window in multiples of speedWindow (default 4).
    % instSpeeds: processed speed in coordinate units per second, as a column vector.
    % A trajectory of N positions gives N-1 speed values, including end padding.
    % Speed outliers are replaced by interpolation; see padding note below.

    % validate input arguments, can't be empty or have nans
    if isempty(traj) || any(isnan(traj(:)))
        warning ('empty trajectory or trajectory with gaps used for speed calculation, gapfill first if possible');
        instSpeeds = [];
        return;
    end

    if ~exist('FRAMERATE', 'var')
        disp ('defaulting to framerate 300');
        FRAMERATE = 300;
    end

    if ~exist('speedWindow', 'var')
        speedWindow = FRAMERATE;
    end

    if ~exist('outlierWindowFactor', 'var')
        outlierWindowFactor = 4;
    end

    nFrames = size(traj, 1);

    % One displacement needs at least speedWindow + 1 positions.
    if nFrames <= speedWindow
        warning('Trajectory must be longer than speedWindow.');
        instSpeeds = [];
        return;
    end

    % Moving-median window for outlier detection, in frames.
    outlierWindow = outlierWindowFactor * speedWindow;

    % calculate distance between points that are speedWindow frames apart:
    diffTraj = traj(1 + speedWindow:nFrames, :) - traj(1:nFrames - speedWindow, :);

    % Calculate Euclidean distances between the current point and a point speedWindow frames into the future
    % this is to avoid influence of measurement noise
    distances = vecnorm(diffTraj, 2, 2);

    % Convert the frame window to seconds, then divide displacement by time.
    % By default speedWindow equals FRAMERATE, giving displacement over 1 second.
    % The window advances one frame at a time, so consecutive estimates overlap.
    timeWindow = speedWindow / FRAMERATE;
    instSpeeds = distances / timeWindow;

    % N frames give N-speedWindow estimates. Add speedWindow-1 NaNs so the
    % output has N-1 values; the plotting code prepends zero to align with N frames.
    instSpeeds(end + 1:end + speedWindow - 1, :) = NaN;

     % Detect outliers using a moving median approach
    OL = isoutlier(instSpeeds, 'movmedian', outlierWindow);

    % If outliers are found, filling also replaces the padded end with the
    % last valid speed. Otherwise, the padded end remains NaN.
    if any(OL)
        instSpeeds(OL) = nan;
        % Fill the speed values removed as outliers.
        instSpeeds = gapFillTrajectory(instSpeeds);
    end

end
