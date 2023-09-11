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


startThreshold = 0.05;
nFrameThreshold = FRAMERATE;

%RRfileID = '*.mp4';

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
%fullFilePath = fullfile(dataFolder, fileName);
%rrVideo = readBehaviorVideo(fullFilePath);
videoMatrix = readVideoIntoMatrix(fullFilePath);
% detecting still moment as the rightning should occur after 1 sec holding
[stillFrames, diffs] = detectStillnessInVideo(videoMatrix, startThreshold, nFrameThreshold);

[rrMask RRlengthFrames] = detectRRframes(diffs, stillFrames);


titleString = strjoin({EXPID SAMPLEID 'RR task duration :' num2str(RRlengthFrames/FRAMERATE) 'sek'});

figure; hold on;
showKeyFrames(videoMatrix, find(rrMask));
title (strjoin({titleString, ' RR frames: '}));

displayBehaviorVideoMatrix(videoMatrix, titleString, diffs, rrMask);
%displayBehaviorVideo(rrVideo, diffs, rrMask, titleString);
figure; hold on; 
xAx = makexAxisFromFrames(length(diffs), FRAMERATE);
plot(xAx, diffs);
plot(xAx, rrMask);
legend({'Diff', 'rightning'});
title (titleString);

