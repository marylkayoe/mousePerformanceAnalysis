function [nSLIPS, slipIndex, slipLocs, slipZscores,QCflags, meanProgressionSpeed,meanSpeedLocomoting, centroids, instProgressionSpeeds]  = analyzeSingleCamBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, CAMID, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO, CROPOFFSETADJ)

if ~exist('TASKID', 'var')
    TASKID =BB;
end

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end


if ~exist('SLIPTH', 'var')
    SLIPTH = 3;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 1;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end



if ~exist('CROPOFFSETADJ', 'var')
    CROPOFFSETADJ = 0.2;
end


CROPVIDEO = 1; % crop top and bottom, 1/4 each
%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, [TIMEPOINT '_' CAMID]);
if isempty(fileName)
    R = [];
    warning('No video loaded');
    return;
end
if (iscell(fileName))
    fileName = fileName{1};
end
fileID = getFileIDfromFilename (fileName);

[nSLIPS, slipIndex, slipLocs, slipZscores, QCflags, meanProgressionSpeed, meanSpeedLocomoting, centroids, instProgressionSpeeds] = analyzeSingleBBfile(dataFolder,fileName, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO, CROPOFFSETADJ);

