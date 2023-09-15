function [meanSpeeds maxSpeeds locoTimes totalDistancesLocomoting, meanSpeedsLocomoting, centerFractions, filesProcessed] = analyzeOFforAnimal(dataFolder, EXPID, SAMPLEID, PIXELSIZE, MAKEPLOTS )
% analyze open field recordings for all files found for the SAMPLEID


if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


fileNames = getFilenamesForSamples(dataFolder, EXPID, SAMPLEID, 'OF');

nFiles = length(fileNames);
meanSpeeds = nan(nFiles, 1);
for file = 1:nFiles
    [meanSpeeds(file), maxSpeeds(file), locoTimes(file), totalDistance(file), totalDistancesLocomoting(file), meanSpeedsLocomoting(file), centerFractions(file)] = analyzeSingleOFfile(dataFolder, fileNames{file}, PIXELSIZE, MAKEPLOTS);
filesProcessed{file} = fileNames{file};
end
  
meanSpeeds = meanSpeeds';
maxSpeeds = maxSpeeds';
locoTimes = locoTimes';
totalDistancesLocomoting = totalDistancesLocomoting';
meanSpeedsLocomoting = meanSpeedsLocomoting';
centerFractions = centerFractions';
filesProcessed = filesProcessed';