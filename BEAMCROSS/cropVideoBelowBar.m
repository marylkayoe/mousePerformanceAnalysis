function croppedVideoMatrix = cropVideoBelowBar(videoMatrix)

% [imHeight imWidth nFrames] = size(videoMatrix); 
% BARWIDTH = floor(imHeight/15);
% CROPEDGE = floor(imWidth / 10);

meanImage = getMeanFrame(videoMatrix);
[barYcoord barWidth] = findBarYCoordInImage(imcomplement(meanImage)); %the coordinate is from image top

[imHeight imWidth nFrames] = size(videoMatrix); 
%BARWIDTH = floor(imHeight/15);
%MOUSEHEIGHT = floor(imHeight/5);
%
%CROPEDGE = floor(imWidth / 10);
CROPEDGE = 1;

cropBottom = barYcoord+ceil(barWidth/2);
if cropBottom > imHeight
    cropBottom = imHeight;
end

croppedVideoMatrix  = imadjustn(videoMatrix(barYcoord:cropBottom, :, :));