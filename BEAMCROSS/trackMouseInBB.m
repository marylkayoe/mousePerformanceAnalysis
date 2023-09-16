function [centroids mouseMaskMatrix] = trackMouseInBB(videoMatrix)
% trackMouseInOF.m - Track the mouse in a open field video
% videoMatrix is the video data converted into a 3D matrix
[h w nFrames] = size(videoMatrix);

% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(nFrames, 2);

% Preallocate array for storing centroid coordinates
centroids = zeros(size(videoMatrix, 3), 2);

% we don't have background image so we subtract the mean image. Not perfect but ok
meanImage = getMeanFrame(videoMatrix);
medianImage = getMedianFrame(videoMatrix);
sumImage = getSumFrame(videoMatrix);
sumSubtractedMatrix = subtractFrom(videoMatrix, sumImage);
meanSumSubtractedImage = getMeanFrame(sumSubtractedMatrix);
meanSubtractedMatrix = subtractFrom(videoMatrix, meanImage);
%subtractedMatrix = videoMatrix-meanImage;

barYcoord = findBarYCoordInImage(meanSumSubtractedImage);
croppedVideoMatrix = cropVideoAboveBar(meanSubtractedMatrix, barYcoord);
% preallocate for the masked video
mouseMaskMatrix = zeros(size(croppedVideoMatrix));
adjustedCroppedVideoMatrix = imadjustn(croppedVideoMatrix, [0 0.6]);
globalThreshold = multithresh(adjustedCroppedVideoMatrix, 2);

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
    mouseMask = (segmentedFrame==1);

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
        centroids(frameIdx,:) = nan;
    else
    centroids(frameIdx,:) = stats(idx).Centroid;
        mouseMask(CC.PixelIdxList{idx}) = true;
    mouseMaskMatrix(:, :, frameIdx) = mouseMask;
    end

    % Create a binary image containing only the selected connected component
    

    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
end
fprintf('\n');
mouseMaskMatrix(:, :, diffs<0.01) = 0;
end

