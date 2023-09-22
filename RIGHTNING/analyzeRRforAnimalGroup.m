function [rrFrameCountsGroup, rrLengthsMSGroup, filesProcessedGroup, QCsGroup] = analyzeRRforAnimalGroup(dataFolder, EXPID, ANIMALIDS, STILLTHRESHOLD, STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO )
% analyze open field recordings for all files found for the SAMPLEID


if ~exist('STILLTHRESHOLD', 'var')
    STILLTHRESHOLD = 0.05;
end

if ~exist('STILLTHRESHOLDTIME', 'var')
    STILLTHRESHOLDTIME = 0.7;
end

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO =4;
end


if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


nANIMALS = length(ANIMALIDS);
for animal = 1:nANIMALS

    fileNamesForAnimal = getFilenamesForSamples(dataFolder, EXPID, ANIMALIDS(animal), 'RR');
    nFilesForAnimal = length(fileNamesForAnimal);

    for file = 1:nFilesForAnimal
        [rrFrameCounts(file) rrLengthsMS(file) QCs(file)] = analyzeSingleRRfile(dataFolder, fileNamesForAnimal(file),STILLTHRESHOLD, STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO);
        filesProcessed{file} = fileNamesForAnimal{file};
    end

    rrFrameCountsGroup(:, animal) = rrFrameCounts';
    rrLengthsMSGroup(:, animal) = rrLengthsMS';
    filesProcessedGroup(:, animal) = filesProcessed';
    QCsGroup(:, animal) = QCs';

end

QCfailed = find(QCsGroup == 0);
QCfailedFiles = filesProcessedGroup(QCfailed);
nFilesFailed = length(QCfailedFiles);

for fFile = 1:nFilesFailed
    analyzeSingleRRfile(dataFolder, QCfailedFiles{fFile}, STILLTHRESHOLD, STILLTHRESHOLDTIME, 1, DOWNSAMPLERATIO);
    title(['QC control flag raised, check RR length manually ' getFileIDfromFilename(QCfailedFiles{fFile})]);
    inputString = [getFileIDfromFilename(QCfailedFiles{fFile}) ' - Automatic measure of RR duration is ', num2str(rrFrameCountsGroup(QCfailed(fFile))) '. Please enter new value or enter if its ok.'];
    newRRframeVal = input(inputString);
    if ~isempty(newRRframeVal)
        rrFrameCountsGroup(QCfailed(fFile)) = newRRframeVal;
        frameRate = round(str2num(getFrameRateForVideo(dataFolder, QCfailedFiles{fFile})));
        rrLengthsMSGroup(QCfailed(fFile)) = round(newRRframeVal*1000 / frameRate);
    end

end

