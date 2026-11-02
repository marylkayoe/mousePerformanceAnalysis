function [videoMatrix, frameRate] = readVideoIntoMatrix(filePath, varargin)
% Read an MP4 into a height x width x frames uint8 grayscale matrix.
% frameRate is the value reported by VideoReader, floored to an integer.
% Optional name-value arguments (not used by analyzeSingleOFfile):
% scaleFactor: spatial reduction factor (default 1, no resizing).
% enhanceContrast: equalize each grayscale frame (default false).

if iscell(filePath)
    filePath = filePath{1};
end

p = inputParser;
addRequired(p, 'filePath');
addParameter(p, 'scaleFactor', 1);
addParameter(p, 'enhanceContrast', false);
parse(p, filePath, varargin{:});

scaleFactor = p.Results.scaleFactor;
enhanceContrast = p.Results.enhanceContrast;

videoMatrix = [];
frameRate = [];

[~, ~, ext] = fileparts(filePath);
if ~strcmpi(ext, '.mp4')
    warning('File must be an MP4.');
    return;
end

if ~exist(filePath, 'file')
    warning('File does not exist: %s', filePath);
    return;
end

vidObj = VideoReader(filePath);
disp(['Reading file into matrix: ' char(filePath)]);
frameRate = floor(vidObj.FrameRate);
videoMatrix = zeros(vidObj.Height, vidObj.Width, vidObj.NumFrames, 'uint8');

frameIndex = 1;
while hasFrame(vidObj)
    frame = readFrame(vidObj);

    if size(frame, 3) == 3
        frame = rgb2gray(frame);
    end

    if enhanceContrast
        frame = histeq(frame);
    end

    videoMatrix(:, :, frameIndex) = frame;
    frameIndex = frameIndex + 1;
end

if scaleFactor < 1
    videoMatrix = imresize(videoMatrix, scaleFactor);
end
end
