function newMatrix = subtractFrom(videoMatrix, subMatrix)

subMatrixNorm = imadjust(subMatrix);
%videoMatrixNorm = imadjustn(videoMatrix, [0, 0.8]);
newMatrix = videoMatrix - subMatrixNorm;
