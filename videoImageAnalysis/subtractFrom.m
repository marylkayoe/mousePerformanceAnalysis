function newMatrix = subtractFrom(videoMatrix, subMatrix)

subMatrixNorm = imadjust(uint8(subMatrix));
videoMatrixNorm = imadjustn(videoMatrix, [0, 0.8]);
newMatrix = videoMatrix - subMatrixNorm;
