function displayBehaviorVideo(vidObj, dispData, logicalData)
if ~exist('dispData', 'var')
    dispData = [];
end

% displayBehaviorVideo - display behavior video with scrollbar, play/pause button, and data display
fig = figure('Name', 'Behavior Video', 'NumberTitle', 'off');
ax = axes('Parent', fig, 'Position', [0.05 0.2 0.9 0.7]);
sld = uicontrol('Style', 'slider', 'Parent', fig, 'Units', 'normalized', ...
    'Position', [0.05 0.1 0.6 0.05], 'Min', 1, 'Max', vidObj.NumberOfFrames, ...
    'Value', 1, 'SliderStep', [1/(vidObj.NumberOfFrames-1) 1/(vidObj.NumberOfFrames-1)], ...
    'Callback', @slider_callback);
playBtn = uicontrol('Style', 'pushbutton', 'Parent', fig, 'Units', 'normalized', ...
    'Position', [0.7 0.1 0.2 0.05], 'String', 'Play', 'Callback', @play_callback);
frameNumText = uicontrol('Style', 'text', 'Parent', fig, 'Units', 'normalized', ...
    'Position', [0.05 0.9 0.3 0.05], 'String', sprintf('Frame: 1, Value: %f', dispData(1)));

% Display first frame
frame = read(vidObj, 1);
imshow(frame, 'Parent', ax);


    function slider_callback(hObject, ~)
        frameNum = round(get(hObject, 'Value'));
        frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));
        imshow(read(vidObj, frameNum), 'Parent', ax);
        if logicalData(frameNum)
            text(ax, 0.5, 1.1, 'MASK', 'HorizontalAlignment', 'center', 'FontSize', 40, 'Color', 'r');
        end
    end

% Callback function for play/pause button
% Callback function for play/pause button
    function play_callback(~, ~)
        if strcmp(playBtn.String, 'Play')
            playBtn.String = 'Pause';
            for frameNum = sld.Value:vidObj.NumberOfFrames
                frame = read(vidObj, frameNum);
                imshow(frame, 'Parent', ax);
                sld.Value = frameNum;
                frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, logicalData(frameNum));
                if logicalData(frameNum)
                    text(ax, 0.5, 1.1, 'MASK', 'HorizontalAlignment', 'center', 'FontSize', 40, 'Color', 'r');
                end
                pause(1/vidObj.FrameRate);
                if strcmp(playBtn.String, 'Play')
                    break;
                end
            end
        else
            playBtn.String = 'Play';
        end
    end
end