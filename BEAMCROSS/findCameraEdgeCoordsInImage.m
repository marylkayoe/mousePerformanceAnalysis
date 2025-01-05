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

[pks, locs, widths, p] = findpeaks(horizSumDiff, 'MinPeakProminence', edgeThreshold);
camRightCoord = locs(end);
[pks, locs, widths, p] = findpeaks(-horizSumDiff, 'MinPeakProminence', edgeThreshold);
camLeftCoord = locs(1);

camRangeX = camLeftCoord:camRightCoord;


% find cameras as peaks in the negative of the vertical sum

vertSum = sum(segMeanFrameCams(:, camRangeX), 2);


vertSumDiff = diff(vertSum);
edgeThreshold = std(vertSumDiff)*3;
% find the bottom position of the top camera rectangle in Y
[pks, locs, widths, p] = findpeaks(vertSumDiff, 'MinPeakProminence',edgeThreshold);
% top and bottom camera edges
topCameraEdgeY = locs(1);

[pks, locs, widths, p] = findpeaks(-vertSumDiff, 'MinPeakProminence',edgeThreshold);
% top and bottom camera edges
bottomCameraEdgeY = locs(end);

end

