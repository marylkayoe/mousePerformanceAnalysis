function [videoMatrix frameRate] = readVideoIntoMatrix(filePath, varargin)
    % reads a .mp4 file in and returns it as an uint matrix (grayscale)
    % filePath: path to the video file

    % Optional input arguments:
    %  'scaleFactor': a scalar value to scale the video by. Default is 1. scaleFactor < 1 will reduce the video size
    %  'enhanceContrast': a boolean value to enhance the contrast of the video. Default is false
    % 'removeGlove': a boolean value to remove the blue color channel from the video. Default is false

    % parse the input arguments
    p = inputParser;
    addRequired(p, 'filePath', @ischar);
    addParameter(p, 'scaleFactor', 1, @isnumeric);
    addParameter(p, 'enhanceContrast', false, @islogical);
    addParameter(p, 'removeGlove', false, @islogical);
    parse(p, filePath, varargin{:});

    filePath = p.Results.filePath;
    scaleFactor = p.Results.scaleFactor;
    enhanceContrast = p.Results.enhanceContrast;
    removeGlove = p.Results.removeGlove;

    % Create a VideoReader object
    if iscell(filePath)
        filePath = filePath{1};
    end

    videoMatrix = [];
    frameRate = [];

    % check that the file is .mp4
    [~, ~, ext] = fileparts(filePath);

    % check if the file ending is mp4 (case-insensitive)
    if ~strcmpi(ext, '.mp4')
        warning('File must be a .mp4 file, aborting...');
        return;
    end

    % Check if the file exists
    if ~exist(filePath, 'file')
        warningMessage = sprintf('File does not exist:\n%s', filePath);
        warning(warningMessage);
        return;
    end

    % vidObj is a VideoReader object that handles the reading of the video file
    vidObj = VideoReader(filePath);
    disp(['reading file into matrix... ' filePath]);

    % Preallocate a 3D matrix to hold the video frames
    vidHeight = vidObj.Height;
    vidWidth = vidObj.Width;
    numFrames = vidObj.NumFrames;
    frameRate = vidObj.FrameRate;
    videoMatrix = zeros(vidHeight, vidWidth, numFrames, 'uint8');

    % Check if the video is monochrome or colored
    isMonochrome = false;
    if hasFrame(vidObj)
        testFrame = readFrame(vidObj);

        if size(testFrame, 3) == 1
            isMonochrome = true;
        end

        vidObj.CurrentTime = 0; % Reset the video reader to the beginning
    end

    % Read each frame into the matrix
    frameIndex = 1;

    while hasFrame(vidObj)
        frame = readFrame(vidObj);

        if ~isMonochrome
            if removeGlove
                % Remove the blue channel from the frame
                frame = removeBlueGloveFromFrame(frame, 'replaceWith', 'white');
            end

            frame = rgb2gray(frame);
        end

        % Apply histogram equalization to increase contrast if requested
        if enhanceContrast
            frame = histeq(frame);
        end

        % place the frame in the video matrix
        videoMatrix(:, :, frameIndex) = frame;
        frameIndex = frameIndex + 1;
    end

    % downscale the video in xy dimension if needed (no changes in the frame rate)
    if scaleFactor < 1
        disp(['downscaling video by factor ' num2str(scaleFactor)]);
        videoMatrix = imresize(videoMatrix, scaleFactor);
    end

end
