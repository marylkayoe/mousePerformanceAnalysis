function sumFrame = getSumFrame(videoMatrix)


sumFrame = sum(videoMatrix, 3);

% Normalize doubleMatrix to [0, 1]
sumFrameNormalized = sumFrame / max(sumFrame(:));

% Rescale to [0, 255] and convert to uint8
sumFrame = uint8(sumFrameNormalized * 255);

