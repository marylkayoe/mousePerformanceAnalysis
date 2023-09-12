function RRlengthFrames = showRightningTrial(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, FRAMERATE)

if ~exist('FRAMERATE', 'var')
    FRAMERATE = 30;
end

if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = 'D07';
end

if (isunix)
    separator = '/';
else
    separator = '\';
end


STILLNESHRESHOLD = 0.05; % fraction of moving pixels that is accepted during "HOLD"
nFrameThreshold = FRAMERATE;

% import video data, converting from avi to mp4 if needed (4x spatial downsample)

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT);
fullFilePath = fullfile(dataFolder, fileName);
[~, name, ext] = fileparts(fileName);
if ~strcmp(ext, '.mp4')
    warning('Provided filename indicates incorrect format (should be mp4).. seeking right version');
    newFilePath = convertToMP4(fullFilePath{1});
    if isempty(newFilePath)
        disp('Failed conversion, aborting');
        return;
    end
    fullFilePath = newFilePath;
end
videoMatrix = readVideoIntoMatrix(fullFilePath);
% crop out the top and bottom thirds from the video
croppedVideoMatrix = cropVideoMid(videoMatrix, 3);
%[centroids mouseMaskMatrix] = trackMouseInRR(croppedVideoMatrix);
% detecting still moment as the rightning should occur after 1 sec holding
[stillFrames, diffs] = detectStillnessInVideo(croppedVideoMatrix, STILLNESHRESHOLD, nFrameThreshold);
if ~find(any(stillFrames))
    warning(['Stillness detection failed for file', fileName{1}]);
end


%[stillFrames, diffsM] = detectStillnessInVideo(mouseMaskMatrix, STILLNESHRESHOLD, nFrameThreshold);

% defining the rightning response (as a burst of activity after the HOLD
% period
[rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames);
if isempty(rrMask)
    warning(['RR detection failed for file', fileName{1}]);
end

%% PLOTTING
figure; hold on;
titleString = strjoin({EXPID SAMPLEID 'RR task duration :' num2str(RRlengthFrames/FRAMERATE) 'sek'});
showKeyFrames(videoMatrix, find(rrMask));
title (strjoin({titleString, ' RR frames: '}));

displayBehaviorVideoMatrix(videoMatrix, titleString, diffs, rrMask);

figure; hold on;
xAx = makexAxisFromFrames(length(diffs), FRAMERATE);
plot(xAx, diffs);

if(find(any(stillFrames)))
    plot(xAx, stillFrames, 'LineWidth', 2);
end

if(find(any(rrMask)))
    plot(xAx, rrMask, 'g', 'LineWidth', 2);
end
legend({'Diff', 'stillness', 'rightning'});


title (titleString);

