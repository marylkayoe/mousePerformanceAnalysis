function displayBehaviorVideoMatrixProbOverlay(videoMatrix, titleString, dispData, probVals, NORMHISTO)
    % DISPLAYBEHAVIORVIDEOMATRIXPROBOVERLAY  Display videoMatrix with per-column prob overlay.

    if ~exist('dispData', 'var') || isempty(dispData)
        dispData = (1 : getNumFrames(videoMatrix))';
    end
    if ~exist('probVals', 'var') || isempty(probVals)
        error('probVals is required.');
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

    width = size(getFrame(videoMatrix, 1), 2);
    if size(probVals, 1) == nFrames && size(probVals, 2) == width
        probVals = probVals.';
    end
    if size(probVals, 1) ~= width || size(probVals, 2) ~= nFrames
        error('probVals must be width x nFrames (or nFrames x width).');
    end

    fig = figure('Name', titleString, 'NumberTitle', 'off');
    ax = axes('Parent', fig, 'Position', [0.05 0.2 0.9 0.7]);

    if nFrames > 1
        sliderStep = [1/(nFrames-1), 1/(nFrames-1)];
    else
        sliderStep = [1, 1];
    end

    sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.1 0.6 0.05], 'Min', 1, 'Max', nFrames, ...
        'Value', 1, ...
        'SliderStep', sliderStep, ...
        'Callback', @slider_callback);

    playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.7 0.1 0.2 0.05], 'String', 'Play', 'Callback', @play_callback);

    frameNumText = uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.9 0.5 0.05], ...
        'String', sprintf('Frame: 1, Value: %f', dispData(1)));

    showFrame(1);
    title(ax, titleString);

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
        frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));

        frm = getFrame(videoMatrix, frameNum);
    maskThreshold = 0.5;
    rgb = makeOverlayFrame(frm, probVals(:, frameNum), maskThreshold, NORMHISTO);
    imshow(rgb, 'Parent', ax);
    end
end

function rgb = makeOverlayFrame(frm, probCol, maskThreshold, NORMHISTO)
    if ndims(frm) == 2
        if isa(frm, 'uint8')
            base = im2double(frm);
        else
            base = double(frm);
            if NORMHISTO
                mn = min(base(:));
                mx = max(base(:));
                if mx > mn
                    base = (base - mn) / (mx - mn);
                end
            else
                base = base / max(base(:) + eps);
            end
        end
        baseRGB = repmat(base, 1, 1, 3);
    else
        baseRGB = im2double(frm);
    end

    probCol = probCol(:)';
    probImg = repmat(probCol, size(baseRGB, 1), 1);
    probImg = max(0, min(1, probImg));

    keep = probImg >= maskThreshold;
    rgb = baseRGB .* keep;
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
