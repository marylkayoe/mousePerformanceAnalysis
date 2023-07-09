function croppedVideoMatrix = cropVideoBelowBar(videoMatrix, barYCoord)

[imHeight imWidth nFrames] = size(videoMatrix); 
BARWIDTH = floor(imHeight/15);
CROPEDGE = floor(imWidth / 10);
croppedVideoMatrix  = videoMatrix(barYCoord:barYCoord+BARWIDTH, CROPEDGE:end-CROPEDGE, :);