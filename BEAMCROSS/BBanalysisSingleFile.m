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
% Default values
MAKEPLOT = false;

% Parse input arguments
p = inputParser;
addRequired(p, 'dataPath', @ischar);
addRequired(p, 'fileName', @ischar);
addParameter(p, 'MAKEPLOT', MAKEPLOT, @islogical);
addParameter(p, 'FRAMERATE', 160, @isnumeric);
addParameter(p, 'PIXELSIZE', 1,  @isnumeric);
parse(p, dataPath, fileName, varargin{:});

dataPath = p.Results.dataPath;
fileName = p.Results.fileName;
MAKEPLOT = p.Results.MAKEPLOT;
FRAMERATE = p.Results.FRAMERATE;
PIXELSIZE = p.Results.PIXELSIZE;
%TODO: add spatial scaling
MEASUREBARMARKS = false;


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
[maskHeight, maskWidth, maskFrames] = size(mouseMaskMatrix);

% the region under the bar that we will look at
underBarCroppedVideo = trackedVideo(barYCoordTopCrop+barWidth/2:barYCoordTopCrop+barWidth*2, :, :);
blankedUnderBarVideo = blankOutsideMouse(underBarCroppedVideo, mouseMaskMatrix, 1, 0.1);
% as we don't want to think about the tail, blanking out the regions og
[blankedUnderBarVideo, blankMat] = blankOutsideMouse(underBarCroppedVideo, mouseMaskMatrix, 255, 0.2);
movementTrace = quantifyTrunkMovement(blankedUnderBarVideo, blankMat);

% plot x and y coordinates in 2d
figure; hold on;
plot(mouseCentroids(:,1), mouseCentroids(:,2)-barYCoordTopCrop, 'LineWidth',2);
scatter(mouseCentroids(:,1), mouseCentroids(:,2)-barYCoordTopCrop,  50, forwardSpeeds, 'filled');
xlabel('Position along bar');
ylabel('Height above bar');
colormap('cool');
ylim([0 30]);
% add colorbar and label

c = colorbar;
c.Label.String = 'Forward speed (pixels/s)';
caxis([0, max(forwardSpeeds)]);

title('Mouse position in the video');
% add horizontal line indicating bar position
%hold on;
%line([1, size(croppedVideo, 2)], [barYCoordTop, barYCoordTop], 'Color', 'k', 'LineWidth', 6);

% add textbox with mean speed, traverse duration and filename
text(0.1, 0.15, ['Mean speed: ', num2str(meanSpeed), ' pixels/s'], 'Units', 'normalized');
text(0.1, 0.1, ['Traverse duration: ', num2str(traverseDuration), ' s'], 'Units', 'normalized');
text(0.1, 0.05, ['Mean postural height: ', num2str(meanPosturalHeight), ' pixels'], 'Units', 'normalized');
text(0.1, 0.01, ['File: ', cleanUnderscores(fileName)], 'Units', 'normalized');

displayBehaviorVideoMatrix(trackedVideo);

R.mouseCentroids = mouseCentroids;
R.forwardSpeeds = forwardSpeeds;
R.traverseDuration = traverseDuration;
R.meanSpeed = meanSpeed;
R.BBvideo = trackedVideo;
end







