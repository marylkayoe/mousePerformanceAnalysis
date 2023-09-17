function RRlengthFrames = showRightningTrial(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, DOWNSAMPLERATIO)


if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = 'D07';
end

if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end


if (isunix)
    separator = '/';
else
    separator = '\';
end


STILLNESHRESHOLD = 0.07; % fraction of moving pixels that is accepted during "HOLD"
STILLTHRESHOLDTIME = 0.7;


% import video data, converting from avi to mp4 if needed (4x spatial downsample)

fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT);
fullFilePath = fullfile(dataFolder, fileName);
[~, name, ext] = fileparts(fileName);
if ~strcmp(ext, '.mp4')
    warning('Provided filename indicates incorrect format (should be mp4).. seeking right version');
    newFilePath = convertToMP4(fullFilePath{1}, DOWNSAMPLERATIO);
    if isempty(newFilePath)
        disp('Failed conversion, aborting');
        return;
    end
    fullFilePath = newFilePath;
end
[videoMatrix FRAMERATE]= readVideoIntoMatrix(fullFilePath);
FRAMERATE = floor(FRAMERATE); %round down to nearest integer
% crop out the top and bottom thirds from the video
croppedVideoMatrix = cropVideoMid(videoMatrix, 3);


% detecting still moment as the rightning should occur after 1 sec holding
[stillFrames, diffs] = detectStillnessInVideo(croppedVideoMatrix, STILLNESHRESHOLD, FRAMERATE*STILLTHRESHOLDTIME);
if ~(any(stillFrames))
    warning(['Stillness detection failed for file', fileName{1}]);
end

% defining the rightning response (as a burst of activity after the HOLD
% period
[rrMask RRlengthFrames QC] = detectRRframes(diffs, stillFrames);
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
plot( diffs);

plot( stillFrames, 'LineWidth', 2);

plot( rrMask, 'g', 'LineWidth', 2);

if (QC)
    legend({'Diff', 'stillness', 'rightning'});
else
    legend({'Diff', 'stillness', 'rightning (guessed)'});
end

xlabel('FRAMES');


title (titleString);



