function displayBehaviorVideoMatrixColumnSelection(videoMatrix, titleString, cols, frameIdxMap, NORMHISTO)
    % DISPLAYBEHAVIORVIDEOMATRIXCOLUMNSELECTION  Display selected columns per frame.

    if ~exist('cols', 'var') || isempty(cols)
        error('cols is required.');
    end
    if ~exist('frameIdxMap', 'var') || isempty(frameIdxMap)
        frameIdxMap = (1:size(cols, 1))';
    end
    if ~exist('NORMHISTO', 'var')
        NORMHISTO = 0;
    end
    if ~exist('titleString', 'var') || isempty(titleString)
        titleString = 'Column selection';
    end

    nFramesSel = size(cols, 1);
    fps = 30;

    if numel(frameIdxMap) ~= nFramesSel
        error('frameIdxMap must have one value per row of cols.');
    end

    firstFrame = getFrame(videoMatrix, frameIdxMap(1));
    frameH = size(firstFrame, 1);
    frameW = size(firstFrame, 2);
    if size(cols, 2) < 1
        error('cols must have at least one column index per frame.');
    end

    fig = figure('Name', titleString, 'NumberTitle', 'off');
    ax = axes('Parent', fig, 'Position', [0.05 0.2 0.9 0.7]);

    if nFramesSel > 1
        sliderStep = [1/(nFramesSel-1), 1/(nFramesSel-1)];
    else
        sliderStep = [1, 1];
    end

    sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.1 0.6 0.05], 'Min', 1, 'Max', nFramesSel, ...
        'Value', 1, ...
        'SliderStep', sliderStep, ...
        'Callback', @slider_callback);

    playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.7 0.1 0.2 0.05], 'String', 'Play', 'Callback', @play_callback);

    frameNumText = uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
        'Position', [0.05 0.9 0.8 0.05], ...
        'String', '');

    showFrame(1);
    title(ax, titleString);

    function slider_callback(hObject, ~)
        frameNum = round(get(hObject, 'Value'));
        showFrame(frameNum);
    end

    function play_callback(~, ~)
        if strcmp(playBtn.String, 'Play')
            playBtn.String = 'Pause';
            while sld.Value < nFramesSel
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
        srcFrameIdx = frameIdxMap(frameNum);
        srcFrameIdx = max(1, min(getNumFrames(videoMatrix), round(srcFrameIdx)));

        frameCols = cols(frameNum, :);
        frameCols = frameCols(isfinite(frameCols));
        frameCols = round(frameCols);
        frameCols = frameCols(frameCols >= 1 & frameCols <= frameW);

        if isempty(frameCols)
            frameNumText.String = sprintf('Frame: %d (src %d), cols: (none)', frameNum, srcFrameIdx);
        else
            frameNumText.String = sprintf('Frame: %d (src %d), cols: [%d..%d], n=%d', ...
                frameNum, srcFrameIdx, min(frameCols), max(frameCols), numel(frameCols));
        end

        frm = getFrame(videoMatrix, srcFrameIdx);
        rgb = makeMaskedFrame(frm, frameCols, frameH, frameW, NORMHISTO);
        imshow(rgb, 'Parent', ax);
    end
end

function rgb = makeMaskedFrame(frm, frameCols, frameH, frameW, NORMHISTO)
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

    keep = false(1, frameW);
    keep(frameCols) = true;
    keepImg = repmat(keep, frameH, 1);

    outsideDim = 0.05;
    rgb = baseRGB .* outsideDim;
    rgb(:,:,1) = rgb(:,:,1) + baseRGB(:,:,1) .* keepImg * (1 - outsideDim);
    rgb(:,:,2) = rgb(:,:,2) + baseRGB(:,:,2) .* keepImg * (1 - outsideDim);
    rgb(:,:,3) = rgb(:,:,3) + baseRGB(:,:,3) .* keepImg * (1 - outsideDim);
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

