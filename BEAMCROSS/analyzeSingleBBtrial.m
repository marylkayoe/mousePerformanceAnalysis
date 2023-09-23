function [nSLIPS, slipIndex, slipLocs,QCflags, meanProgressionSpeed, centroids, instProgressionSpeeds]  = analyzeSingleBBtrial(dataFolder,EXPID, SAMPLEID, TIMEPOINT, SLIPTH, PIXELSIZE, MAKEPLOTS, CROPOFFSETADJ, DOWNSAMPLERATIO)

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 0.25;
end


if ~exist('SLIPTH', 'var')
    SLIPTH = 3;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end

if ~exist('CROPOFFSETADJ', 'var')
    CROPOFFSETADJ = 0.2;
end

TASKID = 'BB';
%FILE info (used for plotting)
fileName = getFilenamesForSamples(dataFolder, EXPID, SAMPLEID, TASKID, TIMEPOINT, '', 'Cam1');
frameRate = getFrameRateForVideo(dataFolder, fileName);
fileID = getFileIDfromFilename (fileName);


% run the analysis for two camera files
[nSLIPSCAM1, slipIndexCAM1, slipLocsCAM1, slipZscoresCAM1,QCflagsCAM1, meanProgressionSpeedCAM1, meanLocoSpeedCAM1, centroidsCAM1, instProgressionSpeedsCAM1]  = analyzeSingleCamBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, 'Cam1', SLIPTH, PIXELSIZE, 1, DOWNSAMPLERATIO, CROPOFFSETADJ);
[nSLIPSCAM2, slipIndexCAM2, slipLocsCAM2, slipZscoresCAM2,QCflagsCAM2, meanProgressionSpeedCAM2, meanLocoSpeedCAM1, centroidsCAM2, instProgressionSpeedsCAM2]  = analyzeSingleCamBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, 'Cam2', SLIPTH, PIXELSIZE, 1, DOWNSAMPLERATIO, CROPOFFSETADJ);


%% COMBINE cam results
nSLIPS = mean([nSLIPSCAM1 nSLIPSCAM2], 'omitnan');
slipIndex = mean([slipIndexCAM1 slipIndexCAM2], 'omitnan');
meanProgressionSpeed = mean([meanProgressionSpeedCAM1 meanProgressionSpeedCAM2], 'omitnan');
instProgressionSpeeds = mean([instProgressionSpeedsCAM1 instProgressionSpeedsCAM2],2, 'omitnan');

% to plot left and right in the same coordinates, need to flip CAM2
flipCam2centroids = centroidsCAM2;
maxX = max(centroidsCAM2(:, 1));
flipCam2centroids(:, 1) = maxX - flipCam2centroids(:, 1) ;

%as the camera angles are not exactly the same, shift both coords so they
%are centered
meanXcam1 = mean(centroidsCAM1(:, 1), 'omitnan');
meanXcam2 = mean(flipCam2centroids(:, 1), 'omitnan');
centroidsCAM1(:,1) = centroidsCAM1(:,1) -meanXcam1;
flipCam2centroids(:,1) = flipCam2centroids(:,1) -meanXcam2;

%calculate mean centroid position from 2 cams in each frame:
combinedCentroids = cat(3, centroidsCAM1, flipCam2centroids);
centroids = mean(combinedCentroids, 3, 'omitnan');


%% select unique slip events (seen in both cams)
slipLocs = unique([slipLocsCAM1; slipLocsCAM2]);
minInterval = str2num(frameRate) / 10; % min frame count between slip events to be seen as separate events
% Sort the combined array in ascending order and
% find the differences between consecutive elements
slipDiffs = diff(sort(slipLocs));
% Find the indices of elements to retain (those that are not too close to each other)
retainIndices = [true; slipDiffs >= minInterval];
% Create a new array that retains only the desired elements
slipLocs = slipLocs(retainIndices);

% combined quality control value for whole trial
QCflags = mean([sum(QCflagsCAM1);sum(QCflagsCAM2) ]);

if MAKEPLOTS
% Display the combined results from 2 cameras
    f = plotBBTrial(centroids,[0; instProgressionSpeeds], slipLocs, frameRate, PIXELSIZE, fileID, [EXPID '-' SAMPLEID '-' TIMEPOINT ' BBtrial'], 'Speed');

end