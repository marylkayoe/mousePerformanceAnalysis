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

DOWNSAMPLERATIO = 4;
PIXELSIZE = PIXELSIZE * DOWNSAMPLERATIO;
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

fullFilePath = fullfile(dataFolder, fileName);
[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo(fullFilePath, DOWNSAMPLERATIO, CROPVIDEO); % newFilePath is with .mp4 ending

[centroids instProgressionSpeeds locoFrames mouseMaskMatrix]= trackMouseInBB(videoMatrix, PIXELSIZE, FRAMERATE );
displayBehaviorVideoMatrix(mouseMaskMatrix, fileID, instProgressionSpeeds, locoFrames, 0);
displayBehaviorVideoMatrix(videoMatrix, fileID, instProgressionSpeeds, locoFrames, 0);
    
titlestring = ['BB centroid from ' CAMID];
plotOpenFieldTrial(centroids,[0 instProgressionSpeeds'], '', '', FRAMERATE, PIXELSIZE, fileID, titlestring);
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


