function stillFrames = detectStillnessInVideo(vidObj, threshold, nFrames)
    diffs = videoFrameDifferences(vidObj);
    diffs = diffs / max(diffs);
    stillFrames = zeros(size(diffs));
    state = 0;
    count = 0;
    for i = 1:length(diffs)
        if diffs(i) < threshold
            count = count + 1;
            if count >= nFrames && state == 0
                state = 1;
                stillFrames(i-nFrames+1:i) = 1;
            end
        else
            count = 0;
            if state == 1
                state = 0;
                stillFrames(i-nFrames:i-1) = 0;
            end
        end
    end
end