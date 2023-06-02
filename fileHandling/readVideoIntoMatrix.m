function videoMatrix = readVideoIntoMatrix(filePath)
    % Create a VideoReader object
    if iscell(filePath)
    filePath = filePath{1};
end
    vidObj = VideoReader(filePath);
    
    % Preallocate a 3D matrix to hold the video frames
    vidHeight = vidObj.Height;
    vidWidth = vidObj.Width;
    numFrames = vidObj.NumFrames;  % Note: this may not work for all video formats
    %videoMatrix = zeros(vidHeight, vidWidth, numFrames);
    
    % Read each frame into the matrix
    k = 1;
    while hasFrame(vidObj)
       frame = readFrame(vidObj);
        grayscaleFrame = rgb2gray(frame);
        videoMatrix(:,:,k) = grayscaleFrame;
        k = k + 1;
    end
end
