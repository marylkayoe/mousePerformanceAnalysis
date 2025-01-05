function [barYCoord barWidth] = findBarYCoordInImage(barImage)
% barImage is average image of a view with balance bar
% balance bar is white
% the cameras are seen as two black rectangles indicating midpoint
% the logic: we sum pixel values horizontally in the region matching
% cameras
% find peaks, as the bar is the only continuous thing it must have highest
% value
% add half of the peak width to estimate where the bar ends

%%TODO: need to normalize everything, maybe threshold the blacks 

[imHeight imWidth] = size(barImage);

% first we find where the cameras are (in x coordinate)
horizSum = sum(barImage, 1); 
[pks, locs, widths, p] = findpeaks(-horizSum, 'MinPeakProminence', 100);
[camPk camLoc] = max(pks);
camXcoord = locs(camLoc);
camWidth = floor(widths(camLoc));
camRangeX = camXcoord-camWidth:camXcoord+camWidth;

% crop image to contain only the midregion defined by cameras
cropBarImage = barImage(:, camRangeX);
%find top and bottom edges of the two black rectangles

[topCameraEdgeY, bottomCameraEdgeY] = findCameraEdgeCoordsInImage(cropBarImage);
levels = multithresh(barImage, 3);
segMeanFrameBar = imquantize(barImage, levels);

% 
% vertSumCams = sum(cropBarImage, 2);
% 
% % now find the position of the two camera rectangles in Y
% [pks, locs, widths, p] = findpeaks(diff(vertSumCams), 'MinPeakProminence', 500);
% topCamEdgeY = locs(1);
% [pks, locs, widths, p] = findpeaks(-diff(vertSumCams), 'MinPeakProminence', 500);
% bottomCamEdgeY = locs(end);
% 
%crop image vertically between the two cameras

cropBarImage = cropBarImage(topCameraEdgeY:bottomCameraEdgeY, :);
%figure; imshow(cropBarImage, []); title ('cropped between cams');

vertSum = sum(cropBarImage, 2);
vertSumDiff = diff(vertSum);
edgeThreshold = std(vertSumDiff)*2;

[pks, locs, widths, p] = findpeaks(vertSumDiff, 'MinPeakProminence', edgeThreshold);
%[barPk, barLoc] = max(pks);
barYCoordTop = locs(1);
barYCoordBottom = locs(2);
barYCoordTop = barYCoordTop + topCameraEdgeY;
barYCoordBottom = barYCoordBottom + topCameraEdgeY;

barYCoord = floor(mean([barYCoordBottom, barYCoordTop]));
barWidth = round(barYCoordBottom - barYCoordTop);


if 0
figure;
imshow(barImage, []);
hold on;

% show camera locations with rectangles on top of original image

rectangle('Position', [camRangeX(1), 1, 2*camWidth, imHeight], 'EdgeColor', 'cyan')

% show the bar
rectangle('Position', [1, barYCoordTop, imWidth, barWidth], 'EdgeColor', 'red')

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
