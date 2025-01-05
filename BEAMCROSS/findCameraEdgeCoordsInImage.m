function [topCameraEdgeY, bottomCameraEdgeY] = findCameraEdgeCoordsInImage(meanImage)
% there are two cameras in the image, one on top and one on bottom
% they look like black rectangles

levels = multithresh(meanImage, 2);
segMeanFrameCams = imquantize(meanImage, levels);


% we find the x-coordinates of the region between the two cameras


% horizontal sum of the image
horizSum = sum(segMeanFrameCams, 1);
horizSumDiff = diff(horizSum);
edgeThreshold = std(horizSumDiff)*2;

[pks, locs, widths, p] = findpeaks(horizSumDiff, 'MinPeakHeight', edgeThreshold);

if isempty(pks)
    camRightCoord = length(horizSumDiff);
else
    camRightCoord = locs(end);
end

[pks, locs, widths, p] = findpeaks(-horizSumDiff, 'MinPeakHeight', edgeThreshold);
if isempty(pks)
    camLeftCoord = 1;
else

    camLeftCoord = locs(1);
end

camRangeX = camLeftCoord:camRightCoord;


% find cameras as peaks in the negative of the vertical sum

vertSum = sum(segMeanFrameCams(:, camRangeX), 2);


vertSumDiff = diff(vertSum);
edgeThreshold = std(vertSumDiff)*3;
% find the bottom position of the top camera rectangle in Y
[pks, locs, widths, p] = findpeaks(vertSumDiff, 'MinPeakHeight',edgeThreshold);
% top camera bottom edge
topCameraEdgeY = locs(1);

[pks, locs, widths, p] = findpeaks(-vertSumDiff, 'MinPeakHeight',edgeThreshold);
% bottom camera top edge
bottomCameraEdgeY = locs(end);

end

