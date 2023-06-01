function showKeyFrames(vidObj, frameRange)
    % createMontage - create a montage of specified frames from a video
    % 
    % vidObj: VideoReader object
    % frameRange: range of frame numbers to include in the montage

    % Preallocate a 4D array to store the frames
    firstFrame = read(vidObj, 1);
    [height, width, numChannels] = size(firstFrame);
    numFrames = length(frameRange);
    frames = zeros(height, width, numChannels, numFrames, 'like', firstFrame);

    % Read in the specified frames
    for i = 1:numFrames
        frames(:,:,:,i) = read(vidObj, frameRange(i));
    end

    % Create a montage of the frames
    montage(frames);
end
