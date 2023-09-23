function [isHandInFrame handFrameIdx handMaskMatrix] = trackHandInBB(videoMatrix, PIXELSIZE, FRAMERATE)
% trackMouseInOF.m - Track the mouse in a open field video
% videoMatrix is the video data converted into a 3D matrix
% return smoothed centroid positions with trial intervals blanked out
% instProgressionSpeeds = speed in X-direction
% blankedIdx = frame indexes when there is no mouse


disp('Segmenting hand in video...');
% Downsample the video matrix spatially
% scalingFactor = 1; % Adjust this value to get the desired downscaling; e.g., 0.5 will reduce the size to half
% [imHeight, imWidth, nFrames] = size(videoMatrix);
% if scalingFactor< 1
%     downsampledVideoMatrix = zeros(floor(imHeight * scalingFactor), floor(imWidth * scalingFactor), nFrames, 'like', videoMatrix);
% 
%     for frameIdx = 1:nFrames
%         downsampledVideoMatrix(:,:,frameIdx) = imresize(videoMatrix(:,:,frameIdx), scalingFactor);
%     end
%     videoMatrix = downsampledVideoMatrix;
% end
% [imHeight imWidth nFrames] = size(videoMatrix);

[imHeight imWidth nFrames] = size(videoMatrix);

% we don't have background image so we subtract the mean image. Not perfect but ok
meanImage = getMeanFrame(videoMatrix);
[barYcoord, barWidth] = findBarYCoordInImage(imcomplement(meanImage)); %the coordinate is from image top

% crop the video starting from 2x bar width up; everything big moving here
% will be "hand"
 croppedVideoMatrix = cropVideoAboveBar(videoMatrix, barYcoord-(barWidth*5), barWidth);
 meanImage = getMeanFrame(croppedVideoMatrix);
barArea = barWidth * imWidth;
HANDSIZETH =round(barArea/2);


sumImage = getSumFrame(croppedVideoMatrix);
sumSubtractedMatrix = subtractFrom(croppedVideoMatrix, sumImage);
meanSumSubtractedImage = getMeanFrame(sumSubtractedMatrix);
meanSubtractedMatrix = subtractFrom(croppedVideoMatrix, meanImage);
meanSubtractedMatrix = subtractFrom(croppedVideoMatrix, meanSumSubtractedImage);
meanSubtractedMatrix = imadjustn(meanSubtractedMatrix);

% preallocate for the masked video
handMaskMatrix = zeros(size(meanSubtractedMatrix));
adjustedMeanSubtractedMatrix = imadjustn(meanSubtractedMatrix, [0 0.6]);
globalThreshold = multithresh(adjustedMeanSubtractedMatrix, 4); % hand is lighter than mouse (black)
frameSize = numel(adjustedMeanSubtractedMatrix(:,:,1));
  se = strel('disk',floor(barWidth/2));
% Loop over each frame and display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = 1:nFrames
    currFrame = adjustedMeanSubtractedMatrix(:,:,frameIdx);
    segmentedFrame = imquantize(currFrame,globalThreshold);

    % hand is in the pixels classified as the higher intensity
    %handMask = (segmentedFrame==2)|(segmentedFrame==3);
    handMask = (segmentedFrame==3);

    % Fill holes in the binary image and smooth
  
    %handMask = imfill(handMask, 'holes');
    handMask = imclose(handMask, se);
    %handMask = bwmorph(handMask, 'close');

    % Find connected components in the binary image
    CC = bwconncomp(handMask);
    handMask = false(size(handMask));

    % Compute properties of connected components
    stats = regionprops(CC, 'Area');
    %in case there are more than one connected component, take the largest
    [~, idx] = max([stats.Area]);
    if isempty(idx)
        handMaskMatrix(:, :, frameIdx) = false; % Set to false if no hand identified
    else
        if stats(idx).Area < HANDSIZETH
            handMaskMatrix(:, :, frameIdx) = false; % Set to false if hand size is below threshold
        else
            handMask(CC.PixelIdxList{idx}) = true;
            handMaskMatrix(:, :, frameIdx) = handMask;
        end
    end

    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
end
fprintf('\n');
% find frames with hand in (based on movement threshold)
diffs = getLocalizedFrameDifferences (handMaskMatrix, 10, FRAMERATE);
diffs = smooth(diffs, FRAMERATE);
diffs = diffs ./ max(diffs);
blankedIdx = find(diffs < 0.15);

% blank out values when hand not detected
handMaskMatrix(:, :, blankedIdx) = 0;


handFrameSum = sum(handMaskMatrix, [1 2]); % Sum of mask matrix to get frames where hand is present
handFrameSum = squeeze(handFrameSum); % Squeeze to get a 1-D array
isHandInFrame = false(length(handFrameSum), 1);
handFrameIdx = find(handFrameSum);
isHandInFrame(handFrameIdx) = 1;

end

