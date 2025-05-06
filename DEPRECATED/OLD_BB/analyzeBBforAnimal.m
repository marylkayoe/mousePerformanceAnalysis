function [nSLIPSs, slipIndexes, slipLocs, meanProgressionSpeeds,meanSpeedsLocomoting, instProgressionSpeeds, filesProcessed ]= analyzeBBforAnimal(dataFolder, EXPID, ANIMALID, CAMID, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO, CROPOFFSETADJ )
% analyze open field recordings for all files found for the SAMPLEID


if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 0.25;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

if ~exist('CAMID', 'var')
    CAMID = 'Cam2';
end

if ~exist('SLIPTH', 'var')
    SLIPTH = 3;
end

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end

if ~exist('CROPOFFSETADJ', 'var')
    CROPOFFSETADJ = 0.2;
end

TASKID = 'BB';


%fileNames = getFilenamesForSamples(dataFolder, EXPID, ANIMALID, 'BB');s
fileNames = getFilenamesForSamples(dataFolder,EXPID, ANIMALID, TASKID, ['*_' CAMID]);
nFiles = length(fileNames);
MAKEPLOTS = 1;
for file = 1:nFiles
    [nSLIPSs(file), slipIndexes(file), slipLocs{file}, slipZscores{file},QCflags{file}, meanProgressionSpeeds(file), meanSpeedsLocomoting(file), instProgressionSpeeds{file}]  = analyzeSingleBBfile(dataFolder,fileNames{file}, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO, CROPOFFSETADJ);
    filesProcessed{file} = fileNames{file};
end

nSLIPSs = nSLIPSs';
slipIndexes = slipIndexes';
meanProgressionSpeeds = meanProgressionSpeeds';
meanSpeedsLocomoting = meanSpeedsLocomoting';
filesProcessed = filesProcessed';
