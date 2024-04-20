function [x1, x2, y1, y2] = findCropRectangle (imageMatrix, THRESHOLD)
% Find the crop rectangle of an image
% the rectangle is marked in the image with tape that is significangly brighter than anything else in the image
% the function returns the coordinates of the rectangle, in the form [x1, x2, y1, y2]
% where (x1, y1) is the top left corner and (x2, y2) is the bottom right corner
% the function also takes an optional parameter THRESHOLD, which is the threshold for the horizontal and vertical profiles
% the default value is 0.9, decrease if the rectangle is not detected properly

% set default value for THRESHOLD
if ~exist('THRESHOLD', 'var')
    THRESHOLD = 0.9;
end

%calculate the horizontal and vertical profiles
% note that mean (imageMatrix,1) takes the mean of each column, and mean (imageMatrix,2) takes the mean of each row
% thus the vertical profile is the mean of each row, and the horizontal profile is the mean of each column
verticalProfile = mean(imageMatrix, 2);
horizontalProfile = mean(imageMatrix, 1);

% normalize the profiles to the range [0,1]
horizontalProfile = normalize(horizontalProfile, 'range');
% find the first and last indices where the profile is above the threshold
x1 = find(horizontalProfile > THRESHOLD, 1, 'first');
x2 = find(horizontalProfile > THRESHOLD, 1, 'last');

% same for the vertical profile
verticalProfile = normalize(verticalProfile, 'range');
y1 = find(verticalProfile > THRESHOLD, 1, 'first');
y2 = find(verticalProfile > THRESHOLD, 1, 'last');

end
