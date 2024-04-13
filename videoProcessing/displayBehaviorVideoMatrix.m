function displayBehaviorVideoMatrix(videoMatrix, titleString, dispData, logicalData, NORMHISTO)
if ~exist('dispData', 'var')
    dispData = string(1:length(videoMatrix));
end
if isempty(dispData)
    dispData = string(1:length(videoMatrix));
end


if ~exist('logicalData', 'var')
    logicalData = false(length(videoMatrix), 1);
end

if isempty(logicalData)
    logicalData = false(length(videoMatrix), 1);
end


if ~exist('NORMHISTO', 'var')
    NORMHISTO = 0;
end

if ~exist('titleString', 'var')
    titleString = 'Behavior Video';
end
% videoMatrixNormalized = (videoMatrix - min(videoMatrix(:))) / (max(videoMatrix(:)) - min(videoMatrix(:)));

% displayBehaviorVideo - display behavior video with scrollbar, play/pause button, and data display
fig = figure('Name', titleString, 'NumberTitle', 'off');

ax = axes('Parent', fig, 'Position', [0.05 0.2 0.9 0.7]);
sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
    'Position', [0.05 0.1 0.6 0.05], 'Min', 1, 'Max', size(videoMatrix, 3), ...
    'Value', 1, 'SliderStep', [1/(size(videoMatrix, 3)-1) 1/(size(videoMatrix, 3)-1)], ...
    'Callback', @slider_callback);
playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
    'Position', [0.7 0.1 0.2 0.05], 'String', 'Play', 'Callback', @play_callback);
frameNumText = uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
    'Position', [0.05 0.9 0.3 0.05], 'String', sprintf('Frame: 1, Value: %f', dispData(1)));

% Display first frame
frame = videoMatrix(:, :, 1);
imshow(frame, 'Parent', ax);
title(ax, titleString);

    function slider_callback(hObject, ~)
        frameNum = round(get(hObject, 'Value'));
        frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));

        % Delete any existing rectangle
        delete(findobj(ax, 'Type', 'rectangle'));

        frame = videoMatrix(:, :, frameNum);
        if NORMHISTO
            imshow(frame, [], 'Parent', ax);
        else
            imshow(frame, 'Parent', ax);
        end

        if logicalData(frameNum)
            % Draw a rectangle on top of the video. Modify the position values
            % [x y w h] as needed. 'LineWidth' and 'EdgeColor' can also be adjusted.
            rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r');
        end
    end

    function play_callback(~, ~)
        if strcmp(playBtn.String, 'Play')
            playBtn.String = 'Pause';
            while sld.Value < size(videoMatrix, 3)
                frameNum = round(sld.Value);

                % Delete any existing rectangle
                delete(findobj(ax, 'Type', 'rectangle'));

                frame = videoMatrix(:, :, frameNum);
                if NORMHISTO
                    imshow(frame, [], 'Parent', ax);
                else
                    imshow(frame, 'Parent', ax);
                end
                frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));
                if logicalData(frameNum)
                    % Draw a rectangle on top of the video. Modify the position values
                    % [x y w h] as needed. 'LineWidth' and 'EdgeColor'Here is the continuation of the code:
                    rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r');
                end
                pause(1/30);  % You may need to adjust this pause duration to suit your needs
                if strcmp(playBtn.String, 'Play')
                    break;
                end
                sld.Value = sld.Value + 1;
            end
        else
            playBtn.String = 'Play';
        end
    end
end
