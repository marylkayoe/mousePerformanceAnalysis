function [stillFrames, diffs] = detectStillnessInVideo(vidObj, threshold, nFrames)
    diffs = videoFrameDifferences(vidObj);
    diffs = diffs / max(diffs);
    stillFrames = zeros(size(diffs));

    stillFrames = diffs < threshold;
    % accept frames as "still" only if there are at least nFrames consecutive below threshold:
    kernel = ones(1, nFrames);
    convOutput = conv(double(stillFrames), kernel, 'same');
    stillFrames = convOutput >= nFrames;
    % state = 0;
    % count = 0;
    % for i = 1:length(diffs)
    %     if diffs(i) < threshold
    %         count = count + 1;
    %         if count >= nFrames && state == 0
    %             state = 1;
    %             stillFrames(i-nFrames+1:i) = 1;
    %         end
    %     else
    %         count = 0;
    %         if state == 1
    %             stillFrames(i-nFrames:i-1) = 1; % set stillFrames to 1 until threshold is exceeded
    %         end

    %     end
    % end
    %lastStillFrame = find(stillFrames, 1, 'last'); % find index of last true value in stillFrames
end