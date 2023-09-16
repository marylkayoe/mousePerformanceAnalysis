function meanFrame = getMeanFrame(videoMatrix)


meanFrame = uint8(mean(videoMatrix, 3));

