function newMatrix = subtractFrom(videoMatrix, subMatrix)

subMatrixNorm = imadjust(uint8(subMatrix));
videoMatrixNorm = imadjustn(videoMatrix);
newMatrix = videoMatrix - subMatrixNorm;
