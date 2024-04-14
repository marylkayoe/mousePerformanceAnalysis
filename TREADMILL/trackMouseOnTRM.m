function [centroids mouseMaskMatrix] = trackMouseOnTRM(videoMatrix, varargin)
% trackMouseonTRM.m - Track the mouse in a open field video
% videoMatrix is the video data converted into a 3D matrix
% the function is based on trackMouseInOF
% inputs:
% videoMatrix - 3D matrix containing the video data
% minArea - minimum area of the mouse in the video relative to the image size, default 0.1 (10%)
% nLevels - number of levels for the Otsu method, default 10
% removeGlove - boolean to remove the glove from the video, default false
% minDurationMouse - tracks shorter than this duration will be removed, default 60 frames
% smoothWindow - window size for smoothing the centroid coordinates, default 0 (no smoothing)

% Parse input arguments
p = inputParser;
addRequired(p, 'videoMatrix', @isnumeric);
addParameter(p, 'minArea', 0.1, @isnumeric); % Minimum area of the mouse in the video relative to the image size
addParameter(p, 'nLevels', 10, @isnumeric); % Number of levels for the Otsu method
addParameter(p, 'removeGlove', false, @islogical); % Remove the glove from the video
addParameter(p, 'minDurationMouse', 60, @isnumeric); % Minimum duration of the mouse track
addParameter(p, 'smoothWindow', 0, @isnumeric); % Window size for smoothing the centroid coordinates


parse(p, videoMatrix, varargin{:});

minArea = p.Results.minArea;
nLevels = p.Results.nLevels;
removeGlove = p.Results.removeGlove;
minDurationMouse = p.Results.minDurationMouse;

nFrames = length(videoMatrix);

% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(nFrames, 2);
% preallocate for the masked video
mouseMaskMatrix = zeros(size(videoMatrix));
% Preallocate array for storing centroid coordinates
centroids = nan(size(videoMatrix, 3), 2);
maxAreas = nan(length(videoMatrix));

% we don't have background image so we subtract the mean image. Not perfect but ok
meanImage = getMeanFrame(videoMatrix);
imageArea = size(videoMatrix, 1) * size(videoMatrix, 2);
%subtractedMatrix = subtractFrom(videoMatrix, meanImage);
%subtractedMatrix = videoMatrix-meanImage;

% threshold image with Otsu method
% the mouse is black and the background is dark
% the mouse is mostly not in the frame so need to get the threshold based on full stack, not individual frames

% reshape the matrix to 2D to get the threshold
wholevideo = reshape(videoMatrix, size(videoMatrix, 1)*size(videoMatrix, 2), size(videoMatrix, 3));
T = multithresh(wholevideo, nLevels);


% Loop over each frame
%display current frame counter
fprintf('Processing frames (out of %d): ', nFrames);
for frameIdx = 1:nFrames
    currFrame = videoMatrix(:,:,frameIdx);
    
    
    
    
    
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
    mouseMask = bwmorph(mouseMask, 'open');

    se = strel('disk', 10); % Create a disk-shaped structuring element with a radius of 5
    mouseMask = imopen(mouseMask, se);
    mouseMask = imclose(mouseMask, se);
    mouseMask = imclearborder(mouseMask);
    
    % Find connected components in the binary image
    CC = bwconncomp(mouseMask);
    if (CC.NumObjects)
        
        % Compute properties of connected components
        stats = regionprops(CC, 'Centroid', 'Area');
        
        %in case there are more than one connected component, take the largest
        [maxArea, idx] = max([stats.Area]);
        
        
        % exclude areas that are smaller than 15% of the image area
        if maxArea < minArea*imageArea
            continue;
        end
        centroids(frameIdx,:) = stats(idx).Centroid;
        maxAreas(frameIdx) = maxArea;
        % Create a binary image containing only the selected connected component
        mouseMask = false(size(mouseMask));
        mouseMask(CC.PixelIdxList{idx}) = true;
        mouseMaskMatrix(:, :, frameIdx) = mouseMask;
    end
    
    
    if mod(frameIdx, 10) == 0
        fprintf('.');
    end
    if mod(frameIdx, 500) == 0
        fprintf('\n');
    end
end
fprintf('\n');

% find frames where mask is not empty
notEmpty = ~isnan(centroids(:,1));
% Find indices where 'notEmpty' changes (i.e., starts or ends of consecutive frames)
consecutive = find(diff([0; notEmpty; 0]));

% Compute lengths of consecutive frame segments
segmentLengths = diff(consecutive);

% Find segments shorter than 50 frames
shortSegments = find(segmentLengths < minDurationMouse);

% Find the start and end of the short consecutive frames
start = consecutive(shortSegments);
stop = consecutive(shortSegments + 1) - 1;

% make the mask empty for the short consecutive frames
for i = 1:length(start)
    centroids(start(i):stop(i),:) = nan;
    mouseMaskMatrix(:,:,start(i):stop(i)) = 0;
end

if smoothWindow > 0
    % Smooth the centroid coordinates
    centroids = smoothdata(centroids, 'movmean', smoothWindow);
end

end
