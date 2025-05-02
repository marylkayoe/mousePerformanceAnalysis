function meanFrame = getMeanFrame(videoMatrix, FRAMES)
%if FRAMES are given, we take the mean frame from those
% otherwise, we take the mean frame from all frames
if ~exist('FRAMES', 'var')
meanFrame = uint8(mean(videoMatrix, 3));
else
    % check if FRAMES is appropriate (positive, and not larger than the number of frames)
    if any(FRAMES < 1) || any(FRAMES > size(videoMatrix, 3))
        warning('Attempting to take mean of frames that are not in the video');
        meanFrame = uint8(mean(videoMatrix, 3));

    else
    meanFrame = uint8(mean(videoMatrix(:, :, FRAMES), 3));
    end
end

