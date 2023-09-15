function [rrFrameCounts, filesProcessed, QCs] = analyzeRRforAnimal(dataFolder, EXPID, ANIMALID, STILLTHRESHOLD, FRAMERATE, MAKEPLOTS )
% analyze open field recordings for all files found for the SAMPLEID


if ~exist('FRAMERATE', 'var')
    FRAMERATE = 60;
end


if ~exist('STILLTHRESHOLD', 'var')
    STILLTHRESHOLD = 0.05;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


fileNames = getFilenamesForSamples(dataFolder, EXPID, ANIMALID, 'RR');

nFiles = length(fileNames);
rrFrames = nan(nFiles, 1);
for file = 1:nFiles
    [rrFrameCounts(file) QCs(file)] = analyzeSingleRRfile(dataFolder, fileNames(file), FRAMERATE,STILLTHRESHOLD, MAKEPLOTS);
filesProcessed{file} =  fileNames(file);
end

rrFrameCounts = rrFrameCounts';
filesProcessed = filesProcessed';
QCs = QCs';

