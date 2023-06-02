function showKeyFrames(videoMatrix, frameRange)
    % createMontage - create a montage of specified frames from a video
    % 
    % frameRange: range of frame numbers to include in the montage

    % Preallocate a 4D array to store the frames
    % firstFrame = read(vidObj, 1);
    % [height, width, numFrames] = size(videoMatrix);
    % numKeyFrames = length(frameRange);
    % keyframes = zeros(height, width, numChannels, numFrames, 'like', firstFrame);
    % 
    % % Read in the specified frames
    % for i = 1:numKeyFrames
    %     keyframes(:,:,i) = read(vidObj, frameRange(i));
    % end
    % 
    % % Create a montage of the frames
    montage(videoMatrix(:, :, frameRange));
    
    % Calculate number of images per row in the montage
    % imagesPerRow = ceil(sqrt(numFrames));
    % 
    % % Add frame numbers above each frame in the montage
    % for i = 1:numFrames
    %     row = floor((i-1) / imagesPerRow);
    %     col = mod(i-1, imagesPerRow);
    %     text(10+col*width, 10+row*height, num2str(frameRange(i)), 'Color', 'r', 'FontSize', 12);
    % end
end
