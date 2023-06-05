function coordData = showMBCtrial(dataFolder,EXPID, SAMPLEID, TASKID, FRAMERATE, PIXELSIZE)
    % PIXELSIZE = how many mm one pixel is
    if ~exist('TASKID', 'var')
        TASKID = BMC;
    end
    
    if ~exist('PIXELSIZE', 'var')
        PIXELSIZE = 1;
    end
    
    if ~exist('FRAMERATE', 'var')
        FRAMERATE = 30;
    end

    BMCfileID = '*.mp4';

%% import the video file and make it into a grayscale matrix:
fileName = getFilenamesForSamples(dataFolder,EXPID, SAMPLEID, TASKID, BMCfileID);
fullFilePath = fullfile(dataFolder, fileName);
bmcVideo = readBehaviorVideo(fullFilePath);
videoMatrix = readVideoIntoMatrix(fullFilePath);

displayBehaviorVideo(bmcVideo, [], 1:length(videoMatrix), 'Beamcrossing');
