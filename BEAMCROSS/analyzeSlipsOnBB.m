function R = analyzeSlipsOnBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, CAMID)

if ~exist('TASKID', 'var')
    TASKID = OF;
end

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

DOWNSAMPLERATIO = 2;
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
fullFilePath = fullfile(dataFolder, fileName);
[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo(fullFilePath, DOWNSAMPLERATIO); % newFilePath is with .mp4 ending

[centroids mouseMaskMatrix] = trackMouseInBB(videoMatrix );


sumFrame = getSumFrame(videoMatrix);
meanFrame = getMeanFrame(videoMatrix);
sumSubtractedVideoMatrix = subtractFrom(videoMatrix, sumFrame);

% medianSubtractedVideoMatrix = subtractFrom(videoMatrix, medianFrame);
 medianFrame = getMedianFrame(sumSubtractedVideoMatrix);
barYcoord = findBarYCoordInImage(medianFrame);
croppedSubtractedVideoMatrix = cropVideoBelowBar(sumSubtractedVideoMatrix, barYcoord);

frameDifferences = getLocalizedFrameDifferences(croppedSubtractedVideoMatrix, 100);
slips=frameDifferences>0.5;
displayBehaviorVideoMatrix(imadjustn(croppedSubtractedVideoMatrix), fileName, frameDifferences, slips);
figure;
findpeaks(frameDifferences, 'MinPeakProminence', 0.5, "Annotate","peaks");
blankedVideoMatrix = videoMatrix;
blankedVideoMatrix(:, :, frameDifferences<0.02) = 0;

R = 1;


