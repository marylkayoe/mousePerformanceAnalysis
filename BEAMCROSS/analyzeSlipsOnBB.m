function R = analyzeSlipsOnBB(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID)

if ~exist('TASKID', 'var')
    TASKID = OF;
end

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end
%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, OFfileID);
if isempty(fileName)
    R = [];
    warning('No video loaded');
    return;
end
fullFilePath = fullfile(dataFolder, fileName);
[videoMatrix newFilePath] = readBehaviorVideo(fullFilePath); % newFilePath is with .mp4 ending
%videoMatrix = readVideoIntoMatrix(newFilePath);

sumFrame = getSumFrame(videoMatrix);
meanFrame = getMeanFrame(videoMatrix);
sumSubtractedVideoMatrix = subtractFrom(videoMatrix, sumFrame);


medianFrame = getMedianFrame(sumSubtractedVideoMatrix);
barYcoord = findBarYCoordInImage(medianFrame);
croppedSubtractedVideoMatrix = cropVideoBelowBar(sumSubtractedVideoMatrix, barYcoord);

frameDifferences = getLocalizedFrameDifferences(croppedSubtractedVideoMatrix, 50);
slips=frameDifferences>100;
displayBehaviorVideoMatrix(imadjustn(croppedSubtractedVideoMatrix), frameDifferences, slips, 'foo');
figure;
findpeaks(frameDifferences, 'MinPeakProminence', 1000, "Annotate","peaks");
R = 1;


