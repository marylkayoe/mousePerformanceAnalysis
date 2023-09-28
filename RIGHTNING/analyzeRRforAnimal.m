function [rrFrameCounts, rrLengthsMS, filesProcessed, QCs] = analyzeRRforAnimal(dataFolder, EXPID, ANIMALID, STILLTHRESHOLD, STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO )
% analyze open field recordings for all files found for the SAMPLEID


if ~exist('STILLTHRESHOLD', 'var')
    STILLTHRESHOLD = 0.07;
end

if isempty(STILLTHRESHOLD)
    STILLTHRESHOLD = 0.07;
end

if ~exist('STILLTHRESHOLDTIME', 'var')
    STILLTHRESHOLDTIME = 0.7;
end

if isempty(STILLTHRESHOLDTIME)
    STILLTHRESHOLDTIME = 0.7;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end


if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


fileNames = getFilenamesForSamples(dataFolder, EXPID, ANIMALID, 'RR');

nFiles = length(fileNames);
rrFrames = nan(nFiles, 1);
for file = 1:nFiles
    [rrFrameCounts(file) rrLengthsMS(file) QCs(file)] = analyzeSingleRRfile(dataFolder, fileNames(file),STILLTHRESHOLD, STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO);
filesProcessed{file} =  fileNames(file);
end

rrFrameCounts = rrFrameCounts';
rrLengthsMS = rrLengthsMS';
filesProcessed = filesProcessed';
QCs = QCs';

