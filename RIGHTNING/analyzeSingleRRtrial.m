function [RRlengthFrames RRlengthMS QC] = analyzeSingleRRtrial(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT,STILLTHRESHOLD, STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO)

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = 'D07';
end

if ~exist('STILLTHRESHOLD', 'var')
    STILLTHRESHOLD = 0.07;
end

if isempty(STILLTHRESHOLD)
    STILLTHRESHOLD = 0.07;
end


if ~exist('STILLTHRESHOLDTIME', 'var') %how many seconds must the hold last
    STILLTHRESHOLDTIME = 0.7;
end

if isempty(STILLTHRESHOLDTIME)
    STILLTHRESHOLDTIME = 0.7;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end


if (isunix)
    separator = '/';
else
    separator = '\';
end

RRlengthFrames = nan;
RRlengthMS = nan;
QC = 0;

%STILLNESHRESHOLD = 0.05; % fraction of moving pixels that is accepted during "HOLD"
nFrameThreshold = floor(FRAMERATE*STILLTHRESHOLDTIME);

% find the right filename
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT);

if isempty(fileName)
    warning ('File not found');
else
    [RRlengthFrames RRlengthMS QC]= analyzeSingleRRfile(dataFolder, fileName, STILLTHRESHOLD,STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO)
end

