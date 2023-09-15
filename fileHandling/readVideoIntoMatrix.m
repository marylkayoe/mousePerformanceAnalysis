function [videoMatrix frameRate] = readVideoIntoMatrix(filePath)
% reads a .mp4 file in and returns it as an uint matrix (grayscale)
% Create a VideoReader object
if iscell(filePath)
    filePath = filePath{1};
end
vidObj = VideoReader(filePath);
disp(['reading file into matrix... ' filePath]);

% Preallocate a 3D matrix to hold the video frames
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
numFrames = vidObj.NumFrames;
frameRate = vidObj.FrameRate;

videoMatrix = uint8(nan(vidHeight, vidWidth, numFrames));

% Check if the video is monochrome or colored
isMonochrome = false;
if hasFrame(vidObj)
    testFrame = readFrame(vidObj);
    if size(testFrame,3) == 1
        isMonochrome = true;
    end
    vidObj.CurrentTime = 0; % Reset the video reader to the beginning
end

% Read each frame into the matrix
k = 1;
while hasFrame(vidObj)
    frame = readFrame(vidObj);
    if ~isMonochrome
        frame = rgb2gray(frame);
    end
    % Apply histogram equalization to increase contrast
    enhancedFrame = histeq(frame);
    videoMatrix(:,:,k) = frame;
    k = k + 1;
end
end



