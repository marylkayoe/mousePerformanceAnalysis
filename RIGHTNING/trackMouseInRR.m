function [centroids mouseMaskMatrix] = trackMouseInRR(videoMatrix)
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
meanImage = mean(videoMatrix, 3);
meanImage = uint8(imadjust(meanImage, [0.1 0.8]));
%subtractedMatrix = subtractFrom(videoMatrix, meanImage);
videoMatrix = imadjustn(videoMatrix, [0.1 0.8]);
subtractedMatrix = videoMatrix-meanImage;

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

    T = multithresh(currFrame, 4);
    %T = graythresh(currFrame);
    %occasionally there might be too little difference between two
    %thresholds so they end up being the same... so we will just remove the
    %duplicate
    %T = unique(T, 'stable');
    segmentedFrame = imquantize(currFrame,T);

    % Mouse is in the pixels classified as the lowest intensity
    mouseMask = (segmentedFrame==1);

    % Fill holes in the binary image and smooth
    mouseMask = imfill(mouseMask, 'holes');
    mouseMask = bwmorph(mouseMask, 'close');
    mouseMask = bwmorph(mouseMask, 'clean');
    mouseMask = bwmorph(mouseMask, 'thicken');

    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);
    mouseMask = false(size(mouseMask));

    if CC.NumObjects % if there are any objects
  
        stats = regionprops(CC,'Area');
        [~, idx] = max([stats.Area]);
        mouseMask(CC.PixelIdxList{idx}) = true;
        
       % centroids(frameIdx,:) = stats(idx).Centroid;
        mouseMask(CC.PixelIdxList{idx}) = true;
    else
        centroids(frameIdx,:) = nan;
    end

 
    % Create a binary image containing only the selected connected component
   
    
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
