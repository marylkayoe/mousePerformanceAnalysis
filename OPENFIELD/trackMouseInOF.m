function [centroids mouseMaskMatrix] = trackMouseInOF(videoMatrix)
% trackMouseInOF.m - Track the mouse in a open field video
% videoMatrix is the video data converted into a 3D matrix
minNmouseArea = 5000; % minimum area of the mouse in pixels, to filter out noise
SKIPMISSIGFRAMES = true; % whether to skip frames where the mouse is not detected from the mouseMaskMatrix, if true the result will only contain frames where centroid is not NAN

USEGLOBALTHRESH = false; % whether to use global thresholding or local thresholding for each frame, global thresholding is faster but less accurate, local thresholding is slower but more accurate

nFrames = length(videoMatrix);

% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(nFrames, 2);
% preallocate for the masked video
mouseMaskMatrix = zeros(size(videoMatrix));
% Preallocate array for storing centroid coordinates
centroids = nan(size(videoMatrix, 3), 2);

% we don't have background image so we subtract the mean image. Not perfect but ok
meanImage = getMeanFrame(videoMatrix);
subtractedMatrix = subtractFrom(videoMatrix, meanImage);

% calculate thresholds based on global histogram
Tglobal = multithresh(subtractedMatrix(:), 5);
Tglobal = unique(Tglobal, 'stable');

% Loop over each frame
%display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = 1:nFrames
    currFrame = videoMatrix(:,:,frameIdx);
    %display current frame counter and total number of frames
    % by erasing the previous value
    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end

    % threshold image with Otsu method
    % the mouse is black and the background is white
    % finetuning could be done with more careful choides of thresholds
    
    if USEGLOBALTHRESH
        segmentedFrame = imquantize(currFrame,Tglobal);
    else
    T = multithresh(currFrame, 10);
        T = unique(T, 'stable');

    segmentedFrame = imquantize(currFrame,T);
    end
    %occasionally there might be too little difference between two
    %thresholds so they end up being the same... so we will just remove the
    %duplicate

    se = strel('disk', 10);

    % Mouse is in the pixels classified as the lowest intensity
    mouseMask = (segmentedFrame==1);

    % Fill holes in the binary image and smooth
    mouseMask = imfill(mouseMask, 'holes');
    mouseMask = bwmorph(mouseMask, 'close');
   % morphologiical clean of the mask to make the outline smooth, using a disk
    mouseMask = imopen(mouseMask, se);

    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);

    % check if there are any elements in CC, if not continue to the next frame
    if CC.NumObjects == 0
        continue;
    end
    
    % Compute properties of connected components
    stats = regionprops(CC, 'Centroid', 'Area');
    %in case there are more than one connected component, take the largest
    [~, idx] = max([stats.Area]); 
    % the area should be larger than minNmouseArea, otherwise we will consider it as noise and ignore it
    if stats(idx).Area < minNmouseArea
        continue;
    end


    centroids(frameIdx,:) = stats(idx).Centroid;

    % Create a binary image containing only the selected connected component
    mouseMask = false(size(mouseMask));
    mouseMask(CC.PixelIdxList{idx}) = true;
    mouseMaskMatrix(:, :, frameIdx) = mouseMask;

end
fprintf('\n');
if SKIPMISSIGFRAMES
    % remove frames where the mouse is not detected (centroid is NAN)
    validFrames = ~isnan(centroids(:,1));
    centroids = centroids(validFrames, :);
    mouseMaskMatrix = mouseMaskMatrix(:,:,validFrames);
end

end
