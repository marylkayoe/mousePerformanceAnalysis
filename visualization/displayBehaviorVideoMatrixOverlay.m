function displayBehaviorVideoMatrixOverlay(videoMatrix, titleString, dispData, logicalData, NORMHISTO)
    % DISPLAYBEHAVIORVIDEOMATRIXOVERLAY  Display videoMatrix with a dispData-driven overlay.

    if ~exist('dispData', 'var') || isempty(dispData)
        dispData = (1 : getNumFrames(videoMatrix))';
    end
    if ~exist('logicalData', 'var') || isempty(logicalData)
        logicalData = false(getNumFrames(videoMatrix), 1);
    end
    if ~exist('NORMHISTO', 'var')
        NORMHISTO = 0;
    end
    if ~exist('titleString', 'var') || isempty(titleString)
        titleString = 'Behavior Video';
    end

    nFrames = getNumFrames(videoMatrix);
    fps = 30;

    dispData = dispData(:);
    if numel(dispData) ~= nFrames
        error('dispData must have one value per frame.');
    end
    if numel(logicalData) ~= nFrames
        error('logicalData must have one value per frame.');
    end

    finiteVals = dispData(isfinite(dispData));
    if isempty(finiteVals)
        vMin = 0;
        vMax = 1;
    else
        try
            vMin = prctile(finiteVals, 5);
            vMax = prctile(finiteVals, 95);
        catch
            vMin = min(finiteVals);
            vMax = max(finiteVals);
        end
        if vMax <= vMin
            vMin = min(finiteVals);
            vMax = max(finiteVals);
        end
        if vMax <= vMin
            vMin = 0;
            vMax = 1;
        end
    end

    firstFrame = getFrame(videoMatrix, 1);
    frameH = size(firstFrame, 1);
    frameW = size(firstFrame, 2);
    baseSize = min(frameH, frameW);
    rMin = max(5, round(baseSize * 0.02));
    rMax = max(rMin + 1, round(baseSize * 0.06));
    circleCx = round(frameW / 2);
    circleCy = frameH - rMax - 5;
    circleCx = max(rMax + 1, min(frameW - rMax - 1, circleCx));
    circleCy = max(rMax + 1, min(frameH - rMax - 1, circleCy));

    fig = figure('Name', titleString, 'NumberTitle', 'off');
    ax = axes('Parent', fig, 'Position', [0.05 0.2 0.9 0.7]);

    if nFrames > 1
        sliderStep = [1/(nFrames-1), 1/(nFrames-1)];
    else
        sliderStep = [1, 1];
    end

    sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.1 0.55 0.05], 'Min', 1, 'Max', nFrames, ...
        'Value', 1, ...
        'SliderStep', sliderStep, ...
        'Callback', @slider_callback);

    playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.62 0.1 0.15 0.05], 'String', 'Play', 'Callback', @play_callback);

    uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.79 0.1 0.16 0.05], 'String', 'Export MP4', 'Callback', @export_callback);

    frameNumText = uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.9 0.5 0.05], ...
        'String', sprintf('Frame: 1, Value: %f', dispData(1)));

    if isGrayscale(videoMatrix)
        if NORMHISTO
            imshow(firstFrame, [], 'Parent', ax);
        else
            imshow(firstFrame, 'Parent', ax);
        end
    else
        imshow(firstFrame, 'Parent', ax);
    end
    title(ax, titleString);
    drawOverlay(1);

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

    function export_callback(~, ~)
        defaultName = regexprep(titleString, '\W+', '_');
        if isempty(defaultName)
            defaultName = 'behavior_video';
        end

        [fileName, filePath] = uiputfile({'*.mp4','MP4 Video (*.mp4)'}, 'Export MP4', [defaultName '.mp4']);
        if isequal(fileName, 0)
            return;
        end

        outPath = fullfile(filePath, fileName);
        try
            vw = VideoWriter(outPath, 'MPEG-4');
        catch
            [p, n] = fileparts(outPath);
            outPath = fullfile(p, [n '.avi']);
            vw = VideoWriter(outPath, 'Motion JPEG AVI');
        end
        vw.FrameRate = fps;
        open(vw);

        oldFrame = round(sld.Value);
        oldPlay = playBtn.String;
        playBtn.String = 'Play';

        for k = 1:nFrames
            showFrame(k);
            drawnow;
            fr = getframe(ax);
            img = fr.cdata;
            img = img(1:2*floor(size(img,1)/2), 1:2*floor(size(img,2)/2), :);
            writeVideo(vw, img);
        end
        close(vw);

        showFrame(oldFrame);
        playBtn.String = oldPlay;
    end

    function showFrame(frameNum)
        frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));

        frm = getFrame(videoMatrix, frameNum);
        if isGrayscale(videoMatrix)
            if NORMHISTO
                imshow(frm, [], 'Parent', ax);
            else
                imshow(frm, 'Parent', ax);
            end
        else
            imshow(frm, 'Parent', ax);
        end

        drawOverlay(frameNum);
    end

    function drawOverlay(frameNum)
        delete(findobj(ax, 'Tag', 'dispDataCircle'));
        delete(findobj(ax, 'Tag', 'logicalRect'));

        val = dispData(frameNum);
        if isfinite(val)
            t = (val - vMin) / (vMax - vMin);
            t = max(0, min(1, t));
        else
            t = 0;
        end

        r = rMin + t * (rMax - rMin);
        edgeColor = 'r';
        rectangle('Position', [circleCx-r, circleCy-r, 2*r, 2*r], 'Curvature', [1 1], ...
            'EdgeColor', edgeColor, 'LineWidth', 2, 'Parent', ax, 'Tag', 'dispDataCircle');

        if logicalData(frameNum)
            rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r', 'Parent', ax, 'Tag', 'logicalRect');
        end
    end
end

function tf = isGrayscale(videoMat)
    tf = (ndims(videoMat) == 3);
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
