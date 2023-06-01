function [stillFrames, diffs] = detectStillnessInVideo(vidObj, threshold, nFrames)
    diffs = videoFrameDifferences(vidObj);
    diffs = diffs / max(diffs);
    stillFrames = zeros(size(diffs));

    stillFrames = diffs < threshold;
    % accept frames as "still" only if there are at least nFrames consecutive below threshold:
    kernel = ones(1, nFrames);
    convOutput = conv(double(stillFrames), kernel, 'same');
    stillFrames = convOutput >= nFrames;
  
end