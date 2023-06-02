function [centroids mouseMaskMatrix] = trackMouseInOF(videoMatrix)
nFrames = length(videoMatrix);
% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(nFrames, 2);
meanImage = mean(videoMatrix, 3);
mouseMaskMatrix = zeros(size(videoMatrix));
subtractedMatrix = videoMatrix-meanImage;

% Preallocate array for storing centroid coordinates
centroids = zeros(size(videoMatrix, 3), 2);

% Loop over each frame
for frameIdx = 1:size(videoMatrix, 3)
    % Get current frame
    frame = videoMatrix(:,:,frameIdx);

    % Determine an optimal threshold using Otsu's method
    T = multithresh(frame, 10);
    seg_I = imquantize(frame,T);

    % Segment mouse from background by thresholding
    mouseMask = (seg_I==1);
    % Fill holes in the binary image
    mouseMask = imfill(mouseMask, 'holes');

    % Perform morphological closing to smooth the image
    mouseMask = bwmorph(mouseMask, 'close');


    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);
    % Compute properties of connected components
    stats = regionprops(CC, 'Centroid', 'Area');
    [~, idx] = max([stats.Area]);  % find the largest connected component
    centroids(frameIdx,:) = stats(idx).Centroid;

    % Create a binary image containing only the selected connected component
    mouseMask = false(size(mouseMask));
    mouseMask(CC.PixelIdxList{idx}) = true;
    mouseMaskMatrix(:, :, frameIdx) = mouseMask;


end
