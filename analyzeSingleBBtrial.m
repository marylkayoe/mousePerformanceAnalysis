function [nSLIPS, slipIndex, slipLocs,nQCflags, meanProgressionSpeed, centroids, instProgressionSpeeds]  = analyzeSingleBBtrial(dataFolder,EXPID, SAMPLEID, TIMEPOINT, SLIPTH, PIXELSIZE, MAKEPLOTS, DOWNSAMPLERATIO)

if ~exist('PIXELSIZE', 'var')
    PIXELSIZE = 1;
end


if ~exist('SLIPTH', 'var')
    SLIPTH = 2;
end

if ~exist('MAKEPLOTS', 'var')
    MAKEPLOTS = 0;
end


if ~exist('DOWNSAMPLERATIO', 'var')
    DOWNSAMPLERATIO = 4;
end


TASKID = 'BB';

[nSLIPSCAM1, slipIndexCAM1, slipLocsCAM1, slipZscoresCAM1,QCflagsCAM1, meanProgressionSpeedCAM1, centroidsCAM1, instProgressionSpeedsCAM1]  = analyzeSingleCamBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, 'Cam1', SLIPTH, 1, DOWNSAMPLERATIO);
[nSLIPSCAM2, slipIndexCAM2, slipLocsCAM2, slipZscoresCAM2,QCflagsCAM2, meanProgressionSpeedCAM2, centroidsCAM2, instProgressionSpeedsCAM2]  = analyzeSingleCamBB(dataFolder,EXPID, SAMPLEID, TASKID, TIMEPOINT, 'Cam2', SLIPTH, 1, DOWNSAMPLERATIO);

    fileName = getFilenamesForSamples(dataFolder, EXPID, SAMPLEID, TASKID, TIMEPOINT, '', 'Cam1');
    frameRate = getFrameRateForVideo(dataFolder, fileName);
    fileID = getFileIDfromFilename (fileName);


%% COMBINE cam results
nSLIPS = mean([nSLIPSCAM1 nSLIPSCAM2], 'omitnan');
slipIndex = mean([slipIndexCAM1 slipIndexCAM2], 'omitnan');
meanProgressionSpeed = mean([meanProgressionSpeedCAM1 meanProgressionSpeedCAM2], 'omitnan');
centroids = mean([centroidsCAM1 centroidsCAM2], 'omitnan');
instProgressionSpeeds = mean([instProgressionSpeedsCAM1 instProgressionSpeedsCAM2],2, 'omitnan');

    %% select unique slip events (seen in both cams)
    slipLocs = unique([slipLocsCAM1; slipLocsCAM2]);
    minInterval = str2num(frameRate) / 10; % min frame count between slip events to be seen as separate events
    % Sort the combined array in ascending order and
    % Find the differences between consecutive elements
    slipDiffs = diff(sort(slipLocs));
    % Find the indices of elements to retain (those that are not too close to each other)
    retainIndices = [true; slipDiffs >= minInterval];
    % Create a new array that retains only the desired elements
    slipLocs = slipLocs(retainIndices);

nQCflags = mean([sum(QCflagsCAM1);sum(QCflagsCAM2) ]);

if MAKEPLOTS
    %% PLOTTING: find file ingo



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
    meanCentroids = mean(combinedCentroids, 3, 'omitnan');

    f = plotBBTrial(meanCentroids,[0; instProgressionSpeeds], slipLocs, frameRate, PIXELSIZE, fileID, [EXPID '-' SAMPLEID '-' TIMEPOINT ' BBtrial'], 'Speed');

end