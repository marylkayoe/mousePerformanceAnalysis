function [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds, isLocomoting] = getSpeedMeasures(mouseTrajectory, FRAMERATE, dataDescriptor)
%GETSPEEDMEASURES Calculate various speed measures from a mouse trajectory.
%
%   [instSpeeds, meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting] = GETSPEEDMEASURES(mouseTrajectory, FRAMERATE, dataDescriptor)
%   calculates the instantaneous speeds, mean speed, max speed, locomotion time, total distance, total distance while locomoting, and mean speed while locomoting from the input mouse trajectory. It also optionally takes a data descriptor for plot labeling.
%
%   Inputs:
%   - mouseTrajectory: A gap-filled (nan-free) trajectory from which we
%   want speed. Can be 1D, 2D, or 3D. Assumed to be in mm.
%   - FRAMERATE: The framerate of the data.
%   - dataDescriptor (optional): A string to be used as a label in the plot title.
%
%   Outputs:
%   - instSpeeds: A single-column vector with instantaneous speeds (mm/sec).
%   - meanSpeed: Mean speed of the mouse.
%   - maxSpeed: Maximum speed of the mouse.
%   - locoTime: Time spent locomoting (in seconds), defined as the time the instantaneous speed was above a threshold (default 40).
%   - totalDistance: Total distance traveled by the mouse.
%   - totalDistanceLocomoting: Total distance traveled by the mouse while locomoting.
%   - meanSpeedLocomoting: Mean speed of the mouse while locomoting.
%


    % Set the default locomotion threshold
    LOCOTHRESHOLD = 40;

    % Validate the input trajectory
    [nRows, nCols] = size(mouseTrajectory);

    if nCols > nRows || nCols < 1 || nCols > 3
        error('Invalid trajectory matrix: should have more rows than columns and 1-3 columns for 1-3D movement');
    end

    % Gap-fill the trajectory
    gapFilledTrajectory = gapFillTrajectory(mouseTrajectory);

    % Calculate instantaneous speeds using getMouseSpeedFromTraj
    instSpeeds = getMouseSpeedFromTraj(gapFilledTrajectory, FRAMERATE);
    [~, isLocomoting] = getLocoFrames(instSpeeds, LOCOTHRESHOLD);
    % Compute mean and max speeds
    meanSpeed = nanmean(instSpeeds);
    meanSpeedLocomoting = nanmean(instSpeeds(isLocomoting));

    maxSpeed = max(instSpeeds);

    % advanced measures from the speed array
    % Calculate total distance moved in the trial, 
    % and distance traveled while locomoting 

    totalDistance = nansum(instSpeeds) * (1/FRAMERATE);
    totalDistanceLocomoting = nansum(instSpeeds(isLocomoting)) * (1/FRAMERATE);
    % Get locomotion frames and logical array
    [~, isLocomoting] = getLocoFrames(instSpeeds, LOCOTHRESHOLD);

    % Compute time spent locomoting
    locoTime = sum(isLocomoting) / FRAMERATE;

    % Placeholder for plotting the data
   % infoString = sprintf('Mean Speed: %.2f mm/s\nMax Speed: %.2f mm/s\nLoco Time: %.2f s\nTotal Distance: %.2f mm\nTotal Distance Locomoting: %.2f mm\nMean Speed Locomoting: %.2f mm/s', meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting);



end
