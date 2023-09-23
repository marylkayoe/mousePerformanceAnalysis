function croppedVideoMatrix = cropVideoAboveBar(videoMatrix, barYCoord, barWidth)

[imHeight imWidth nFrames] = size(videoMatrix); 
%barWidth = floor(imHeight/15);
%MOUSEHEIGHT = floor(imHeight/5);
mouseHeight = barWidth * 5;
%CROPEDGE = floor(imWidth / 10);
CROPEDGE = 1;
yCropTop = barYCoord-barWidth-mouseHeight;
if yCropTop < 1
    yCropTop = 1;
end
yCropBottom = barYCoord+barWidth;
if yCropBottom > imHeight
    yCropBottom = imHeight;
end


if yCropTop < 1
    yCropTop = 1;
end

croppedVideoMatrix  = videoMatrix(yCropTop:yCropBottom, :, :);