function [nSLIPS, slipIndex, slipLocs, slipZscores, QCflags, meanProgressionSpeed, meanSpeedLocomoting, mouseCentroids, instProgressionSpeeds] = analyzeSingleBBfile(dataFolder,fileName, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO, CROPOFFSETADJ)

% process one file for balance beam trials


if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 0.25;
end

if ~exist('SLIPTH', 'var')
    SLIPTH = 2;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end
if ~exist('CROPOFFSETADJ', 'var')
    CROPOFFSETADJ = 0;
end



PIXELSIZE = PIXELSIZE * DOWNSAMPLERATIO;
CROPVIDEO = 1; % crop top and bottom, 1/4 each

FILEID = getFileIDfromFilename (fileName);

fullFilePath = fullfile(dataFolder, fileName);
[videoMatrix newFilePath FRAMERATE] = readBehaviorVideo(fullFilePath, DOWNSAMPLERATIO, CROPVIDEO, CROPOFFSETADJ); % newFilePath is with .mp4 ending
[ imHeight imWidth nFRAMES] = size(videoMatrix);

[mouseCentroids, instProgressionSpeeds, isLocomoting, meanSpeedLocomoting, mouseMaskMatrix, blankedFrames, handFrameIdx]= trackMouseInBB(videoMatrix, PIXELSIZE, FRAMERATE );
   


% now track what happens under the bar.. crop only below bar
underBarVideoMatrix = cropVideoBelowBar(videoMatrix);
%blank frames without mouse
blankedUnderBarVideoMatrix = underBarVideoMatrix;
blankedUnderBarVideoMatrix(:, :, blankedFrames) = 0;


% probability of mouse being in a current position along the bar
noMouseFrames = find(isnan(mouseCentroids(:, 1)));
if (length(noMouseFrames) > nFRAMES*0.95)
    warning('Possibly low quality recording, mouse not tracked correctly, check results');
    QCflags = 0;
    underBarDiffs = getLocalizedFrameDifferences(underBarVideoMatrix, FRAMERATE/10, FRAMERATE);
    underBarDiffs = smooth(underBarDiffs,FRAMERATE/10);
    underBarDiffs = zscore(underBarDiffs);
    underBarDiffs(underBarDiffs<SLIPTH) = 0;

else

    % get movement value weighted by mouse presence
    [mouseProbVals mouseProbMatrix] = getMouseProbOnBeam(mouseMaskMatrix);
    underBarDiffs = getHighProbFrameDifferences(blankedUnderBarVideoMatrix, mouseProbVals, FRAMERATE/10, SLIPTH);
end
% find peaks in the (zscored) movement under themouse
[pks, slipLocs, w, p] = findpeaks(underBarDiffs, 'MinPeakDistance', FRAMERATE/10);

%track the hand so we can omit those frames from slips
% [isHandInFrame handFrameIdx handMaskMatrix] = trackHandInBB(videoMatrix, mouseMaskMatrix,PIXELSIZE, FRAMERATE);
% % remove "slips" from data if hand was in the frame
%  [hf, idx] = intersect(slipLocs, handFrameIdx);
% disp(['FYI, ' num2str(length(idx)) ' slips potentially had hand in frame ']);
% slipLocs(idx) = [];
slipLocs(pks>(SLIPTH*4)) = [];
nSLIPS = length(slipLocs);
meanProgressionSpeed = round(mean(instProgressionSpeeds, 'omitnan'), 1);
blankedUnderBarDiffs = underBarDiffs;
slipIndex = round(sum (blankedUnderBarDiffs));
slipZscores = underBarDiffs(slipLocs);
QCflags = slipZscores<(SLIPTH+SLIPTH*0.1);

if MAKEPLOTS

    %show the frames with slip peaks
    CAMID = getCAMIDfromFilename(fileName);
    FILEID = getFileIDfromFilename (fileName);
    showKeyFrames(videoMatrix, slipLocs,  ['SLIP FRAMES in ' FILEID ', ' CAMID ', with frame slip Zscores'], slipZscores);
    %plotOpenFieldTrial(centroids,underBarDiffs, slipLocs, '', FRAMERATE, PIXELSIZE, fileID, ['SLIP PROBABILITY from ' CAMID]);
    %plotBBTrial(centroids,underBarDiffs, slipLocs, FRAMERATE, PIXELSIZE, FILEID, ['SLIP PROBABILITY from ' CAMID], 'SLIP PROB');
    %ylim([0 imHeight]);
    titlestring = ['Speed on BB from ' CAMID];
    %plotOpenFieldTrial(centroids,[0 instProgressionSpeeds'], slipLocs, '', FRAMERATE, PIXELSIZE, fileID, titlestring);
    plotBBTrial(mouseCentroids,[0 instProgressionSpeeds'], slipLocs, FRAMERATE, PIXELSIZE, FILEID, ['Speed from ' CAMID], 'Mouse speed (mm/s)');

    %displayBehaviorVideoMatrix(mouseMaskMatrix, [FILEID '-UBmov-SLIPPING'],blankedUnderBarDiffs, blankedUnderBarDiffs>SLIPTH, 0);
    %displayBehaviorVideoMatrix(videoMatrix, [FILEID CAMID '-speed-SLIPPING'], instProgressionSpeeds, blankedUnderBarDiffs>SLIPTH, 0);
end


