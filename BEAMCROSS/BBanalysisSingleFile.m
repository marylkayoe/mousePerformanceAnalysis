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
R = 0;
% Default values
MAKEPLOT = false;

% Parse input arguments
p = inputParser;
addRequired(p, 'dataPath', @ischar);
addRequired(p, 'fileName', @ischar);
addParameter(p, 'MAKEPLOT', MAKEPLOT, @islogical);
parse(p, dataPath, fileName, varargin{:});

dataPath = p.Results.dataPath;
fileName = p.Results.fileName;
MAKEPLOT = p.Results.MAKEPLOT;

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
barYCoordTop = barYCoordTop - topCameraEdgeY;

% display new mean image of the cropped video
meanFrameCropped = getMeanFrame(croppedVideo);
figure; imshow(meanFrameCropped, []);
% display the bar position as a rectangle
hold on;
rectangle('Position', [1, barYCoordTop, size(meanFrameCropped, 2), barWidth], 'EdgeColor', 'red');
%displayBehaviorVideoMatrix(croppedVideo);
R = 1;







