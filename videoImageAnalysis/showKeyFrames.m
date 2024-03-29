function showKeyFrames(videoMatrix, frameRange, TITLESTRING, VALUES, ADJUSTIMAGE)
    % Create a new array to hold the annotated frames

if ~exist('TITLESTRING', 'var')
    TITLESTRING = 'Key frames';
end

if ~exist('ADJUSTIMAGE', 'var')
    ADJUSTIMAGE = 0;
end



    [height, width, ~] = size(videoMatrix);
    annotatedFrames = zeros(height, width, 1, length(frameRange), 'like', videoMatrix);
    
    % Get the number of frames to annotate
    numFrames = length(frameRange);
    
    if ~exist('VALUES', 'var')
    VALUES = zeros(numFrames, 1);
end


    % Loop through each frame and annotate it with the frame number
    for i = 1:numFrames
        % Get the current frame
        frame = videoMatrix(:, :, frameRange(i));

        % Convert the frame to an RGB image to add text
        frameRGB = cat(3, frame, frame, frame);

        % Add the frame number as a text annotation
        frameAnnotationString = ['FRAME#' num2str(frameRange(i)) ': ' num2str(VALUES(i))] ;
        frameRGB = insertText(frameRGB, [5, 5], frameAnnotationString, 'FontSize', 18, 'BoxColor', 'white', 'BoxOpacity', 0.7, 'TextColor', 'black');

        % Convert the frame back to grayscale
        frame = rgb2gray(frameRGB);
        if ADJUSTIMAGE
        frame = imadjust(frame, [0, 0.6]);
        end

        % Store the annotated frame back in the array
        annotatedFrames(:, :, 1, i) = frame;
    end
    figure;
    % Create a montage of the annotated frames
    montage(annotatedFrames);
    title(TITLESTRING);
end




% function showKeyFrames(videoMatrix, frameRange)
%     % createMontage - create a montage of specified frames from a video
%     % 
%     % frameRange: range of frame numbers to include in the montage
% 
% 
%     % % Create a montage of the frames
%     montage(videoMatrix(:, :, frameRange));
% 
% 
% end
