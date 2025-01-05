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

% segment the frame into the background, two cameras and the balance bar using otsus multithresh

levels = multithresh(meanFrame, 2);
segMeanFrameCams = imquantize(meanFrame, levels);
% vertSum = sum(segMeanFrame, 2); % sum pixel values vertically
% horizSum = sum(segMeanFrame);
% 
% figure; imshow(segMeanFrame, []);
% figure; plot(vertSum);
% figure; plot(horizSum);




% cropping the video to contain only the vertical region between the cameras
% find cameras in the video; they are BLACK



if MEASUREBARMARKS % if we want to attempt to find the black marks
% find the black marks at the ends of the beam
[beamMarkPks, beamMarkLocs, beamMarkWidths, beamMarkProminence] = findpeaks(diff(horizSum), 'MinPeakProminence', 150);
% first and last peak mark the ends of white part of the beam
leftBeamMarkLoc = beamMarkLocs(1);
[beamMarkPks, beamMarkLocs, beamMarkWidths, beamMarkProminence] = findpeaks(-diff(horizSum), 'MinPeakProminence', 150);
rightBeamMarkLoc = beamMarkLocs(end);
% crop the mean frame to contain only the region between the beam marks
meanFrameCroppedHoriz = meanFrame(:, leftBeamMarkLoc:rightBeamMarkLoc);

else % just crop off 5 percent both left and right edge
    leftCrop = round(size(meanFrame, 2)*0.05);
    rightCrop = round(size(meanFrame, 2)*0.95);
    meanFrameCroppedHoriz = meanFrame(:, leftCrop:rightCrop);
    segMeanFrameCropHoriz = segMeanFrameCams(:, leftCrop:rightCrop);
end
[topCameraEdgeY, bottomCameraEdgeY] = findCameraEdgeCoordsInImage(meanFrameCroppedHoriz);



% find the balance bar in the video
[barYCoord, barWidth] = findBarYCoordInImage(meanFrameCroppedHoriz);

% crop the video to contain only the vertical extent defined by the cameras
croppedVideo = videoMatrix(topCameraEdgeY:bottomCameraEdgeY, leftCrop:rightCrop, :);
barYCoord = barYCoord - topCameraEdgeY;

% display new mean image of the cropped video
meanFrameCropped = getMeanFrame(croppedVideo);
figure; imshow(meanFrameCropped, []);
% display the bar position as a rectangle
hold on;

rectangle('Position', [1, barYCoord-barWidth/2, size(meanFrameCropped, 2), barWidth], 'EdgeColor', 'red');

R = 1;







