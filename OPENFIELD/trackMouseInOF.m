function mouseCentroids = trackMouseInOF(videoMatrix)

% Preallocate arrays for the mouse centroid coordinates
mouseCentroids = zeros(videoMatrix.NumberOfFrames, 2);

% Read in the first frame (assume it's the background)
background = double(readFrame(videoMatrix));
frame = 1;
nFrames = length(videoMatrix);
% Loop through the remaining frames
for frame = 1:nFrames  
    currentFrame = videoMatrix(:, :, frame);    
    % Calculate the absolute difference between the current frame and the background
    diffFrame = abs(currentFrame - background);
    
    % Threshold the difference image (you may need to adjust this value)
    binaryImage = diffFrame > 50;
    
    % Get the properties of the connected components in the image
    properties = regionprops(binaryImage, 'Centroid', 'Area');
    
    % Store the centroid of the largest component (assume it's the mouse)
    if ~isempty(properties)
        % If there are multiple components, assume the one with the maximum area is the mouse
        [~, idx] = max([properties.Area]);
        mouseCentroids(frame, :) = properties(idx).Centroid;
    end
    frame = frame+1;
end

% Now mouseCentroids contains the (x, y) coordinates of the mouse centroid for each frame
