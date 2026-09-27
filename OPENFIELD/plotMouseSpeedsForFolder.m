function speedResults = plotMouseSpeedsForFolder(dataFolder, speedWindow, minCentroidSpeed, maxStationaryFrames)
% plotMouseSpeedsForFolder Run the OF tracking pipeline for every mp4 in a folder.
% speedResults = plotMouseSpeedsForFolder(dataFolder, speedWindow, minCentroidSpeed, maxStationaryFrames)
% imports each video with readVideoIntoMatrix, tracks the mouse with
% trackMouseInOF, computes speed with getMouseSpeedFromTraj, cleans the
% speed trace with cleanOFtracking, and overlays all resulting traces on a
% single axes.

    if ~exist('dataFolder', 'var') || isempty(dataFolder)
        dataFolder = '/Users/yoe/Documents/DATA/BEHAVIOR/HY';
    end

    if iscell(dataFolder)
        dataFolder = dataFolder{1};
    end
    dataFolder = char(dataFolder);
    dataFolder = strtrim(dataFolder);

    while numel(dataFolder) > 1 && any(dataFolder(end) == ['/' '\'])
        dataFolder(end) = [];
    end

    if ~isfolder(dataFolder)
        error('Data folder does not exist: %s', dataFolder);
    end

    videoFiles = dir(fullfile(dataFolder, '*.mp4'));
    if isempty(videoFiles)
        videoFiles = dir(fullfile(dataFolder, '*.MP4'));
    end
    if isempty(videoFiles)
        error('No mp4 files found in folder: %s', dataFolder);
    end

    if ~exist('minCentroidSpeed', 'var')
        minCentroidSpeed = [];
    end

    if ~exist('maxStationaryFrames', 'var')
        maxStationaryFrames = [];
    end

    speedResults = struct( ...
        'fileName', cell(numel(videoFiles), 1), ...
        'filePath', cell(numel(videoFiles), 1), ...
        'frameRate', cell(numel(videoFiles), 1), ...
        'centroids', cell(numel(videoFiles), 1), ...
        'cleanCentroids', cell(numel(videoFiles), 1), ...
        'rawSpeeds', cell(numel(videoFiles), 1), ...
        'cleanSpeeds', cell(numel(videoFiles), 1), ...
        'cleanMouseMaskMatrix', cell(numel(videoFiles), 1));

    speedFigure = figure('Name', 'Open Field Mouse Speeds', 'Color', 'w');
    speedAx = axes(speedFigure);
    hold(speedAx, 'on');

    centroidFigure = figure('Name', 'Open Field Centroid Trajectories', 'Color', 'w');
    centroidAx = axes(centroidFigure);
    hold(centroidAx, 'on');
    colors = lines(numel(videoFiles));

    nPlotted = 0;
    for fileIdx = 1:numel(videoFiles)
        fileName = videoFiles(fileIdx).name;
        filePath = fullfile(videoFiles(fileIdx).folder, fileName);
        fprintf('Processing %d/%d: %s\n', fileIdx, numel(videoFiles), fileName);

        try
            [videoMatrix, frameRate] = readVideoIntoMatrix(filePath);
            if isempty(videoMatrix)
                warning('Skipping %s because the video could not be loaded.', fileName);
                continue;
            end

            [centroids, mouseMaskMatrix] = trackMouseInOF(videoMatrix);
            if isempty(centroids)
                warning('Skipping %s because no mouse trajectory was detected.', fileName);
                continue;
            end

            if ~exist('speedWindow', 'var') || isempty(speedWindow)
                currentSpeedWindow = frameRate;
            else
                currentSpeedWindow = speedWindow;
            end

            rawSpeeds = getMouseSpeedFromTraj(centroids, frameRate, currentSpeedWindow);
            [cleanSpeeds, cleanCentroids, cleanMouseMaskMatrix] = cleanOFtracking(rawSpeeds, centroids, mouseMaskMatrix, frameRate, minCentroidSpeed, maxStationaryFrames);

            if isempty(cleanSpeeds) || isempty(cleanCentroids)
                warning('Skipping %s because cleaning removed all tracking samples.', fileName);
                continue;
            end

            timeAxis = (0:numel(cleanSpeeds) - 1) ./ frameRate;
            plot(speedAx, timeAxis, cleanSpeeds, 'Color', colors(fileIdx, :), 'LineWidth', 1.5, 'DisplayName', fileName);
            plot(centroidAx, cleanCentroids(:, 1), cleanCentroids(:, 2), 'Color', colors(fileIdx, :), 'LineWidth', 1.5, 'DisplayName', fileName);
            nPlotted = nPlotted + 1;

            speedResults(fileIdx).fileName = fileName;
            speedResults(fileIdx).filePath = filePath;
            speedResults(fileIdx).frameRate = frameRate;
            speedResults(fileIdx).centroids = centroids;
            speedResults(fileIdx).cleanCentroids = cleanCentroids;
            speedResults(fileIdx).rawSpeeds = rawSpeeds;
            speedResults(fileIdx).cleanSpeeds = cleanSpeeds;
            speedResults(fileIdx).cleanMouseMaskMatrix = cleanMouseMaskMatrix;
        catch ME
            warning('Failed to process %s: %s', fileName, ME.message);
        end
    end

    if nPlotted == 0
        close(speedFigure);
        close(centroidFigure);
        error('No speed traces were successfully plotted for folder: %s', dataFolder);
    end

    xlabel(speedAx, 'Time (s)');
    ylabel(speedAx, 'Speed (pixels/s)');
    title(speedAx, sprintf('Open Field Speeds: %s', dataFolder), 'Interpreter', 'none');
    legend(speedAx, 'show', 'Interpreter', 'none', 'Location', 'eastoutside');
    grid(speedAx, 'on');
    box(speedAx, 'off');

    xlabel(centroidAx, 'X position (pixels)');
    ylabel(centroidAx, 'Y position (pixels)');
    title(centroidAx, sprintf('Open Field Centroid Trajectories: %s', dataFolder), 'Interpreter', 'none');
    legend(centroidAx, 'show', 'Interpreter', 'none', 'Location', 'eastoutside');
    grid(centroidAx, 'on');
    box(centroidAx, 'off');
    axis(centroidAx, 'equal');

    

    speedResults = speedResults(~cellfun(@isempty, {speedResults.fileName}));
end