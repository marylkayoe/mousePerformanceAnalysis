function videoMatrix = readBBaviVideoIntoMatrix(filename, dataPath, varargin)
% readBBaviVideoIntoMatrix - Reads a .avi video file into a 3D matrix.
% 
% Syntax:
%   videoMatrix = readBBaviVideoIntoMatrix(filename, dataPath, 'scaleFactor', 0.5);
% INPUTS:
%   filename: String, name of the .avi video file.
%   dataPath: String, path to the directory containing the video file.
%   'scaleFactor' (optional): Scalar to spatially downscale the video (default: 1).
% OUTPUTS:
%   videoMatrix: 3D  matrix (height x width x nFrames).
%   frameRate: Scalar, frame rate of the video.
%
