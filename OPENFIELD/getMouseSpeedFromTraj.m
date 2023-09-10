function [instSpeeds] = getMouseSpeedFromTraj(traj, FRAMERATE, speedWindow)

    % purpose is to get the speed of the entire mouse
    % extreme outliers are removed
    % for individual limbs or body parts, use getVelocityFromTraj

    % inputs :
    % traj: gap-filled (nan-free) trajectory from which we want speed
    % can be 1D, 2D, 3D
    % FRAMERATE: framerate of the data

    % returns a single-column vector with instantaneous speeds (units/sec)
    % default window for speed is one second, i.e. FRAMERATE frames
    % if want to use something else, give the number of frames in speedWindow

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

    %  initialize output vector with nans
    [nFrames nDIMs] = size (traj);
    instSpeeds = nan(nFrames, 1);

    % check that the trace is long enough ...
    if speedWindow > nFrames
        warning('speedWindow is too large compared to the length of the trajectory. Reducing speedWindow to match the trajectory length.');
        speedWindow = nFrames;
    end

    % calculate distance between points that are speedWindow frames apart:
    diffTraj = traj(1 + speedWindow:nFrames, :) - traj(1:nFrames - speedWindow, :);

    % Calculate Euclidean distances between the current point and a point speedWindow frames into the future
    % this is to avoid influence of measurement noise
    distances = vecnorm(diffTraj, 2, 2);

    % Divide the distances by the time window (in seconds) to obtain the instantaneous speeds
    timeWindow = speedWindow / FRAMERATE;
    instSpeeds = distances / timeWindow;

    % Pad the end of instSpeeds with NaNs to match the length of the input trajectory
    instSpeeds(end + 1:end + speedWindow - 1, :) = NaN;
    % Outlier detection window size: either FFT-guided (NOT PROVEN)
    %outlierWindow = selectOptimalOutlierWindow(instSpeeds(1:end-speedWindow), FRAMERATE);
    %  or just simply 4x speedWindow (WORKS)
    outlierWindow = 4 * speedWindow;

     % Detect outliers using a moving median approach
    OL = isoutlier(instSpeeds, 'movmedian', outlierWindow);

    % Replace outliers with NaN
    if any(OL)
        %disp(['removing speed outliers in time window of ' num2str(outlierWindow)]);
        instSpeeds(OL) = nan;
        % Gap fill the trajectory where outliers were found
        instSpeeds = gapFillTrajectory(instSpeeds);
    end

end
