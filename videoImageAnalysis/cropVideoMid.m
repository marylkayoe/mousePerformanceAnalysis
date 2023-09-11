function croppedVideoMatrix = cropVideoMid(videoMatrix, midFraction)
% crop out top and bottom segments (e.g. leave only midFraction in the middle)
% midfraction should be odd number
% e.g. midFraction 3 crops out top and bottom thirds
[imHeight imWidth nFrames] = size(videoMatrix); 
cropTop = floor(imHeight / midFraction);
cropBottom = floor(imHeight - cropTop);

croppedVideoMatrix  = videoMatrix(cropTop:cropBottom,:, :);