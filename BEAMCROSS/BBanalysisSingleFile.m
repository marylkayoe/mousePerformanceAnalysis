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
parse(p, dataPath, fileName, varargin{:});

dataPath = p.Results.dataPath;
fileName = p.Results.fileName;
MAKEPLOT = p.Results.MAKEPLOT;
FRAMERATE = p.Results.FRAMERATE;

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



barYCoordTop = barYCoordTop - topCameraEdgeY;

mouseCentroids = BBtrackingMouse(croppedVideo);
mouseCentroids(:, 2) = imHeight - mouseCentroids(:, 2)+1; % flip coordinates

% check the period when mouse is seen, longest continuous non-NAN period
% is the period when the mouse is on the beam
% use morphological operations to find period of non-nan
mouseFoundFrames = ~isnan(mouseCentroids(:,1));
mouseFoundFrames = imclose(mouseFoundFrames, strel('disk', 5));
mouseFoundFrames = bwareaopen(mouseFoundFrames, 10);
mouseFoundPeriods = regionprops(mouseFoundFrames, 'Area', 'PixelIdxList');
[~, longestPeriodIndex] = max([mouseFoundPeriods.Area]);
longestPeriod = mouseFoundPeriods(longestPeriodIndex).PixelIdxList;
mouseCentroids = mouseCentroids(longestPeriod, :);

% crop the video to the longest period
croppedVideo = croppedVideo(:,:,longestPeriod);




% calculate instantaneous speed of the mouse, using FRAMERATE
% calculate the distance between consecutive frames in X dimension only
forwardSpeeds = nan(length(mouseCentroids),1);
velWin = floor(FRAMERATE/10);
[frameDisplacements ] = pdist2(mouseCentroids(2:end,1), mouseCentroids(1:end-1,1), 'euclidean');
winDisplacements = diag(frameDisplacements, -velWin);

forwardSpeeds(1:length(winDisplacements)) = winDisplacements / (velWin / FRAMERATE);




% plot x and y coordinates in 2d
figure; hold on;
plot(mouseCentroids(:,1), mouseCentroids(:,2), 'LineWidth',2);
scatter(mouseCentroids(:,1), mouseCentroids(:,2),  50, forwardSpeeds, 'filled');
xlabel('X coordinate');
ylabel('Y coordinate');
colormap('cool');
% add colorbar and label

c = colorbar;
c.Label.String = 'Speed (pixels/s)';
caxis([0, max(forwardSpeeds)]);

title('Mouse position in the video');
% add horizontal line indicating bar position
hold on;
line([1, size(croppedVideo, 2)], [barYCoordTop, barYCoordTop], 'Color', 'k', 'LineWidth', 6);



R.mouseCentroids = mouseCentroids;
R.forwardSpeeds = forwardSpeeds;
R.traverseDuration = length(forwardSpeeds) / FRAMERATE;
R.meanSpeed = nanmean(forwardSpeeds);
end







