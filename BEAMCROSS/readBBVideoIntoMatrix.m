function [videoMatrix, frameRate] = readBBVideoIntoMatrix(filePath, varargin)
% READBBVIDEOINTOMATRIX Reads a video file into a 3D matrix
% this version of the function is meant to be used with the balance beam videos,
% which are monochrome (but in RGB format). No gloves are present in the videos.
% The function reads the video file, converts it to grayscale, and stores it in a 3D matrix.
% The function also allows for downscaling the video frames by a specified scale factor.
% The function returns the video matrix and the frame rate of the video.
% INPUTS:
%   filePath: string or cell array of strings, path to the video file
%   varargin: optional parameters
%       'scaleFactor': a scalar value to scale the video by. Default is 1. scaleFactor < 1 will reduce the video size
% OUTPUTS:
%   videoMatrix: 3D matrix of the video frames (height x width x nFrames)
%   frameRate: scalar, the frame rate of the video

p = inputParser;
addRequired(p, 'filePath', @ischar);
addParameter(p, 'scaleFactor', 1, @isnumeric);
parse(p, filePath, varargin{:});

filePath = p.Results.filePath;
scaleFactor = p.Results.scaleFactor;

if iscell(filePath)
    filePath = filePath{1};
end

[~, ~, ext] = fileparts(filePath);
if ~strcmpi(ext, '.mp4') || ~exist(filePath, 'file')
    warning('Invalid file provided, aborting...');
    videoMatrix = [];
    frameRate = [];
    return;
end

disp(['Reading video file: ', filePath]);
vidObj = VideoReader(filePath);
frameRate = vidObj.FrameRate;
numFrames = vidObj.NumFrames;

vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

% Preallocate directly as grayscale
videoMatrix = zeros(vidHeight, vidWidth, numFrames, 'uint8');
% Check the first frame to determine if the video is RGB or grayscale
testFrame = readFrame(vidObj);
vidObj.CurrentTime = 0; % Reset to the beginning after reading test frame

isColor = (size(testFrame, 3) == 3);  % 3 channels => RGB color

frameIndex = 1;

% Read frames with conditional grayscale conversion
while hasFrame(vidObj)
    frame = readFrame(vidObj);
    if isColor
        videoMatrix(:,:,frameIndex) = rgb2gray(frame);
    else
        videoMatrix(:,:,frameIndex) = frame;
    end
    frameIndex = frameIndex + 1;
end

% Downscale if requested (after loading)
if scaleFactor < 1
    disp(['Downscaling video by factor ', num2str(scaleFactor)]);
    videoMatrix = imresize(videoMatrix, scaleFactor);
end
end
