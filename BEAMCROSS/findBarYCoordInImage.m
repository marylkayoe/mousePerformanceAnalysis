function [barYCoord barWidth] = findBarYCoordInImage(barImage)
% barImage is average image of a view with balance bar
% balance bar is white
% the cameras are seen as two black rectangles indicating midpoint
% the logic: we sum pixel values horizontally in the region matching
% cameras
% find peaks, as the bar is the only continuous thing it must have highest
% value
% add half of the peak width to estimate where the bar ends

BARWIDTHPERC = 5; %(percent of image height)

[imHeight imWidth] = size(barImage);

barWidth = round(imHeight * BARWIDTHPERC / 100);

% first we find where the cameras are (in x coordinate)
horizSum = sum(barImage, 1); 
horizSumDiff = diff(horizSum);
edgeThreshold = std(horizSumDiff);

[pks, locs, widths, p] = findpeaks(-horizSumDiff, 'MinPeakHeight', edgeThreshold);
camXleft = locs(1);
[pks, locs, widths, p] = findpeaks(horizSumDiff, 'MinPeakHeight', edgeThreshold);
camXright = locs(end);
camWidth = camXright - camXleft;
camRangeX = camXleft:camXright;

% crop image to contain only the midregion defined by cameras
cropBarImage = barImage(:, camRangeX);
%find top and bottom edges of the two black rectangles
[topCameraEdgeY, bottomCameraEdgeY] = findCameraEdgeCoordsInImage(cropBarImage);
topCameraEdgeY = topCameraEdgeY + 5; % taking out remainder of camers
bottomCameraEdgeY = bottomCameraEdgeY-5;
cropBarImage = cropBarImage(topCameraEdgeY:bottomCameraEdgeY,:);

%threshold the image; the bar should be in the bright levels
levels = multithresh(cropBarImage, 2);
segMeanFrameBar = imquantize(cropBarImage, levels);


vertSum = sum(segMeanFrameBar, 2);
vertSumDiff = diff(vertSum);
edgeThreshold = std(vertSumDiff)*3;
%bottom of the bar should be darker than background
[pks, locs, widths, p] = findpeaks(vertSumDiff, 'MinPeakHeight', edgeThreshold);
barYCoordBottom = locs(end) + topCameraEdgeY;
%[pks, locs, widths, p] = findpeaks(-vertSumDiff, 'MinPeakHeight', edgeThreshold);
%barYCoordBottom = locs(1) + topCameraEdgeY;

%barYCoord = floor(mean([barYCoordBottom, barYCoordTop]));

% hardcoding bar width to 5% of image height
barYCoord = barYCoordBottom - barWidth ;




if 0
figure;
imshow(barImage, []);
hold on;

% show camera locations with rectangles on top of original image

rectangle('Position', [camRangeX(1), 1, 2*camWidth, imHeight], 'EdgeColor', 'cyan')

% show the bar
rectangle('Position', [1, barYCoord, imWidth, barWidth], 'EdgeColor', 'red');
end





%barYcoord = floor(barYcoord + w(barLoc)/4);

% imshow(barImage, []);
% hold on;
% ys = 1:imHeight;
% xs = (vertSum / max(vertSum)) * imWidth;
% 
% plot(xs, ys, 'LineWidth', 2, 'Color', 'cyan');
% 
% scatter(imWidth, barYcoord, '*', 'white');
