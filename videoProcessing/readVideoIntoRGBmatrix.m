function RGBmatrix = readVideoIntoRGBmatrix(filePath, varargin)
    % readVideoIntoRGBmatrix - read video file into RGB matrix
    % input: filePath - the path to the video file
    %        varargin - optional input arguments
    %         'scaleFactor': a scalar value to scale the video by. Default is 1. scaleFactor < 1 will reduce the video size
    % output: RGBmatrix - a 4D matrix representing the video in RGB format

    % parse the input arguments
    p = inputParser;
    addRequired(p, 'filePath', @ischar);
    addParameter(p, 'scaleFactor', 1, @isnumeric);
    parse(p, filePath, varargin{:});

    filePath = p.Results.filePath;
    scaleFactor = p.Results.scaleFactor;

    RGBmatrix = [];

    % Find the file
    if iscell(filePath)
        filePath = filePath{1};
    end


    % check if the file ending is mp4 (case-insensitive)
    [~, ~, ext] = fileparts(filePath);
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

    % Preallocate a 4D matrix to hold the video frames
    vidHeight = vidObj.Height;
    vidWidth = vidObj.Width;
    numFrames = vidObj.NumFrames;
    frameRate = vidObj.FrameRate;
    RGBmatrix = zeros(vidHeight, vidWidth, 3, numFrames, 'uint8');

    % Read each frame and store it in the matrix
    for k = 1:numFrames
        frame = readFrame(vidObj);
        RGBmatrix(:, :, :, k) = frame;
    end

end
