function R = BBanalysisSingleFile(dataPath, fileName, varargin)
% BBanalysisSingleFile: Analyze a single file of the balance beam video
% the video is assumed to be already converted to mp4

% Input arguments
% dataPath: path to the data folder
% fileName: name of the file to be analyzed
% varargin: optional arguments
%   'MAKEPLOT': make plots of the analysis

% Output arguments
% R: structure containing the results of the analysis


R.mouseCentroids = [];
R.forwardSpeeds = [];
R.traverseDuration = [];
R.meanSpeed = [];

% Parse input arguments
p = inputParser;
addRequired(p, 'dataPath', @ischar);
addRequired(p, 'fileName', @ischar);
addParameter(p, 'MAKEPLOT', true, @islogical);
addParameter(p, 'FRAMERATE', 160, @isnumeric);
addParameter(p, 'PIXELSIZE', 1,  @isnumeric);
addParameter(p, 'SLIPTHRESHOLD', 1, @isnumeric);
parse(p, dataPath, fileName, varargin{:});

dataPath = p.Results.dataPath;
fileName = p.Results.fileName;
MAKEPLOT = p.Results.MAKEPLOT;
FRAMERATE = p.Results.FRAMERATE;
PIXELSIZE = p.Results.PIXELSIZE;
SLIPTHRESHOLD = p.Results.SLIPTHRESHOLD;
%TODO: add spatial scaling


% check the file exists

if ~exist(fullfile(dataPath, fileName), 'file')
    warning('File does not exist, aborting...');
    R = -1;
    return;
end

% check the file is a .mp4 file
[~, ~, ext] = fileparts(fileName);
if ~strcmp(ext, '.mp4')
    warning('File is not an mp4 file, aborting...');
    R = -1;
    return;
end

filePath = fullfile(dataPath, fileName);

% load the video into a matrix
[videoMatrix, frameRate] = readVideoIntoMatrix(filePath, 'enhanceContrast', false);


% get mean frame to base the cropping and element localization on
meanFrame = getMeanFrame(videoMatrix);

% crop 5% off left and right - there are black marks on the beam that can
% cause trouble

leftCropIndex = round(size(meanFrame, 2)*0.05);
rightCropIndex = round(size(meanFrame, 2)*0.95);
meanFrameCroppedHoriz = meanFrame(:, leftCropIndex:rightCropIndex);

% find edges of the camera rectangles in vertical direction
[topCameraEdgeY, bottomCameraEdgeY] = findCameraEdgeCoordsInImage(meanFrameCroppedHoriz);

% find the balance bar in the video
[barYCoordTop, barWidth] = findBarYCoordInImage(meanFrameCroppedHoriz);

% crop the video to contain only the vertical extent defined by the cameras
croppedVideo = videoMatrix(topCameraEdgeY:bottomCameraEdgeY, :, :);
[imHeight, imWidth, nFrames] = size(croppedVideo);

barYCoordTopCrop = barYCoordTop - topCameraEdgeY;

[mouseCentroids,  forwardSpeeds, meanSpeed, traverseDuration, meanPosturalHeight,mouseMaskMatrix, trackedVideo, croppedOriginalVideo] = BBtrackingMouse(croppedVideo);
mouseCentroids(:, 2) = imHeight - mouseCentroids(:, 2)+1; % flip coordinates
mouseCentroids(:, 2) = mouseCentroids(:,2)-barYCoordTopCrop;
[maskHeight, maskWidth, maskFrames] = size(mouseMaskMatrix);

% the region under the bar that we will look at
underBarCroppedVideo = trackedVideo(barYCoordTopCrop+barWidth/2:barYCoordTopCrop+barWidth*2, :, :);
% as we don't want to think about the tail, blanking out the regions
% outside mouse
%[blankedUnderBarVideo, blankMat] = blankOutsideMouse(underBarCroppedVideo, mouseMaskMatrix, 255, 0.2);
[normMouseProbVals, mouseProbMatrix] = getMouseProbOnBeam(mouseMaskMatrix);
movementTrace = quantifyWeightedMovement(underBarCroppedVideo, normMouseProbVals);
[slipEventStarts, slipEventPeaks, slipEventAreas, slipEventDurations] = ...
    detectSlipsFromMovement(movementTrace, SLIPTHRESHOLD);

% make a plot of the movement trace with slips indicated
if MAKEPLOT
    figure; hold on;
    xAx = makexAxisFromFrames(length(movementTrace), FRAMERATE);
    plot(movementTrace);
    hold on;
    if ~isempty(slipEventStarts)
        scatter(slipEventStarts, movementTrace(slipEventStarts), slipEventAreas*20, 'o', 'filled');
    end
    title('Movement trace with detected slips');
    xlabel('Frame number');
    ylabel('Movement');

    % plot x and y coordinates in 2d
 figure; hold on;
    plot(mouseCentroids(:,1), mouseCentroids(:,2), 'LineWidth',2);
    scatter(mouseCentroids(:,1), mouseCentroids(:,2),  50, forwardSpeeds, 'filled');
    xlabel('Position along bar');
    ylabel('Height above bar');
    if ~isempty(slipEventStarts)
    scatter(mouseCentroids(slipEventStarts, 1), mouseCentroids(slipEventStarts, 2), slipEventAreas*20, 'ko', 'filled' );
    end
    colormap('cool');
    ylim([0 30]);

    % add colorbar and label
    c = colorbar;
    c.Label.String = 'Forward speed (pixels/s)';
    caxis([0, max(forwardSpeeds)]);

    title('Mouse position in the video');

    % check which direction mouse goes and add arrow
    if (mouseCentroids(1, 1) < mouseCentroids(end, 1)) % we go left to right
        % add arrow within the subplot area to indicate direction
        annotation('arrow', [0.2, 0.3], [0.5, 0.5], 'Units', 'normalized');
        text(0.25, 0.5, 'Forward', 'Units', 'normalized');
     
    else

        % add arrow pointing to the left and text "forward"
        annotation('arrow', [0.3, 0.2], [0.5, 0.5], 'Units', 'normalized');
        text(0.25, 0.5, 'Forward', 'Units', 'normalized');

    end
    % add textbox with mean speed, traverse duration and filename
    text(0.1, 0.25, ['Mean speed: ', num2str(meanSpeed), ' pixels/s'], 'Units', 'normalized');
    text(0.1, 0.2, ['Traverse duration: ', num2str(traverseDuration), ' s'], 'Units', 'normalized');
    text(0.1, 0.15, ['Mean postural height: ', num2str(meanPosturalHeight), ' pixels'], 'Units', 'normalized');
    text(0.1, 0.1, ['File: ', cleanUnderscores(fileName)], 'Units', 'normalized');

   % displayBehaviorVideoMatrix(trackedVideo);
end
R.mouseCentroids = mouseCentroids;
R.forwardSpeeds = forwardSpeeds;
R.traverseDuration = traverseDuration;
R.meanSpeed = meanSpeed;
R.BBvideo = trackedVideo;
R.slipEventStarts = slipEventStarts;
R.slipEventAreas = slipEventAreas;
R.slipEventDurations = slipEventDurations;
R.slipEventPeaks = slipEventPeaks;
R.nSlips = length(slipEventStarts);
R.totalSlipMagnitude = sum(slipEventAreas);
R.meanSlipAmplitude = mean(slipEventAreas);
end







