function displayTailMotionWeightDebug(videoMatrix, noMouseProbVals, tailMovementTrace, titleString)
    % DISPLAYTAILMOTIONWEIGHTDEBUG  Debug view for tail motion weighting.

    if ~exist('titleString', 'var') || isempty(titleString)
        titleString = 'Tail motion weight debug';
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

    fig = figure('Name', titleString, 'NumberTitle', 'off');
    axVid = axes('Parent', fig, 'Position', [0.05 0.32 0.9 0.62]);
    axWgt = axes('Parent', fig, 'Position', [0.05 0.12 0.9 0.16]);

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
        'Position', [0.7 0.03 0.2 0.05], 'String', 'Play', 'Callback', @play_callback);

    showFrame(1);

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

    function showFrame(frameNum)
        frm = getFrame(videoMatrix, frameNum);
        imshow(frm, 'Parent', axVid);
        alignWeightAxesToImage();

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
        hold(axWgt, 'on');
        if any(contrib)
            contrib = contrib / max(contrib + eps);
            plot(axWgt, contrib, 'g', 'LineWidth', 1);
        end
        hold(axWgt, 'off');
        xlim(axWgt, [0.5 width+0.5]);
        ylim(axWgt, [0 1]);
        axWgt.Box = 'on';
        axWgt.YTick = [0 1];
        xlabel(axWgt, 'Column');
        ylabel(axWgt, 'Weight');
    end

    function alignWeightAxesToImage()
        axVid.Units = 'pixels';
        axWgt.Units = 'pixels';
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
