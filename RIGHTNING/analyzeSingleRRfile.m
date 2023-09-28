function [RRlengthFrames RRlengthMS QC]= analyzeSingleRRfile(dataFolder, fileName, STILLTHRESHOLD, STILLTHRESHOLDTIME, MAKEPLOTS, DOWNSAMPLERATIO)


if ~exist('TIMEPOINT', 'var')
    TIMEPOINT = 'D07';
end

if ~exist('STILLTHRESHOLD', 'var')
    STILLTHRESHOLD = 0.07;
end

if isempty(STILLTHRESHOLD)
    STILLTHRESHOLD = 0.07;
end

if ~exist('STILLTHRESHOLDTIME', 'var') % time (in sec) of stillness used to detect the hold period
    STILLTHRESHOLDTIME = 0.7;
end


if isempty(STILLTHRESHOLDTIME)
    STILLTHRESHOLDTIME = 0.7;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 2;
end


if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


if (isunix)
    separator = '/';
else
    separator = '\';
end



if iscell(fileName)
    fileName = fileName{1};
end

% import video data, converting from avi to mp4 if needed (4x spatial downsample)

fullFilePath = fullfile(dataFolder, fileName);
[~, name, ext] = fileparts(fileName);
if ~strcmp(ext, '.mp4')
    %warning('Provided filename indicates incorrect format (should be mp4).. seeking right version');
    newFilePath = convertToMP4(fullFilePath, DOWNSAMPLERATIO);
    if isempty(newFilePath)
        disp('Failed conversion, aborting');
        return;
    end
    fullFilePath = newFilePath;
end
if iscell(fileName)
    fileName = fileName{1};
end

fileID = getFileIDfromFilename (fileName);

[videoMatrix FRAMERATE]= readVideoIntoMatrix(fullFilePath);
FRAMERATE = floor(FRAMERATE); %round down to nearest integer
nFrameThreshold = floor(FRAMERATE*STILLTHRESHOLDTIME);
% crop out the top and bottom thirds from the video
croppedVideoMatrix = cropVideoMid(videoMatrix, 3);


QCtimelimit = FRAMERATE; %if found RR is longer than 1 sec raise QC flag



% detecting still moment as the rightning should occur after 1 sec (nFrameThreshold frames) holding
[stillFrames, diffs] = detectStillnessInVideo(croppedVideoMatrix, STILLTHRESHOLD, nFrameThreshold);
if ~find(any(stillFrames))
    warning(['Stillness detection failed for file', fileName]);
end


% defining the rightning response (as a burst of activity after the HOLD
% period
[rrMask RRlengthFrames QC] = detectRRframes(diffs, stillFrames);
if RRlengthFrames > QCtimelimit
    QC = 0;
end
RRlengthMS = round(RRlengthFrames*1000 / FRAMERATE);
if isempty(rrMask)
    warning(['RR detection failed for file', fileName]);
end

%% PLOTTING
if MAKEPLOTS
    figure; hold on;
    titleString = strjoin({fileID 'RR task duration :' num2str(RRlengthFrames/FRAMERATE, '%.2f')  'sek'});
    showKeyFrames(videoMatrix, find(rrMask));
    title (strjoin({fileID, ' RR frames: '}));

    displayBehaviorVideoMatrix(videoMatrix, titleString, diffs, rrMask);

    figure; hold on;
    xAx = makexAxisFromFrames(length(diffs), FRAMERATE);
    plot( diffs);
    if(find(any(rrMask)))
        if QC
        plot( rrMask, 'g', 'LineWidth', 2);
        else
            plot( rrMask, 'r', 'LineWidth', 2);
        end
    end

    if(find(any(stillFrames)))
        plot( stillFrames, 'LineWidth', 2);
    end

    legend({'Movement', 'RR', 'HOLD'});
    xlabel('FRAMES');


    title ([fileID ' RR duration ' num2str(RRlengthMS) ' ms']);
end
