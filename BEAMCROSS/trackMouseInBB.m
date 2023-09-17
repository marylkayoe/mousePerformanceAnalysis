function [centroids instProgressionSpeeds locoFrames mouseMaskMatrix] = trackMouseInBB(videoMatrix, PIXELSIZE, FRAMERATE)
% trackMouseInOF.m - Track the mouse in a open field video
% videoMatrix is the video data converted into a 3D matrix
% return smoothed centroid positions with trial intervals blanked out
% instProgressionSpeeds = speed in X-direction
LOCOTHRESHOLD = 40;
disp('Segmenting mouse in video...');
[h w nFrames] = size(videoMatrix);

% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(nFrames, 2);

% Preallocate array for storing centroid coordinates
centroids = zeros(size(videoMatrix, 3), 2);

% we don't have background image so we subtract the mean image. Not perfect but ok
meanImage = getMeanFrame(videoMatrix);
barYcoord = findBarYCoordInImage(imcomplement(meanImage)); %the coordinate is from image top
sumImage = getSumFrame(videoMatrix);
sumSubtractedMatrix = subtractFrom(videoMatrix, sumImage);
meanSumSubtractedImage = getMeanFrame(sumSubtractedMatrix);
meanSubtractedMatrix = subtractFrom(videoMatrix, meanImage);
meanSubtractedMatrix = subtractFrom(videoMatrix, meanSumSubtractedImage);
meanSubtractedMatrix = imadjustn(meanSubtractedMatrix);
%subtractedMatrix = videoMatrix-meanImage;

%barYcoord = findBarYCoordInImage(meanSumSubtractedImage);
croppedVideoMatrix = cropVideoAboveBar(meanSubtractedMatrix, barYcoord);
% preallocate for the masked video
mouseMaskMatrix = zeros(size(croppedVideoMatrix));
adjustedCroppedVideoMatrix = imadjustn(croppedVideoMatrix, [0 0.6]);
globalThreshold = multithresh(adjustedCroppedVideoMatrix, 4); % mouse body is

% Loop over each frame
%display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = 1:nFrames
    currFrame = adjustedCroppedVideoMatrix(:,:,frameIdx);
    %display current frame counter and total number of frames
    % by erasing the previous value


    % threshold image with Otsu method
    % the mouse is black and the background is white
    % finetuning could be done with more careful choides of thresholds
    
    %T = multithresh(currFrame, 3);
    segmentedFrame = imquantize(currFrame,globalThreshold);

    % Mouse is in the pixels classified as the lowest intensity
    mouseMask = (segmentedFrame==2);
 %mouseMask =(segmentedFrame == 2) | (segmentedFrame == 3);
    % Fill holes in the binary image and smooth
    mouseMask = imfill(mouseMask, 'holes');
    mouseMask = bwmorph(mouseMask, 'close');
frameSize = numel(currFrame);
    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);
mouseMask = false(size(mouseMask));
    % Compute properties of connected components
    stats = regionprops(CC, 'Centroid', 'Area');
    %in case there are more than one connected component, take the largest
    [~, idx] = max([stats.Area]);
    if isempty(idx)
        warning('No object found in frame ');
        centroids(frameIdx,:) = nan;
    else
        if stats(idx).Area < frameSize*0.1
            %warning('The largest object is smaller than the threshold (10% of framesize)');
            centroids(frameIdx,:) = nan;
        else

            centroids(frameIdx,:) = stats(idx).Centroid;
            mouseMask(CC.PixelIdxList{idx}) = true;
            mouseMaskMatrix(:, :, frameIdx) = mouseMask;
        end

        % Create a binary image containing only the selected connected component
    end 

    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
end
fprintf('\n');
% find frames with mouse in (based on movement threshold)
diffs = getLocalizedFrameDifferences (mouseMaskMatrix, 10, FRAMERATE);
diffs = smooth(diffs, FRAMERATE);
diffs = diffs ./ max(diffs);
blankedIdx = find(diffs < 0.2);

% mouse position defined by the segment centroids
centroids = centroids / PIXELSIZE;
centroidsSMOOTH = smoothdata(centroids, 'movmean', floor(FRAMERATE/20));
centroidsGF = gapFillTrajectory(centroidsSMOOTH);

% we only measure speed along the bar (horizontally)
instProgressionSpeeds = getMouseSpeedFromTraj(centroidsGF(:, 1), FRAMERATE, FRAMERATE);

% blank out values when mouse not detected
mouseMaskMatrix(:, :, blankedIdx) = 0;
centroidsSMOOTH(blankedIdx, :) = nan;
instProgressionSpeeds( blankedIdx) = nan;

% frames where mouse is (maybe) going forward
locoFrames = instProgressionSpeeds > LOCOTHRESHOLD;
end

