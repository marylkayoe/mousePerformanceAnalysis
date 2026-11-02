function [centroids, mouseMaskMatrix] = trackMouseInOF(videoMatrix, PIXELSIZE, nLevels)
% Track a dark mouse against a light open-field background.
% videoMatrix: height x width x frames grayscale video.
% PIXELSIZE: mm per pixel in this video (default 2 for our 2x-downsampled recordings).
% nLevels: number of Otsu thresholds (default 10, giving 11 intensity classes).
% centroids: one [x y] position per frame, in mm relative to the image origin.
% mouseMaskMatrix: selected mouse masks at the original video pixel dimensions.
% Each raw frame is quantized using nLevels Otsu thresholds. The darkest class is
% hole-filled and closed, then the largest connected component is selected.
% No minimum-area cutoff or disk opening is applied. Mouse must be
% present in every frame.

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 2;
end

if ~exist('nLevels', 'var')
    nLevels = 10;
end


% Preallocate arrays for the mouse centroid coordinates
nFrames = length(videoMatrix);

if nargout > 1
    mouseMaskMatrix = zeros(size(videoMatrix));
end

% Preallocate array for storing centroid coordinates
centroids = zeros(size(videoMatrix, 3), 2);

% Loop over each frame and display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = 1:nFrames
    currFrame = videoMatrix(:,:,frameIdx);

    % threshold image with Otsu method the mouse is black and the background is white
    % finetuning could be done with more careful choides of thresholds

    T = multithresh(currFrame, nLevels);
    %occasionally there might be too little difference between two
    %thresholds so they end up being the same... so we will just remove the
    %duplicate
    T = unique(T, 'stable');

    % segment the frame into intensity classes based on the thresholds
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
    % only if a mask was requested as an output
if nargout > 1
    % Store the mask of the selected component.
    mouseMask = false(size(mouseMask));
    mouseMask(CC.PixelIdxList{idx}) = true;
    mouseMaskMatrix(:, :, frameIdx) = mouseMask;
end

    % display progress for every 10 frames and new line for every 500 frames
    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
end
fprintf('\n');

% Scale the centroids by the pixel size (convert from pixels to physical units)
centroids = centroids * PIXELSIZE;

end
