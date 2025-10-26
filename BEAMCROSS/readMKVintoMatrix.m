function videoMatrix = readMKVintoMatrix(fileName, dataPath, varargin)
% reads a grayscale mkv video into a 3D matrix (height x width x nFrames)
% the mkv file is assumed to be in grayscale format
%  NOTE: VideoReader can not read mkv, so we use Computer Vision Toolbox
% INPUTS:
%   fileName: String, name of the .mkv video file.
%   dataPath: String, path to the directory containing the video file.
%   'scaleFactor' (optional): Scalar to spatially downscale the video (default: 1).
% OUTPUTS:
%   videoMatrix: 3D uint8 matrix (height x width x nFrames).

% Input parsing
p = inputParser;
addRequired(p, 'fileName', @ischar);
addRequired(p, 'dataPath', @ischar);
addParameter(p, 'scaleFactor', 1, @(x)isnumeric(x) && x>0 && x<=1);
parse(p, fileName, dataPath, varargin{:});
fileName = p.Results.fileName;
dataPath = p.Results.dataPath;
scaleFactor = p.Results.scaleFactor;
% check the folder and file exist
fullFilePath = fullfile(dataPath, fileName);
if ~exist(fullFilePath, 'file')
    warning('The specified MKV file does not exist: %s', fullFilePath);
    videoMatrix = [];
    return;
end


vidReader = VideoFReader(fullFilePath);

% check metadata from the video

videoFrame = readFrame(vidReader);



vidObj = VideoReader(fullFilePath);
numFrames = vidObj.NumFrames;
nEst = max(1, floor(v.FrameRate * v.Duration + 0.5));
disp(['Number of frames in video: ', num2str(numFrames), ', Estimated frames: ', num2str(nEst)]);
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
% Preallocate matrix
videoMatrix = zeros(vidHeight, vidWidth, numFrames, 'uint8');





