function [meanSpeedsGroup maxSpeedsGroup locoTimesGroup totalDistancesLocomotingGroup, meanSpeedsLocomotingGroup, centerFractionsGroup, filesProcessedGroup] = analyzeOFforAnimalGroup(dataFolder, EXPID, SAMPLEIDS, PIXELSIZE, MAKEPLOTS )
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

nANIMALS = length(SAMPLEIDS);
for animal = 1:nANIMALS

    fileNamesForAnimal = getFilenamesForSamples(dataFolder, EXPID, SAMPLEIDS(animal), 'OF');

    nFilesForAnimal = length(fileNamesForAnimal);
   % meanSpeeds = nan(nFilesForAnimal, 1);
    for file = 1:nFilesForAnimal
        [meanSpeeds(file), maxSpeeds(file), locoTimes(file), totalDistance(file), totalDistancesLocomoting(file), meanSpeedsLocomoting(file), centerFractions(file)] = analyzeSingleOFfile(dataFolder, fileNamesForAnimal{file}, PIXELSIZE, MAKEPLOTS);
        filesProcessed{file} = fileNamesForAnimal{file};
    end

    meanSpeedsGroup(:, animal) = meanSpeeds';
    maxSpeedsGroup(:, animal) = maxSpeeds';
    locoTimesGroup(:, animal) = locoTimes';
    totalDistancesLocomotingGroup(:, animal) = totalDistancesLocomoting';
    meanSpeedsLocomotingGroup(:, animal) = meanSpeedsLocomoting';
    centerFractionsGroup(:, animal) = centerFractions';
    filesProcessedGroup(:, animal)= filesProcessed';

end