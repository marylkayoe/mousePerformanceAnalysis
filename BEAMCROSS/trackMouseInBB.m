function [mouseCentroids instProgressionSpeeds locoFrames mouseMaskMatrix blankedIdx] = trackMouseInBB(videoMatrix, PIXELSIZE, FRAMERATE)
% trackMouseInOF.m - Track the mouse BB video
% videoMatrix is the video data converted into a 3D matrix
% return smoothed centroid positions with trial intervals blanked out
% instProgressionSpeeds = speed in X-direction
% blankedIdx = frame indexes when there is no mouse
LOCOTHRESHOLD = 40;

disp('Segmenting mouse in video...');
[imHeight imWidth nFrames] = size(videoMatrix);
meanImage = getMeanFrame(videoMatrix);
[barYcoord barWidth] = findBarYCoordInImage(imcomplement(meanImage)); %the coordinate is from image top
barArea = barWidth * imWidth;
MOUSESIZETH = round(barArea /4); %min size

%% start by finding frames where there is a hand in the frame

[isHandInFrame handFrameIdx handMaskMatrix] = trackHandInBB(videoMatrix,PIXELSIZE, FRAMERATE);
% remove frames we look at if hand was in the frame

frameList = 1:nFrames;
[hf, idx] = intersect(frameList, handFrameIdx);
frameList(idx) = [];




% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = nan(nFrames, 2);


% we don't have background image so we subtract the mean image. Not perfect but ok
sumImage = getSumFrame(videoMatrix);
sumSubtractedMatrix = subtractFrom(videoMatrix, sumImage);
meanSumSubtractedImage = getMeanFrame(sumSubtractedMatrix);
meanSubtractedMatrix = subtractFrom(videoMatrix, meanImage);
meanSubtractedMatrix = subtractFrom(videoMatrix, meanSumSubtractedImage);
meanSubtractedMatrix = imadjustn(meanSubtractedMatrix);
%subtractedMatrix = videoMatrix-meanImage;

%barYcoord = findBarYCoordInImage(meanSumSubtractedImage);
croppedVideoMatrix = cropVideoAboveBar(meanSubtractedMatrix, barYcoord, barWidth);
% preallocate for the masked video
mouseMaskMatrix = zeros(size(croppedVideoMatrix));
adjustedCroppedVideoMatrix = imadjustn(croppedVideoMatrix, [0 0.6]);
globalThreshold = multithresh(adjustedCroppedVideoMatrix, 4); % mouse body is

frameSize = numel(adjustedCroppedVideoMatrix(:,:,1));
% Loop over each frame
%display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = frameList % going through the frames without hand
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

    % Fill holes in the binary image and smooth
    mouseMask = imfill(mouseMask, 'holes');
    mouseMask = bwmorph(mouseMask, 'close');
    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);
mouseMask = false(size(mouseMask));
    % Compute properties of connected components
    stats = regionprops(CC, 'Centroid', 'Area');
    %in case there are more than one connected component, take the largest
    [~, idx] = max([stats.Area]);
    if isempty(idx)
        warning('No object found in frame ');
        mouseCentroids(frameIdx,:) = nan;
    else
        if (stats(idx).Area < MOUSESIZETH)
            %warning('The largest object is smaller than the threshold (relative to bar size)');
            mouseCentroids(frameIdx,:) = nan;
        else
            if (stats(idx).Area > MOUSESIZETH*3)
                %warning('The largest object is smaller than the threshold (relative to bar size)');
                mouseCentroids(frameIdx,:) = nan;
            else
                mouseCentroids(frameIdx,:) = stats(idx).Centroid;
                mouseMask(CC.PixelIdxList{idx}) = true;
                mouseMaskMatrix(:, :, frameIdx) = mouseMask;
            end
        end

    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
    end
end
fprintf('\n');
% find frames with mouse in (based on movement threshold)
diffs = getLocalizedFrameDifferences (mouseMaskMatrix, 10, FRAMERATE);
diffs = smooth(diffs, FRAMERATE);
diffs = diffs ./ max(diffs);
blankedIdx = find(diffs < 0.05);
disp('Calculating centroid position and forward speed...');
% mouse position defined by the segment centroids
mouseCentroids = mouseCentroids / PIXELSIZE;
centroidsSMOOTH = smoothdata(mouseCentroids, 'movmean', floor(FRAMERATE/20));
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

