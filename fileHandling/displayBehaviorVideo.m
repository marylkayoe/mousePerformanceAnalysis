function displayBehaviorVideo(vidObj, dispData, logicalData, titleString)
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
title(ax, titleString);


function slider_callback(hObject, ~)
    frameNum = round(get(hObject, 'Value'));
    frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));
    
    % Delete any existing rectangle
    delete(findobj(ax, 'Type', 'rectangle'));
    
    frame = read(vidObj, frameNum);
    imshow(frame, 'Parent', ax);
    
    if logicalData(frameNum)
        % Draw a rectangle on top of the video. Modify the position values 
        % [x y w h] as needed. 'LineWidth' and 'EdgeColor' can also be adjusted.
        rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r');

    end
end


% Callback function for play/pause button
function play_callback(~, ~)
    if strcmp(playBtn.String, 'Play')
        playBtn.String = 'Pause';
        while sld.Value < vidObj.NumberOfFrames
            frameNum = round(sld.Value);
            
            % Delete any existing rectangle
            delete(findobj(ax, 'Type', 'rectangle'));

            frame = read(vidObj, frameNum);
            imshow(frame, 'Parent', ax);
            frameNumText.String = sprintf('Frame: %d, Value: %f', frameNum, dispData(frameNum));
            if logicalData(frameNum)
                % Draw a rectangle on top of the video. Modify the position values 
                % [x y w h] as needed. 'LineWidth' and 'EdgeColor' can also be adjusted.
                rectangle('Position', [5 5 10 10], 'EdgeColor', 'r', 'FaceColor', 'r');

            end
            pause(1/vidObj.FrameRate);
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