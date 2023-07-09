function croppedVideoMatrix = cropVideoAboveBar(videoMatrix, barYCoord)

[imHeight imWidth nFrames] = size(videoMatrix); 
BARWIDTH = floor(imHeight/15);
MOUSEHEIGHT = floor(imHeight/10);
CROPEDGE = floor(imWidth / 10);
croppedVideoMatrix  = videoMatrix(barYCoord-BARWIDTH-MOUSEHEIGHT:barYCoord+BARWIDTH, CROPEDGE:end-CROPEDGE, :);