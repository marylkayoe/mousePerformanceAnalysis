function croppedVideoMatrix = cropVideoAboveBar(videoMatrix, barYCoord)

[imHeight imWidth nFrames] = size(videoMatrix); 
BARWIDTH = floor(imHeight/15);
MOUSEHEIGHT = floor(imHeight/5);
%CROPEDGE = floor(imWidth / 10);
CROPEDGE = 1;
yCropTop = barYCoord-BARWIDTH-MOUSEHEIGHT;
yCropBottom = barYCoord+BARWIDTH;
if yCropBottom > imHeight
    yCropBottom = imHeight;
end
croppedVideoMatrix  = videoMatrix(yCropTop:yCropBottom, CROPEDGE:end-CROPEDGE, :);