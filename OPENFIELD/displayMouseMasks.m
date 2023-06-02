function displayMouseMasks(videoMatrix, FRAMERATE)
    % displayMouseMasks - display the processed frames as a video
    numFrames = size(videoMatrix, 3);

    % Create a VideoWriter object
    v = VideoWriter('mouseMasks.avi');
    v.FrameRate = FRAMERATE;
    open(v);

    for frameIdx = 1:numFrames

        imshow(videoMatrix(:,:, frameIdx), []);


        pause(1/FRAMERATE);
        writeVideo(v, videoMatrix(:,:, frameIdx));
    end
        % Close the VideoWriter object
    close(v);
end
