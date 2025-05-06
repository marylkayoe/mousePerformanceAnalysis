function displayBehaviorVideoMatrix(videoMatrix, titleString, dispData, logicalData, NORMHISTO)
    % DISPLAYBEHAVIORVIDEOMATRIX  Displays a grayscale or RGB video with a slider and play button.
    %   - If videoMatrix is 3D (H x W x nFrames), we treat it as grayscale.
    %   - If videoMatrix is 4D (H x W x 3 x nFrames), we treat it as RGB.
    %   - dispData is an optional array of data to display, one value per frame.
    %   - logicalData is an optional logical array (nFrames x 1) to decide when
    %     to draw a small rectangle on the displayed frame.
    %   - NORMHISTO is an optional flag to decide if we show grayscale frames
    %     with `imshow(...,[])` normalization.
    
    %
    
        % ---------- Parse Input Arguments and Defaults ----------
        if ~exist('dispData', 'var') || isempty(dispData)
            dispData = (1 : getNumFrames(videoMatrix))';  % default numeric array
        end
        if ~exist('logicalData', 'var') || isempty(logicalData)
            logicalData = false(getNumFrames(videoMatrix), 1);
        end
        if ~exist('NORMHISTO', 'var')
            NORMHISTO = 0;
        end
        if ~exist('titleString', 'var')
            titleString = 'Behavior Video';
        end
    
        nFrames = getNumFrames(videoMatrix);  % total frames in the video
    
        % ---------- Create UI Figure ----------
        fig = figure('Name', titleString, 'NumberTitle', 'off');
        ax = axes('Parent', fig, 'Position', [0.05 0.2 0.9 0.7]);
        
        sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
            'Position', [0.05 0.1 0.6 0.05], 'Min', 1, 'Max', nFrames, ...
            'Value', 1, ...
            'SliderStep', [1/(nFrames-1), 1/(nFrames-1)], ...
            'Callback', @slider_callback);
        
        playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
            'Position', [0.7 0.1 0.2 0.05], 'String', 'Play', 'Callback', @play_callback);
        
        frameNumText = uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
            'Position', [0.05 0.9 0.3 0.05], ...
            'String', sprintf('Frame: 1, Value: %f', dispData(1)));
    
        % ---------- Display First Frame ----------
        firstFrame = getFrame(videoMatrix, 1);
        if isGrayscale(videoMatrix)
            if NORMHISTO
                imshow(firstFrame, [], 'Parent', ax);
            else
                imshow(firstFrame, 'Parent', ax);
            end
        else
            % Color
            imshow(firstFrame, 'Parent', ax);
        end
        title(ax, titleString);
    
        % ---------- Nested Callback: Slider ----------
        function slider_callback(hObject, ~)
            frameNum = round(get(hObject, 'Value'));
            frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));
    
            % Delete any existing rectangle overlay
            delete(findobj(ax, 'Type', 'rectangle'));
    
            % Display the selected frame
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
    
            % If logicalData is true for this frame, draw a rectangle
            if logicalData(frameNum)
                rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r', 'Parent', ax);
            end
        end
    
        % ---------- Nested Callback: Play/Pause ----------
        function play_callback(~, ~)
            if strcmp(playBtn.String, 'Play')
                playBtn.String = 'Pause';
                while sld.Value < nFrames
                    frameNum = round(sld.Value);
    
                    % Delete any existing rectangle
                    delete(findobj(ax, 'Type', 'rectangle'));
    
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
                    frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));
    
                    if logicalData(frameNum)
                        rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r', 'Parent', ax);
                    end
    
                    pause(1/30);  % Adjust frame rate if needed
    
                    if strcmp(playBtn.String, 'Play')
                        break;  % user hit 'Pause'
                    end
                    sld.Value = sld.Value + 1;
                end
            else
                playBtn.String = 'Play';
            end
        end
    end
    
    % ---------- Helper #1: Determine if grayscale (3D) or color (4D) ----------
    function tf = isGrayscale(videoMat)
        tf = (ndims(videoMat) == 3);
    end
    
    % ---------- Helper #2: Return total number of frames ----------
    function nf = getNumFrames(videoMat)
        if ndims(videoMat) == 3
            % (H x W x nFrames) => nFrames is size(videoMat, 3)
            nf = size(videoMat, 3);
        else
            % (H x W x 3 x nFrames) => nFrames is size(videoMat, 4)
            nf = size(videoMat, 4);
        end
    end
    
    % ---------- Helper #3: Extract a single frame ----------
    function f = getFrame(videoMat, idx)
        if ndims(videoMat) == 3
            % Grayscale => (H x W x nFrames)
            f = videoMat(:,:,idx);
        else
            % Color => (H x W x 3 x nFrames)
            f = videoMat(:,:,:,idx);
        end
    end
    
