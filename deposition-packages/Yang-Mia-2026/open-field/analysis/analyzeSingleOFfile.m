function [meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, centerFraction, instSpeeds] = analyzeSingleOFfile(dataFolder, fileName, PIXELSIZE, MAKEPLOTS, BORDERLIMIT, LOCOTHRESHOLD)
% Analyze one prepared MP4 recording; video conversion is a separate step.
% PIXELSIZE: mm per pixel in the analyzed video (default 2 for our 2x-downsampled recordings).
% MAKEPLOTS: show trial plots (default 0).
% BORDERLIMIT: border fraction on each side of the trajectory range (default 0.15).
% LOCOTHRESHOLD: locomotion threshold in mm/s (default 40).
% Speeds are in mm/s; times in seconds; distances in mm.
% centerFraction is the original rounded percentage (0-100).
% Speed is based on displacement over a one-second window; locomotion is >40 mm/s.

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

% definition of what is considered the border region in the open field arena
% fraction of the arena considered as the border region
if ~exist('BORDERLIMIT', 'var')
    BORDERLIMIT = 0.15;
end

% this is our standard locomotion threshold in mm/s for defining locomotion bouts
if ~exist('LOCOTHRESHOLD', 'var')
LOCOTHRESHOLD = 40;
end
 % how many mm per pixel
if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 2;
end

% Read the video into a 3D matrix (height x width x frames)
[videoMatrix, FRAMERATE] = readVideoIntoMatrix(fullfile(dataFolder, fileName));

% track the mouse; result is matrix of centroid coordinates (x, y) per frame
centroidCoords = trackMouseInOF(videoMatrix, PIXELSIZE);

% Fill missing positions before calculating speed.
gapFilledTrajectory = gapFillTrajectory(centroidCoords);

[~, fileIDstring] = fileparts(fileName);

[meanSpeed, maxSpeed, locoTime, totalDistance, totalDistanceLocomoting, meanSpeedLocomoting, instSpeeds] = ...
getLocomotionMeasures(gapFilledTrajectory, FRAMERATE, LOCOTHRESHOLD);
[centerFrames, ~, centerFraction] = getCenterBorderFrames(gapFilledTrajectory, BORDERLIMIT);

if MAKEPLOTS
    % Pad the speed array for plotting against the full trajectory.
    plotTrialSpeedData(instSpeeds, LOCOTHRESHOLD, FRAMERATE, fileIDstring);
    plotOpenFieldTrial(gapFilledTrajectory, [0; instSpeeds], centerFrames, BORDERLIMIT, FRAMERATE, PIXELSIZE, fileIDstring);
end
end
