function displayTailMotionWeightDebug(videoMatrix, noMouseProbVals, tailMovementTrace, titleString, outFile)
    % DISPLAYTAILMOTIONWEIGHTDEBUG  Debug view for tail motion weighting.

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
    width = size(getFrame(videoMatrix, 1), 2);

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
    colDiffSum = squeeze(sum(videoDiff, 1));
    allContrib = colDiffSum .* (noMouseProbVals(:, 2:end) .^ 2);
    contribYMax = max(allContrib(:), [], 'omitnan');
    if isempty(contribYMax) || ~isfinite(contribYMax) || contribYMax <= 0
        contribYMax = 1;
    end

    fig = figure('Name', titleString, 'NumberTitle', 'off');
    axVid = axes('Parent', fig, 'Position', [0.05 0.45 0.9 0.49]);
    axWgt = axes('Parent', fig, 'Position', [0.05 0.29 0.9 0.11]);
    axMotion = axes('Parent', fig, 'Position', [0.05 0.13 0.9 0.11]);

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
        alignDebugAxesToImage();

        tval = tailMovementTrace(frameNum);
        title(axVid, sprintf('%s | Frame %d | tail=%g', titleString, frameNum, tval));

        prob = noMouseProbVals(:, frameNum);
        w = prob .^ 2;

        if frameNum == 1
            contrib = zeros(size(w));
        else
            contrib = colDiffSum(:, frameNum-1) .* w;
        end

        cla(axWgt);
        plot(axWgt, w, 'k', 'LineWidth', 1);
        xlim(axWgt, [0.5 width+0.5]);
        ylim(axWgt, [0 1]);
        axWgt.YTick = [0 1];
        axWgt.XTickLabel = [];
        axWgt.Box = 'on';
        ylabel(axWgt, 'Weight');

        cla(axMotion);
        plot(axMotion, contrib, 'Color', [0.75 0.75 0.75], 'LineWidth', 1);
        hold(axMotion, 'on');
        includedContrib = contrib;
        includedContrib(w <= 0) = nan;
        plot(axMotion, includedContrib, 'g', 'LineWidth', 1.5, ...
            'Marker', '.', 'MarkerSize', 10);
        hold(axMotion, 'off');
        xlim(axMotion, [0.5 width+0.5]);
        ylim(axMotion, [0 contribYMax]);
        axMotion.Box = 'on';
        xlabel(axMotion, 'Column');
        ylabel(axMotion, 'Weighted pixel difference');
        title(axMotion, 'Green = included by weight cutoff');

        % Overlay the included motion trace in a fixed-height band centered
        % vertically on the video. The global maximum spans 1/4 image height.
        imageHeight = size(frm, 1);
        overlaySpan = imageHeight / 4;
        overlayBaseline = imageHeight / 2 + overlaySpan / 2;
        overlayY = overlayBaseline - (includedContrib / contribYMax) * overlaySpan;
        hold(axVid, 'on');
        plot(axVid, 1:width, overlayY, 'g', 'LineWidth', 1.5, ...
            'Marker', '.', 'MarkerSize', 10);
        hold(axVid, 'off');
    end

    function alignDebugAxesToImage()
        axVid.Units = 'pixels';
        axWgt.Units = 'pixels';
        axMotion.Units = 'pixels';
        pos = axVid.Position;

        xl = axVid.XLim;
        yl = axVid.YLim;
        dataAspect = abs(diff(xl) / diff(yl));

        boxW = pos(3);
        boxH = pos(4);
        if boxW / boxH > dataAspect
            plotH = boxH;
            plotW = plotH * dataAspect;
        else
            plotW = boxW;
            plotH = plotW / dataAspect;
        end

        plotX = pos(1) + (boxW - plotW) / 2;
        wpos = axWgt.Position;
        axWgt.Position = [plotX, wpos(2), plotW, wpos(4)];
        mpos = axMotion.Position;
        axMotion.Position = [plotX, mpos(2), plotW, mpos(4)];
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

            fr = getframe(fig);
            img = fr.cdata;

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
