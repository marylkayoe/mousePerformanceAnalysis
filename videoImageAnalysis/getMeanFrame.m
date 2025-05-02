function meanFrame = getMeanFrame(videoMatrix, FRAMES)
%if FRAMES are given, we take the mean frame from those
if ~exist('FRAMES', 'var')
meanFrame = uint8(mean(videoMatrix, 3));
else
    meanFrame = uint8(mean(videoMatrix(:, :, FRAMES), 3));
end

