function [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds, isLocomoting] = getLocomotionMeasures(mouseTrajectory, FRAMERATE, LOCOTHRESHOLD)
% Calculate speed and locomotion measures from a mouse trajectory.
% mouseTrajectory: gap-filled positions in mm, with samples in rows and 1-3 coordinate columns.
% Frames-in-columns input is transposed when there are more columns than rows.
% Empty trajectories or invalid shapes produce a warning and empty outputs.
% Fill any trajectory gaps before calling this function.
% FRAMERATE: samples per second.
% LOCOTHRESHOLD: locomotion threshold in mm/s (optional, default 40).
%
% Outputs, in order:
% meanSpeed: mean processed speed over the recording (mm/s).
% maxSpeed: maximum processed speed (mm/s).
% locoTime: time with speed strictly above LOCOTHRESHOLD (s).
% totalDistance: sum of processed speeds divided by FRAMERATE (mm).
% totalDistanceLocomoting: the same sum restricted to locomotion samples (mm).
% meanSpeedLocomoting: mean speed during locomotion (mm/s).
% instSpeeds: column vector of processed speeds (mm/s).
% isLocomoting: logical vector indicating speeds above LOCOTHRESHOLD.
%
% getMouseSpeedFromTraj uses displacement across a one-second window,
% advanced one frame at a time, with outlier handling. These are whole-mouse
% speeds, not frame-to-frame speeds. Distances integrate this speed estimate;
% they are not sums of frame-to-frame trajectory lengths.
% Means and distance sums omit NaNs; NaN speeds do not count as locomotion.

if ~exist('LOCOTHRESHOLD', 'var')
    LOCOTHRESHOLD = 40;
end

meanSpeed = [];
maxSpeed = [];
locoTime = [];
totalDistance = [];
totalDistanceLocomoting = [];
meanSpeedLocomoting = [];
instSpeeds = [];
isLocomoting = [];

% Arrange frames in rows.
if size(mouseTrajectory, 2) > size(mouseTrajectory, 1)
    mouseTrajectory = mouseTrajectory.';
end

[nRows, nCols] = size(mouseTrajectory);
if isempty(mouseTrajectory) || nCols > 3 || nRows <= nCols
    warning('Trajectory must have frames in rows and 1-3 coordinate columns.');
    return;
end


% Calculate instantaneous speeds using getMouseSpeedFromTraj
instSpeeds = getMouseSpeedFromTraj(mouseTrajectory, FRAMERATE);

[~, isLocomoting] = getLocoFrames(instSpeeds, LOCOTHRESHOLD);
% Compute mean and max speeds
meanSpeed = mean(instSpeeds, 'omitnan');
meanSpeedLocomoting = mean(instSpeeds(isLocomoting), 'omitnan');

maxSpeed = max(instSpeeds);


% Calculate total distance moved in the trial,
% and distance traveled while locomoting

totalDistance = sum(instSpeeds, 'omitnan') * (1/FRAMERATE);
totalDistanceLocomoting = sum(instSpeeds(isLocomoting), 'omitnan') * (1/FRAMERATE);

% Compute time spent locomoting
locoTime = sum(isLocomoting) / FRAMERATE;


end
