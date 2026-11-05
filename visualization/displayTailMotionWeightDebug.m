function displayTailMotionWeightDebug(videoMatrix, noMouseProbVals, tailMovementTrace, titleString, outFile, barPosition, barWidth)
    % DISPLAYTAILMOTIONWEIGHTDEBUG  Debug view for tail motion weighting.
    % Green and red show per-column motion above and below the bar, using
    % the same spatial weights as the separate tail-motion calculations.
    % Magenta shows per-row motion with a bar-relative weight gradient;
    % it includes all columns in the cropped video, without mouse weighting.
    % These profiles are before temporal smoothing and normalization.
    % barPosition and barWidth use rows in the uncropped video.

    if ~exist('titleString', 'var') || isempty(titleString)
        titleString = 'Tail motion weight debug';
    end
    if ~exist('outFile', 'var')
        outFile = '';
    end
    if ~exist('tailMovementTrace', 'var') || isempty(tailMovementTrace)
        tailMovementTrace = (1 : getNumFrames(videoMatrix))';
    end

    nFrames = getNumFrames(videoMatrix);
    [height, width, ~] = size(videoMatrix);
    if ~exist('barPosition', 'var') || isempty(barPosition)
        barPosition = round(height / 2);
    end
    if ~exist('barWidth', 'var') || isempty(barWidth)
        barWidth = 1;
    end

    if size(noMouseProbVals, 1) == nFrames && size(noMouseProbVals, 2) == width
        noMouseProbVals = noMouseProbVals.';
    end
    if size(noMouseProbVals, 1) ~= width || size(noMouseProbVals, 2) ~= nFrames
        error('noMouseProbVals must be width x nFrames (or nFrames x width).');
    end
    tailMovementTrace = tailMovementTrace(:);
    if numel(tailMovementTrace) ~= nFrames
        error('tailMovementTrace must have one value per frame.');
    end

    fps = 30;

    videoDouble = im2double(videoMatrix);
    videoDiff = abs(diff(videoDouble, 1, 3));

    % Weight rises from 0 at the top to 1 at the bar and 2 at the bottom.
    % All rows below the bar therefore carry more weight than rows above it.
    rowGradient = ones(height, 1);
    rowGradient(1:barPosition) = linspace(0, 1, barPosition)';
    belowStart = barPosition + barWidth;
    nBelow = height - belowStart + 1;
    rowGradient(belowStart:end) = 1 + (1:nBelow)' / nBelow;
    rowMotion = reshape(sum(videoDiff, 2), height, nFrames-1) .* rowGradient;
    rowMotionMax = max(rowMotion(:), [], 'omitnan');
    if isempty(rowMotionMax) || ~isfinite(rowMotionMax) || rowMotionMax <= 0
        rowMotionMax = 1;
    end

    % Apply the same vertical weighting separately to the two regions as
    % getTailMotionTrace, then sum each column for display.
    aboveRows = 1:barPosition;
    belowRows = barPosition+barWidth:height;
    aboveWeights = ((0:numel(aboveRows)-1)' / (numel(aboveRows)-1) + eps).^3;
    belowWeights = (min(2 * (0:numel(belowRows)-1)' / (numel(belowRows)-1), 1) + eps).^3;
    aboveWeights = aboveWeights / max(aboveWeights);
    belowWeights = belowWeights / max(belowWeights);
    aboveDiff = reshape(videoDiff(aboveRows, :, :), numel(aboveRows), []);
    belowDiff = reshape(videoDiff(belowRows, :, :), numel(belowRows), []);
    aboveContrib = reshape(aboveWeights' * aboveDiff, width, nFrames-1);
    belowContrib = reshape(belowWeights' * belowDiff, width, nFrames-1);
    weights = noMouseProbVals(:, 2:end).^2;
    aboveContrib = aboveContrib .* weights;
    belowContrib = belowContrib .* weights;
    contribYMax = max([aboveContrib(:); belowContrib(:)], [], 'omitnan');
    clear videoDouble videoDiff aboveDiff belowDiff;
    if isempty(contribYMax) || ~isfinite(contribYMax) || contribYMax <= 0
        contribYMax = 1;
    end

    fig = figure('Name', titleString, 'NumberTitle', 'off');
    axVid = axes('Parent', fig, 'Position', [0.05 0.12 0.9 0.80]);

    if nFrames > 1
        sliderStep = [1/(nFrames-1), 1/(nFrames-1)];
    else
        sliderStep = [1, 1];
    end

    sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.03 0.6 0.05], 'Min', 1, 'Max', nFrames, ...
        'Value', 1, ...
        'SliderStep', sliderStep, ...
        'Callback', @slider_callback);

    playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.7 0.03 0.12 0.05], 'String', 'Play', 'Callback', @play_callback);

    saveBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.83 0.03 0.12 0.05], 'String', 'Save MP4', 'Callback', @save_callback);

    showFrame(1);

    if ~isempty(outFile)
        saveMovie(outFile);
    end

    function slider_callback(hObject, ~)
        frameNum = round(get(hObject, 'Value'));
        showFrame(frameNum);
    end

    function play_callback(~, ~)
        if strcmp(playBtn.String, 'Play')
            playBtn.String = 'Pause';
            while sld.Value < nFrames
                frameNum = round(sld.Value);
                showFrame(frameNum);
                pause(1/fps);
                if strcmp(playBtn.String, 'Play')
                    break;
                end
                sld.Value = sld.Value + 1;
            end
        else
            playBtn.String = 'Play';
        end
    end

    function save_callback(~, ~)
        if isempty(outFile)
            [fn, pn] = uiputfile('*.mp4', 'Save debug video as');
            if isequal(fn, 0)
                return;
            end
            outFile = fullfile(pn, fn);
        end
        saveMovie(outFile);
    end

    function showFrame(frameNum)
        frm = getFrame(videoMatrix, frameNum);
        imshow(frm, 'Parent', axVid);

        tval = tailMovementTrace(frameNum);
        title(axVid, {sprintf('%s | Frame %d | tail=%g', titleString, frameNum, tval), ...
            'Green: above-bar | Red: below-bar | Magenta: row motion (bar-weighted)', ...
            'Profiles shown before temporal smoothing and normalization'});

        if frameNum == 1
            above = zeros(width, 1);
            below = zeros(width, 1);
            rows = zeros(height, 1);
        else
            above = aboveContrib(:, frameNum-1);
            below = belowContrib(:, frameNum-1);
            rows = rowMotion(:, frameNum-1);
        end

        % Plot both profiles away from the bar using the same fixed scale.
        above(noMouseProbVals(:, frameNum) <= 0) = nan;
        below(noMouseProbVals(:, frameNum) <= 0) = nan;
        overlaySpan = height / 4;
        overlayBaseline = barPosition + (barWidth - 1) / 2;
        aboveY = overlayBaseline - (above / contribYMax) * overlaySpan;
        belowY = overlayBaseline + (below / contribYMax) * overlaySpan;
        hold(axVid, 'on');
        plot(axVid, 1:width, aboveY, 'g', 'LineWidth', 2.5);
        plot(axVid, 1:width, belowY, 'r', 'LineWidth', 2.5);
        % Horizontal deflection shows weighted motion in each image row.
        rowX = width - (rows / rowMotionMax) * width / 2;
        plot(axVid, rowX, 1:height, 'm', 'LineWidth', 2.5);
        hold(axVid, 'off');
    end

    function saveMovie(movieFile)
        try
            vid = VideoWriter(movieFile, 'MPEG-4');
        catch
            vid = VideoWriter(movieFile);
        end
        vid.FrameRate = fps;
        open(vid);

        oldVal = sld.Value;
        oldStr = playBtn.String;
        playBtn.String = 'Play';

        for k = 1:nFrames
            sld.Value = k;
            showFrame(k);
            drawnow;

            % Capture the video axes and overlays without the figure controls.
            fr = getframe(axVid);
            img = imresize(fr.cdata, [height, width]);

            h = size(img, 1);
            w = size(img, 2);
            h2 = 2 * floor(h / 2);
            w2 = 2 * floor(w / 2);
            img = img(1:h2, 1:w2, :);

            writeVideo(vid, img);
        end

        playBtn.String = oldStr;
        sld.Value = oldVal;
        showFrame(round(oldVal));

        close(vid);
    end
end

function nf = getNumFrames(videoMat)
    if ndims(videoMat) == 3
        nf = size(videoMat, 3);
    else
        nf = size(videoMat, 4);
    end
end

function f = getFrame(videoMat, idx)
    if ndims(videoMat) == 3
        f = videoMat(:,:,idx);
    else
        f = videoMat(:,:,:,idx);
    end
end
