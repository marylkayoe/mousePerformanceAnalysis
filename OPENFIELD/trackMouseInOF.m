function [centroids mouseMaskMatrix] = trackMouseInOF(videoMatrix)
% trackMouseInOF.m - Track the mouse in a open field video
% videoMatrix is the video data converted into a 3D matrix

nFrames = length(videoMatrix);

% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(nFrames, 2);
% preallocate for the masked video
mouseMaskMatrix = zeros(size(videoMatrix));
% Preallocate array for storing centroid coordinates
centroids = zeros(size(videoMatrix, 3), 2);

% we don't have background image so we subtract the mean image. Not perfect but ok
meanImage = getMeanFrame(videoMatrix);
subtractedMatrix = subtractFrom(videoMatrix, meanImage);
%subtractedMatrix = videoMatrix-meanImage;

% Loop over each frame
%display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = 1:nFrames
    currFrame = videoMatrix(:,:,frameIdx);
    %display current frame counter and total number of frames
    % by erasing the previous value


    % threshold image with Otsu method
    % the mouse is black and the background is white
    % finetuning could be done with more careful choides of thresholds
    
    T = multithresh(currFrame, 10);
    %occasionally there might be too little difference between two
    %thresholds so they end up being the same... so we will just remove the
    %duplicate
    T = unique(T, 'stable');
    segmentedFrame = imquantize(currFrame,T);

    % Mouse is in the pixels classified as the lowest intensity
    mouseMask = (segmentedFrame==1);

    % Fill holes in the binary image and smooth
    mouseMask = imfill(mouseMask, 'holes');
    mouseMask = bwmorph(mouseMask, 'close');

    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);

    % Compute properties of connected components
    stats = regionprops(CC, 'Centroid', 'Area');
    %in case there are more than one connected component, take the largest
    [~, idx] = max([stats.Area]); 
    centroids(frameIdx,:) = stats(idx).Centroid;

    % Create a binary image containing only the selected connected component
    mouseMask = false(size(mouseMask));
    mouseMask(CC.PixelIdxList{idx}) = true;
    mouseMaskMatrix(:, :, frameIdx) = mouseMask;
    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
end
fprintf('\n');
end
