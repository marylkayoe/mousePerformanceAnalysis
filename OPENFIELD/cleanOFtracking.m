function [cleanSpeeds, cleanCentroids, cleanMouseMatrix] = cleanOFtracking(centroidSpeeds,centroids, mouseMatrix, FRAMERATE, minCentroidSpeed, maxStationaryFrames)
    % cleaning up tracking data, used in the context of under-floor filming with gopro
    % in these files the mouse is often outside (the FoV was too narrow!) and the trackingis noisy.
    % Here we decide that if the centroid speed is less than minCentroidSpeed for longer than maxStationaryFrames, then we will set the centroid to NaN for those frames. This is to avoid having a lot of noise in the tracking data when the mouse is not detected. 
    % the frames with nan will be removed from the trajectory and the matrix.

    % inputs:
    % centroidSpeeds: nFrames x 2 matrix of centroid coordinates (x,y)
    % mouseMatrix: nRows x nCols x nFrames matrix of the masked video (the frames where the mouse is not detected should be all zeros)
    % minCentroidSpeed: the minimum speed (in pixels/frame) that the centroid must have to be considered as "moving".default 50
    % maxStationaryFrames: the maximum number of consecutive frames that the centroid can be stationary before we consider it as "not detected". default: FRAMERATE (i.e. 1 second)

    if ~exist('minCentroidSpeed', 'var') || isempty(minCentroidSpeed)
        minCentroidSpeed = 100;
    end
    if ~exist('maxStationaryFrames', 'var') || isempty(maxStationaryFrames)
        maxStationaryFrames = FRAMERATE/4;
    end

    % ugly hack: there is a reflection in one corner that causes trouble. 
    % we'll exclude all frames where the centroid is at posiiton where both x and y are less than 150
    % 

    reflectionFrames = centroids(:,1) < 150 & centroids(:,2) < 150;
    centroidSpeeds(reflectionFrames(2:end)) = [];
    centroids(reflectionFrames, :) = [];
    if exist('mouseMatrix', 'var') && ~isempty(mouseMatrix)
    mouseMatrix(:,:,reflectionFrames) = [];
    end

    maxStationaryFrames = max(1, round(maxStationaryFrames));

    % identify frames where the centroid speed is less than minCentroidSpeed
    stationaryFrames = centroidSpeeds < minCentroidSpeed;
    % identify consecutive frames where the centroid is stationary
    stationaryFrameGroups = bwconncomp(stationaryFrames);
    % identify frames that are part of a stationary group that is longer than maxStationaryFrames
    framesToSetNaN = [];
    for i = 1:stationaryFrameGroups.NumObjects
        if length(stationaryFrameGroups.PixelIdxList{i}) > maxStationaryFrames
            framesToSetNaN = [framesToSetNaN; stationaryFrameGroups.PixelIdxList{i}];
        end
    end 
    % remove the identified frames from the centroidSpeeds
    cleanSpeeds = centroidSpeeds;
    cleanSpeeds(framesToSetNaN, :) = [];

    cleanCentroids = centroids;
    cleanCentroids(framesToSetNaN, :) = [];
    % remove the identified frames from the mouseMatrix
    if exist('mouseMatrix', 'var') && ~isempty(mouseMatrix)
    cleanMouseMatrix = mouseMatrix;
    cleanMouseMatrix(:,:,framesToSetNaN) = [];
    else
        cleanMouseMatrix = [];
    end


    


  