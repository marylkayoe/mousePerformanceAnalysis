function [videoMatrix, frameRate] = readBBVideoIntoMatrix(filePath, varargin)
    % READBBVIDEOINTOMATRIX Reads a grayscale video file into a 3D matrix.
    %
    % This function reads monochrome balance beam videos (possibly stored as RGB) into
    % grayscale frames. It allows optional spatial downscaling.
    %
    % INPUTS:
    %   filePath: String (or cell array), path to the .mp4 video file.
    %   'scaleFactor' (optional): Scalar to spatially downscale the video (default: 1).
    %
    % OUTPUTS:
    %   videoMatrix: 3D uint8 matrix (height x width x nFrames).
    %   frameRate: Scalar, frame rate of the video.
    
    % Input parsing
    p = inputParser;
    addRequired(p, 'filePath', @ischar);
    addParameter(p, 'scaleFactor', 1, @(x)isnumeric(x) && x>0 && x<=1);
    parse(p, filePath, varargin{:});
    
    filePath = p.Results.filePath;
    scaleFactor = p.Results.scaleFactor;
    
    if iscell(filePath)
        filePath = filePath{1};
    end
    
    % Validate file
    [~, ~, ext] = fileparts(filePath);
    if ~strcmpi(ext, '.mp4') || ~exist(filePath, 'file')
        warning('Invalid or non-existent file provided, aborting...');
        videoMatrix = [];
        frameRate = [];
        return;
    end
    
    % Load video metadata
    vidObj = VideoReader(filePath);
    frameRate = vidObj.FrameRate;
    numFrames = vidObj.NumFrames;
    [vidHeight, vidWidth] = deal(vidObj.Height, vidObj.Width);
    
    % Preallocate matrix directly as grayscale
    videoMatrix = zeros(vidHeight, vidWidth, numFrames, 'uint8');
    
    % Check color format from the first frame
    firstFrame = readFrame(vidObj);
    vidObj.CurrentTime = 0; % Reset reader to start
    isColor = (size(firstFrame, 3) == 3);
    
    % Read video frames
    disp(['Reading video file: ', filePath]);
    frameIndex = 1;
    while hasFrame(vidObj)
        frame = readFrame(vidObj);
        if isColor
            videoMatrix(:,:,frameIndex) = rgb2gray(frame);
        else
            videoMatrix(:,:,frameIndex) = frame;
        end
        frameIndex = frameIndex + 1;
    end
    
    % Optional downscaling
    if scaleFactor < 1
        disp(['Downscaling video by factor ', num2str(scaleFactor)]);
        videoMatrix = imresize(videoMatrix, scaleFactor);
    end
    end
    