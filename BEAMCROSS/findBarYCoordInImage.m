function [barYcoord barWidth] = findBarYCoordInImage(barImage)
% barImage is average image of a view with balance bar
% balance bar is white
% the logic: we sum pixel values horizontally
% find peaks, as the bar is the only continuous thing it must have highest
% value
% add half of the peak width to estimate where the bar ends

[imHeight imWidth] = size(barImage);
vertSum = sum(barImage, 2);
[pks locs, widths, p] = findpeaks(vertSum);
[barPk barLoc] = max(pks);
barYcoord = locs(barLoc);
barWidth = round(widths(barLoc));
%barYcoord = floor(barYcoord + w(barLoc)/4);

% imshow(barImage, []);
% hold on;
% ys = 1:imHeight;
% xs = (vertSum / max(vertSum)) * imWidth;
% 
% plot(xs, ys, 'LineWidth', 2, 'Color', 'cyan');
% 
% scatter(imWidth, barYcoord, '*', 'white');
